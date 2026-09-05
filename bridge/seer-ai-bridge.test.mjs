import assert from "node:assert/strict";
import { createHash, createHmac } from "node:crypto";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  callTool, cancelWork, createBridgeReadState, createReadScan, ensureBridgeProtocol,
  discoverModelProfiles,
  extractMcpCookie, fetchWebContext, isPrivateContextAddress, libraryObservations, loadLibraryContext,
  nextReadJob, normalizeContextContent, parseClaudeAuthChallenge, parseCodexDeviceAuth,
  parseEditResult, parseStatePlan, poll, processChange, processQuestion,
  promptDigest, publishModelProfiles, READ_CAPS, readBoundedDetail, readBoundedPage,
  recoverWork, runInteractive, startLogin, validateContextPacket, validateContextUrl,
} from "./seer-ai-bridge.mjs";

const secret = "0123456789abcdef0123456789abcdef";
const epoch = "~2026.9.4..00.00.00..0000";
const config = { workerId: "worker-test", bridgeSecret: secret, idempotencyEpoch: epoch };
const ref = (kind, id, scope = "") => ({ kind, owner: "~zod", scope, id,
  incarnation: 1, content_revision: 2, review_revision: 3 });
const receipt = (action, args, extra = {}) => ({ schema_version: 2, action,
  idempotency_epoch: args.idempotency_epoch, operation_id: args.operation_id,
  payload_digest: "0xabcd", status: "ok", effect: "none", ...extra });
const page = (collection, rows, query = {}, extra = {}) => ({
  schema_version: 2, status: "ok", state_revision: 1, observed_at: epoch,
  idempotency_epoch: epoch, watermark: "scope-watermark", projection: query.projection || "metadata",
  complete: true, next_cursor: null, omissions: [],
  limits: { limit: Number(query.limit || READ_CAPS.pageRows), max_bytes: Number(query.max_bytes || READ_CAPS.pageBytes) },
  ...(collection ? { [collection]: rows } : {}), ...extra,
});

async function catalogCli(t, paddingBytes) {
  const directory = await mkdtemp(join(tmpdir(), "seer-catalog-"));
  t.after(() => rm(directory, { recursive: true, force: true }));
  const command = join(directory, "codex");
  const models = ["luna", "terra", "sol"].map((tier) => ({
    slug: `gpt-5.6-${tier}`, visibility: "list",
  }));
  await writeFile(command, `#!${process.execPath}
process.stdout.write(JSON.stringify({models:${JSON.stringify(models)},metadata:"x".repeat(${paddingBytes})}));
`, { mode: 0o700 });
  return command;
}

async function localMcp(t, handle, handleNative) {
  const requests = [];
  const server = createServer(async (request, response) => {
    let body = "";
    for await (const chunk of request) body += chunk;
    try {
      if (handleNative && request.url !== "/mcp") {
        await handleNative(new URLSearchParams(body), request, response);
        return;
      }
      const rpc = JSON.parse(body);
      requests.push(rpc);
      const result = await handle(rpc.params?.name, rpc.params?.arguments, request, response);
      if (response.destroyed || response.writableEnded) return;
      response.writeHead(200, { "Content-Type": "application/json" });
      response.end(JSON.stringify({ jsonrpc: "2.0", id: rpc.id, result: { structuredContent: result } }));
    } catch {
      response.writeHead(500);
      response.end("Cookie=private-account-secret provider-output");
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(async () => {
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  });
  return { requests, config: { ...config, mcpTimeoutMs: 1000,
    mcpUrl: `http://127.0.0.1:${server.address().port}/mcp` } };
}

// Independent protocol consumer, deliberately not importing the signing helper.
function validProof(action, args, id, fields) {
  const hmac = createHmac("sha256", secret);
  for (const value of ["seer-bridge-v2", action, id, args.worker_id, args.proof_nonce,
    "2", args.idempotency_epoch, args.operation_id, String(args.attempt), args.lease, ...fields]) {
    const bytes = Buffer.from(String(value));
    hmac.update(`${bytes.length}:`); hmac.update(bytes);
  }
  return BigInt(args.proof.replaceAll(".", "")) === BigInt(`0x${hmac.digest("hex")}`);
}

function packetFixture(kind = "question", mode = "ask", library) {
  const id = kind === "question" ? "q-one" : "change-one";
  const profile = { profile_id: "exact-profile", provider: "codex", role: "default",
    selector: "openai-codex/exact-model", model: "exact-model" };
  if (mode === "library" && library === undefined) {
    library = {
      observations: [],
      read_report: { scope: "local-library", complete: true, omissions: [] },
      source_coverage: { scope: "local-library", owner: "~zod", complete: true,
        stack_count: 0, observed_stack_count: 0, unobserved_stack_count: 0,
        card_count: 0, observed_card_count: 0, unobserved_card_count: 0 },
    };
  }
  const input = JSON.stringify({ schema_version: 2, objective: "Explain é", entries: [],
    card: { title: "", front: mode === "library" ? JSON.stringify(library) : "", back: "" } });
  const prompt = `Source-authored contract\nBEGIN UNTRUSTED INPUT JSON\n${input}\nEND UNTRUSTED INPUT JSON\n`;
  const packet = { schema_version: 2, output_schema_version: 2, prompt_version: 1,
    packet_ref: "0xa", canonical_prompt: prompt, prompt_digest: promptDigest(prompt),
    input_digest: promptDigest(input), input_bytes: Buffer.byteLength(prompt),
    blocked_reason: null, complete: false, entries: [], profile, mode, objective: "Explain é",
    scope: { kind: "stack", owner: "~zod", stack_id: "s", card_id: "c" } };
  const job = { [kind === "question" ? "question_id" : "change_id"]: id,
    ref: ref(kind, id), status: "working", mode, target: kind === "change" ? mode : "library", prompt: "Explain é",
    provider: profile.provider, model_id: profile.profile_id, model: profile.model,
    model_selector: profile.selector, model_role: profile.role,
    work: { worker: config.workerId, schema_version: 2, attempt: 1, lease: "0xb",
      execution: "running", effect: "none", deadline_ms: Date.now() + 60_000,
      lease_until_ms: Date.now() + 40_000, packet_ref: packet.packet_ref,
      packet_digest: packet.prompt_digest, input_bytes: packet.input_bytes,
      max_input_bytes: 131072, max_output_bytes: 65536, max_operations: 64,
      max_invocations: 1, invocations: 0, prompt_version: 1, policy_version: 1,
      provider: profile.provider, model_id: profile.profile_id, model_revision: 1 } };
  return { packet, job };
}

function workRuntime(fixture, runProvider, override = {}) {
  const calls = [];
  const runtime = {
    runProvider,
    inspectProvider: async () => ({ supported: true }),
    callTool: async (_config, _cookie, name, args = {}) => {
      calls.push({ name, args });
      if (override[name]) return override[name](args);
      if (name === "seer/list-card-questions") return page("questions", [fixture.job], args);
      if (name === "seer/list-change-requests") return page("changes", [fixture.job], args);
      if (name === "seer/get-context-packet") return fixture.packet;
      if (name === "seer/lookup-learning") return { schema_version: 2, status: "ok", artifacts: [] };
      return { schema_version: 2, status: "ok", effect: "none" };
    },
  };
  return { calls, runtime };
}

test("model catalog discovery accepts metadata larger than an answer", { skip: process.platform === "win32" }, async (t) => {
  const codex = await catalogCli(t, 131_072);
  const profiles = await discoverModelProfiles({ codex }, { timeoutMs: 5000 });
  assert.deepEqual(profiles.map(({ role, model }) => [role, model]), [
    ["smol", "gpt-5.6-luna"],
    ["default", "gpt-5.6-terra"],
    ["slow", "gpt-5.6-sol"],
  ]);
});

test("model catalog discovery rejects oversized metadata", { skip: process.platform === "win32" }, async (t) => {
  const codex = await catalogCli(t, 1_048_576);
  await assert.rejects(discoverModelProfiles({ codex }, { timeoutMs: 5000 }), { code: "PROCESS_STDOUT_LIMIT" });
});

test("MCP cookies remain endpoint-specific and environment-backed", () => {
  const toml = `[mcp_servers.other]\nurl = "http://other/mcp"\nhttp_headers = { "Cookie" = "wrong" }\n
[mcp_servers.seer]\nurl = "http://seer/mcp"\nenv_http_headers = { "Cookie" = "SEER_COOKIE" }`;
  assert.equal(extractMcpCookie(toml, "http://seer/mcp", { SEER_COOKIE: "account" }), "account");
  assert.equal(extractMcpCookie(toml, "http://absent/mcp", { SEER_COOKIE: "account" }), null);
});

test("login challenges require allowlisted complete provider URLs", () => {
  assert.equal(parseCodexDeviceAuth("https://auth.openai.com/activate enter "), null);
  assert.equal(parseCodexDeviceAuth("https://evil.example/activate ABCD-EFGH"), null);
  assert.deepEqual(parseCodexDeviceAuth("\u001b[36mhttps://auth.openai.com/activate\u001b[0m ABCD-EFGH"),
    { authUrl: "https://auth.openai.com/activate", userCode: "ABCD-EFGH" });
  const authUrl = "https://claude.com/cai/oauth/authorize?state=opaque";
  assert.deepEqual(parseClaudeAuthChallenge(authUrl), { authUrl });
  assert.equal(parseClaudeAuthChallenge("https://evil.example/cai/oauth/authorize"), null);
});

test("worker proof binds epoch, operation, lease, Unicode content, and citation list", async (t) => {
  const server = await localMcp(t, (name, args) => {
    const action = name.slice(5);
    if (action === "answer-card-question") {
      assert.ok(validProof(action, args, "q-one", ["é answer", "1", "0xa", "0", "2", "é"]));
      for (const change of [{ attempt: "2" }, { lease: "0xc" }, { operation_id: "different" }, { idempotency_epoch: "~2026.9.5" }]) {
        assert.equal(validProof(action, { ...args, ...change }, "q-one", ["é answer", "1", "0xa", "0", "2", "é"]), false);
      }
      assert.deepEqual(JSON.parse(args.citations), [{ snapshot_ref: "0xa", start: 0, end: 2, quote: "é" }]);
    }
    return receipt(action, args);
  });
  await callTool(server.config, "account", "seer/answer-card-question", {
    question_id: "q-one", attempt: 1, lease: "0xb", answer: "é answer",
    citations: [{ snapshot_ref: "0xa", start: 0, end: 2, quote: "é" }],
  });
  assert.equal(server.requests.filter((row) => row.params.name === "seer/issue-bridge-nonce").length, 1);
});

test("login code consumption proof fences the observed content revision", async (t) => {
  const server = await localMcp(t, (name, args) => {
    if (name === "seer/consume-login-code") assert.ok(validProof("consume-login-code", args, "login-one", ["42"]));
    return receipt(name.slice(5), args);
  });
  await callTool(server.config, "account", "seer/consume-login-code", {
    login_id: "login-one", attempt: 1, lease: "0xb", content_revision: "42",
  });
});

test("response loss consults the original receipt and never repeats a mutation", async (t) => {
  let committed;
  const server = await localMcp(t, (name, args, _request, response) => {
    if (name === "seer/claim-card-question") {
      committed = receipt("claim-card-question", args);
      response.destroy(); return;
    }
    if (name === "seer/get-operation-result") {
      assert.equal(args.operation_id, committed.operation_id);
      return committed;
    }
    return receipt(name.slice(5), args);
  });
  assert.deepEqual(await callTool(server.config, "account", "seer/claim-card-question", {
    question_id: "q-one", attempt: 0, lease: "0x0",
  }), committed);
  assert.equal(server.requests.filter((row) => row.params.name === "seer/claim-card-question").length, 1);
});

test("missing receipts and untrusted RPC errors never authorize retries or leak output", async (t) => {
  const server = await localMcp(t, (name, args) => {
    if (name === "seer/issue-bridge-nonce") return receipt(name.slice(5), args);
    if (name === "seer/get-operation-result") return receipt("unknown", args, { status: "outcome-unknown", effect: "unknown" });
    throw new Error(secret);
  });
  await assert.rejects(callTool(server.config, "account", "seer/claim-card-question", {
    question_id: "q-one", attempt: 0, lease: "0x0",
  }), (error) => error.ambiguous === true && !String(error).includes("private-account") && !String(error).includes(secret));
  assert.equal(server.requests.filter((row) => row.params.name === "seer/claim-card-question").length, 1);
});

test("an explicitly repeated operation ID is receipt-only, including unknown outcomes", async (t) => {
  const server = await localMcp(t, (name, args) => {
    assert.equal(name, "seer/get-operation-result");
    return receipt("unknown", args, { status: "outcome-unknown", effect: "unknown" });
  });
  await assert.rejects(callTool(server.config, "account", "seer/claim-card-question", {
    question_id: "q-one", attempt: 0, lease: "0x0", operation_id: "previous-attempt",
  }), { code: "MUTATION_STOPPED" });
  assert.equal(server.requests.length, 1);
});

test("oversized RPC responses are stopped before parsing or error disclosure", async (t) => {
  const server = await localMcp(t, (_name, _args, _request, response) => {
    response.writeHead(200, { "Content-Type": "text/plain", "Content-Length": 600000 });
    response.end("credential".repeat(60000));
  });
  await assert.rejects(callTool(server.config, "account", "seer/agent-context"), { code: "RPC_FAILED" });
});

test("old protocol discovery fails closed even when bounded reads succeed", async () => {
  await assert.rejects(ensureBridgeProtocol({ ...config }, "", { callTool: async () => page(null, [], {}, {
    capabilities_revision: 2, worker_authority: "paired-proof", authority: "owner-trusted",
    scoped_delegation: false, mutation_receipts: false, leased_execution: false,
  }) }));
});

test("bounded readers reject inconsistent completeness and preserve omission reasons", async () => {
  const query = { limit: 1, max_bytes: 1024 };
  const row = { question_id: "q-one", status: "pending" };
  for (const extra of [{ schema_version: 1 }, { complete: true, next_cursor: "next" },
    { complete: false }, { projection: "detail" }, { status: "unchanged" }]) {
    await assert.rejects(readBoundedPage({}, "", "seer/list-card-questions", query, {
      callTool: async () => page("questions", [row], query, extra),
    }));
  }
  const omission = { reason: "row-too-large", ref: "q-one", fields: ["question"] };
  const result = await readBoundedDetail({}, "", "seer/list-card-questions", "q-one", {}, {
    callTool: async (_c, _k, _n, args) => page("questions", [], args,
      { status: "limit-exceeded", complete: false, omissions: [omission] }),
  });
  assert.equal(result.row, null);
  assert.deepEqual(result.page.omissions, [omission]);
});

test("bounded continuation retains discovered IDs and resets expired cursors explicitly", async () => {
  const scan = createReadScan();
  let count = 0;
  const queries = [];
  const runtime = { onSnapshotExpired() {}, callTool: async (_c, _k, _n, query) => {
    queries.push(query);
    if (++count === 1) return page("questions", ["a", "b"].map((question_id) => ({ question_id, status: "pending" })), query,
      { complete: false, next_cursor: "old" });
    if (count === 2) return page("questions", [], query, { status: "snapshot-expired", complete: false });
    return page("questions", [{ question_id: "c", status: "pending" }], query);
  } };
  const selected = [];
  for (let i = 0; i < 4; i++) selected.push((await nextReadJob({}, "", "seer/list-card-questions", { status: "pending" }, scan, runtime))?.question_id);
  assert.deepEqual(selected, ["a", "b", undefined, "c"]);
  assert.equal(queries[1].cursor, "old");
  assert.equal(queries[2].cursor, undefined);
});

test("explicit stack references resolve beyond discovery with owner-scoped bodies and truthful omissions", async () => {
  const ids = ["buried-one", "buried-two", "buried-three", "buried-four", "buried-five", "buried-six"];
  const owners = ids.map((id) => id === "buried-five" ? "~nec" : "~zod");
  const prompt = 'Compare stack_id=buried-one, stack identifier buried-two, "buried-three", `buried-four`, '
    + "https://ship.example/apps/seer/stack/~nec/buried-five and stack buried-six.";
  const context = await loadLibraryContext({}, "", { prompt }, {
    callTool: async (_c, _k, _n, query) => {
      if (query.stack_id) {
        const index = ids.indexOf(query.stack_id);
        assert.notEqual(index, -1, "explicit targets must precede unrelated discovery candidates");
        const owner = query.owner || "~zod";
        const card = { card_id: "evidence", title: "Evidence",
          ref: { ...ref("card", "evidence", query.stack_id), owner } };
        return page("cards", [query.projection === "detail"
          ? { ...card, front: `${owner}/${query.stack_id}`, back: "Exact target body" } : card], query);
      }
      if (query.id) return page("stacks", [{ stack_id: query.id, title: query.id,
        ref: { ...ref("stack", query.id), owner: query.owner || "~zod" } }], query);
      return page("stacks", Array.from({ length: READ_CAPS.libraryMetadataRows }, (_, index) => ({
        stack_id: `unrelated-${index}`, title: "Other", ref: ref("stack", `unrelated-${index}`),
      })), query, { complete: false, next_cursor: "more-library-metadata" });
    },
  });
  assert.deepEqual(context.stacks.map((stack) => stack.stack_id), ids);
  assert.deepEqual(context.stacks.map((stack) => stack.cards[0].front), ids.map((id, index) => `${owners[index]}/${id}`));
  assert.equal(context.complete, false);
  assert.ok(context.omissions.some((row) => row.reason === "page-incomplete" && row.next_cursor === "more-library-metadata"));
  assert.ok(context.omissions.some((row) => row.reason === "library-stack-cap"));
});

test("explicit misses, incomplete reads, and excess targets cannot become whole-library completeness", async () => {
  const ids = ["missing", "oversized", "found-one", "found-two", "found-three", "found-four", "beyond-cap"];
  const omission = { reason: "row-too-large", fields: ["title"] };
  const resolved = [];
  const context = await loadLibraryContext({}, "", { prompt: ids.map((id) => `\`${id}\``).join(" ") }, {
    callTool: async (_c, _k, _n, query) => {
      if (query.stack_id) return page("cards", [], query);
      if (!query.id) return page("stacks", [], query);
      resolved.push(query.id);
      if (query.id === "missing") return page("stacks", [], query, { status: "not-found" });
      if (query.id === "oversized") return page("stacks", [], query, {
        status: "limit-exceeded", complete: false, omissions: [omission],
      });
      return page("stacks", [{ stack_id: query.id, title: query.id, ref: ref("stack", query.id) }], query);
    },
  });
  assert.deepEqual(context.stacks.map((stack) => stack.stack_id), ids.slice(2, 6));
  assert.equal(resolved.includes("beyond-cap"), false);
  assert.equal(context.complete, false);
  assert.ok(context.omissions.some((row) => row.reason === "not-found" && row.scope.stack_id === "missing"));
  assert.ok(context.omissions.some((row) => row.reason === "limit-exceeded" && row.scope.stack_id === "oversized"));
  assert.ok(context.omissions.includes(omission));
  assert.ok(context.omissions.some((row) => row.reason === "library-explicit-stack-cap"));
});

test("all stack metadata is validated before relevance sorting or card dispatch", async () => {
  await assert.rejects(loadLibraryContext({}, "", { prompt: "Compare the library" }, {
    callTool: async (_c, _k, _n, query) => {
      assert.equal(query.stack_id, undefined, "malformed discovery must not dispatch card reads");
      return page("stacks", [
        ...Array.from({ length: READ_CAPS.libraryStacks }, (_, index) => ({
          stack_id: `valid-${index}`, title: "Valid", ref: ref("stack", `valid-${index}`),
        })),
        { stack_id: "malformed", title: { text: "Not a title" } },
      ], query);
    },
  }), { code: "INCOMPLETE_LIBRARY_METADATA", message: /Incomplete stack metadata read:.*title/u });
});

test("exact discovery responses share the total library budget with selected bodies", async () => {
  let responseBytes = 0;
  let queries = 0;
  const ids = Array.from({ length: READ_CAPS.libraryStacks }, (_, index) => `target-${index}`);
  const context = await loadLibraryContext({}, "", { prompt: ids.map((id) => `\`${id}\``).join(" ") }, {
    callTool: async (_c, _k, _n, query) => {
      queries += 1;
      let result;
      if (!query.stack_id) {
        result = page("stacks", query.id ? [{
          stack_id: query.id, title: "Long metadata ".repeat(200), ref: ref("stack", query.id),
        }] : [], query);
      } else {
        const rows = Array.from({ length: READ_CAPS.cardsPerStack }, (_, index) => ({
          card_id: `card-${index}`, title: "Card", ref: ref("card", `card-${index}`, query.stack_id),
        }));
        result = page("cards", query.projection === "detail"
          ? [{ ...rows.find((row) => row.card_id === query.id), front: "Q".repeat(12_000), back: "Answer" }]
          : rows, query);
      }
      if (Buffer.byteLength(JSON.stringify(result)) > Number(query.max_bytes)) {
        result = page(query.stack_id ? "cards" : "stacks", [], query, {
          status: "limit-exceeded", complete: false, omissions: [{ reason: "row-too-large" }],
        });
      }
      responseBytes += Buffer.byteLength(JSON.stringify(result));
      return result;
    },
  });
  assert.ok(responseBytes <= READ_CAPS.libraryBytes, `read ${responseBytes} bytes`);
  assert.ok(queries <= READ_CAPS.libraryStacks * 2 + READ_CAPS.libraryCards + 1);
  assert.equal(context.stacks[0].cards[0].front, "Q".repeat(12_000));
  assert.equal(context.complete, false);
  assert.ok(context.omissions.some((row) => ["library-cap", "library-byte-cap", "limit-exceeded"].includes(row.reason)));
});

test("omitted card titles fail closed before detail expansion or indexing", async () => {
  await assert.rejects(loadLibraryContext({}, "", { prompt: "Compare the library" }, {
    callTool: async (_c, _k, _n, query) => {
      assert.notEqual(query.projection, "detail", "incomplete card metadata must not dispatch body reads");
      if (!query.stack_id) return page("stacks", [{ stack_id: "selected", title: "Selected", ref: ref("stack", "selected") }], query);
      return page("cards", [
        { card_id: "valid", title: "Valid", ref: ref("card", "valid", "selected") },
        { card_id: "omitted-title", title: "", title_omitted: true, ref: ref("card", "omitted-title", "selected") },
      ], query);
    },
  }), { code: "INCOMPLETE_LIBRARY_METADATA", message: /Incomplete card metadata read:.*title/u });
});

test("an exact metadata hit without its identity is an explicit incomplete read", async () => {
  await assert.rejects(loadLibraryContext({}, "", { prompt: "Read stack_id=selected" }, {
    callTool: async (_c, _k, _n, query) => page("stacks", [{ title: "Missing identity" }], query),
  }), { code: "INCOMPLETE_LIBRARY_METADATA", message: /Incomplete stack metadata read:.*stack_id/u });
});

test("packet verification preserves exact source bytes and checks both digests", () => {
  const { packet, job } = packetFixture();
  assert.equal(validateContextPacket(packet, job), packet.canonical_prompt);
  for (const changed of [{ canonical_prompt: packet.canonical_prompt + "\n" }, { input_bytes: 1 },
    { input_digest: "0x1" }, { blocked_reason: "egress-denied" },
    { profile: { ...packet.profile, model: "default" } }]) {
    assert.throws(() => validateContextPacket({ ...packet, ...changed }, job));
  }
  const expected = createHash("sha256").update("é").digest().reverse().toString("hex");
  assert.equal(BigInt(promptDigest("é").replaceAll(".", "")), BigInt(`0x${expected}`));
});

test("source checkpoint rejection prevents provider dispatch", async () => {
  const fixture = packetFixture();
  const { runtime, calls } = workRuntime(fixture, async () => assert.fail("provider must not be reached"), {
    "seer/checkpoint-work": (args) => args.stage === "provider-started" ? { status: "blocked" } : { status: "ok" },
  });
  await assert.rejects(processQuestion(config, "", { codex: "/exact" }, fixture.job, runtime));
  assert.equal(calls.some(({ name }) => name === "seer/answer-card-question"), false);
});

test("unsupported provider remains an explicit failure without a legacy prompt path", async () => {
  const fixture = packetFixture();
  const { runtime, calls } = workRuntime(fixture, async ({ prompt, job }) => {
    assert.equal(prompt, fixture.packet.canonical_prompt);
    assert.equal(job.model, "exact-model");
    throw Object.assign(new Error("private provider output"), { code: "PROVIDER_UNSUPPORTED" });
  });
  await assert.rejects(processQuestion(config, "", { codex: "/exact" }, fixture.job, runtime), { code: "PROVIDER_UNSUPPORTED" });
  assert.deepEqual(calls.filter(({ name }) => name === "seer/fail-card-question").map(({ args }) => args.error), ["PROVIDER_UNSUPPORTED"]);
  assert.equal(calls.some(({ name }) => name === "seer/answer-card-question"), false);
});

test("known unsupported capability consumes no invocation checkpoint", async () => {
  const fixture = packetFixture();
  const { runtime, calls } = workRuntime(fixture, async () => assert.fail("no prompt dispatch"));
  runtime.inspectProvider = async () => ({ supported: false, reason: "isolation-unavailable" });
  await assert.rejects(processQuestion(config, "", { codex: "/exact" }, fixture.job, runtime), { code: "PROVIDER_UNSUPPORTED" });
  assert.equal(calls.some(({ name, args }) => name === "seer/checkpoint-work" && args.stage === "provider-started"), false);
  assert.equal(calls.find(({ name }) => name === "seer/fail-card-question").args.error, "PROVIDER_UNSUPPORTED");
});

test("a failed library scan cannot freeze a packet or start a provider", async () => {
  const fixture = packetFixture("change", "library");
  fixture.job.work.packet_ref = null;
  const { runtime, calls } = workRuntime(fixture, async () => assert.fail("provider must not receive a failed read"), {
    "seer/state-context": (args) => page("stacks", [], args, {
      status: "limit-exceeded", complete: false, omissions: [{ reason: "limit-exceeded" }],
    }),
    "seer/prepare-change-packet": () => assert.fail("failed context must not be frozen"),
  });
  await assert.rejects(processChange(config, "", { codex: "/exact" }, fixture.job, runtime),
    { code: "INCOMPLETE_LIBRARY_READ" });
  assert.equal(calls.some(({ name, args }) => name === "seer/checkpoint-work" && args.stage === "provider-started"), false);
});

test("resumed library work cannot discard its frozen coverage warning", async () => {
  const library = {
    observations: [],
    read_report: { scope: "local-library", complete: false,
      omissions: [{ scope: "stacks", reason: "page-incomplete", next_cursor: "continue-here" }] },
    source_coverage: { scope: "local-library", owner: "~zod", complete: false,
      stack_count: 101, observed_stack_count: 0, unobserved_stack_count: 101,
      card_count: 0, observed_card_count: 0, unobserved_card_count: 0 },
  };
  const fixture = packetFixture("change", "library", library);
  let invocations = 0;
  const { runtime } = workRuntime(fixture, async ({ prompt }) => {
    invocations += 1;
    const input = JSON.parse(prompt.split("BEGIN UNTRUSTED INPUT JSON\n")[1].split("\nEND UNTRUSTED INPUT JSON")[0]);
    const visible = JSON.parse(input.card.front);
    assert.equal(visible.source_coverage.unobserved_stack_count, 101);
    assert.equal(visible.read_report.omissions[0].next_cursor, "continue-here");
    return JSON.stringify({ summary: "Expand the named scope before making a plan", operations: [], citations: [] });
  });
  await assert.rejects(processChange(config, "", { codex: "/exact" }, fixture.job, runtime),
    { code: "NO_SUPPORTED_CANDIDATE" });
  assert.equal(invocations, 1);

  const missing = packetFixture("change", "library", { observations: [], source_coverage: library.source_coverage });
  const denied = workRuntime(missing, async () => assert.fail("unreported coverage must not reach a provider"));
  await assert.rejects(processChange(config, "", { codex: "/exact" }, missing.job, denied.runtime),
    { code: "INVALID_LIBRARY_READ_REPORT" });
});

test("provider output is published as one complete plan, not incremental effects", async () => {
  const fixture = packetFixture("change", "library");
  const operations = [
    { kind: "create-stack", stack_id: "new", card_id: "", title: "New", front: "", back: "", original_title: "", original_front: "", original_back: "" },
    { kind: "create-card", stack_id: "new", card_id: "card", title: "Card", front: "Q", back: "A", original_title: "", original_front: "", original_back: "" },
  ];
  const { runtime, calls } = workRuntime(fixture, async () => JSON.stringify({ summary: "Complete candidate", operations, citations: [] }));
  await processChange(config, "", { codex: "/exact" }, fixture.job, runtime);
  const finish = calls.filter(({ name }) => name === "seer/finish-change");
  assert.equal(finish.length, 1);
  assert.deepEqual(finish[0].args.operations, operations);
  assert.equal(calls.some(({ name }) => name === "seer/stage-change-operation"), false);
});

test("lost result publication is not followed by a failure mutation or provider rerun", async () => {
  const fixture = packetFixture();
  let invocations = 0;
  const { runtime, calls } = workRuntime(fixture, async () => { invocations++; return JSON.stringify({ answer: "A", citations: [] }); }, {
    "seer/answer-card-question": () => { throw Object.assign(new Error("lost"), { ambiguous: true }); },
  });
  await assert.rejects(processQuestion(config, "", { codex: "/exact" }, fixture.job, runtime));
  assert.equal(invocations, 1);
  assert.equal(calls.some(({ name }) => name === "seer/fail-card-question"), false);
});

test("catalog replacement is one mutation and signs every profile definition", async (t) => {
  const profiles = [{ id: "exact", provider: "codex", role: "default", selector: "openai-codex/exact", model: "exact", label: "Exact", description: "Account model" }];
  const server = await localMcp(t, (name, args) => {
    if (name === "seer/replace-assistant-models") {
      assert.ok(validProof("replace-assistant-models", args, "catalog", ["1", "exact", "codex", "default", "openai-codex/exact", "exact", "Exact", "Account model"]));
    }
    return receipt(name.slice(5), args);
  });
  await publishModelProfiles(server.config, "account", profiles);
  assert.deepEqual(server.requests.map(({ params }) => params.name), ["seer/issue-bridge-nonce", "seer/replace-assistant-models"]);
});

test("library observations use source identity and separate content/review revisions", () => {
  const observations = libraryObservations({ stacks: [{ ref: ref("stack", "s"), cards: [{ ref: ref("card", "c", "s") }] }] });
  assert.equal(observations[1].ref.scope, "s");
  assert.equal(observations[1].version.content_revision, 2);
  assert.equal(observations[1].version.review_revision, 3);
  assert.equal(observations[1].content, true);
  assert.equal(observations[1].review, false);
  assert.throws(() => libraryObservations({ stacks: [{ cards: [] }] }));
});

test("slow work does not block other queue classes or consume unbounded pages", async () => {
  const state = createBridgeReadState();
  let release;
  const slow = new Promise((resolve) => { release = resolve; });
  const admissions = [];
  const rows = {
    "seer/list-context-sources": ["contexts", { context_id: "web", status: "pending", active: true, kind: "web" }],
    "seer/list-card-questions": ["questions", { question_id: "q", status: "pending" }],
    "seer/list-change-requests": ["changes", { change_id: "plan", status: "pending" }],
    "seer/list-login-requests": ["logins", { login_id: "login", status: "pending", provider: "codex" }],
  };
  const runtime = {
    callTool: async (_c, _k, name, args) => page(rows[name][0], args.since ? [] : [rows[name][1]], args,
      args.since ? { status: "unchanged" } : {}),
    processContextSource: () => { admissions.push("context"); return slow; },
    processQuestion: async () => { admissions.push("question"); },
    processChange: async () => { admissions.push("change"); },
    startLogin: async () => { admissions.push("login"); },
  };
  assert.equal(await poll(config, "", {}, {}, async () => {}, state, runtime), 4);
  assert.deepEqual(admissions, ["context", "question", "change", "login"]);
  assert.equal(state.active.has("seer/list-context-sources"), true);
  await poll(config, "", {}, {}, async () => {}, state, runtime);
  assert.equal(admissions.filter((kind) => kind === "context").length, 1);
  release();
  await Promise.allSettled([...state.active.values()]);
});

test("explicit recovery reads durable attempt identity and refuses an unexpired lease", async () => {
  const fixture = packetFixture();
  const calls = [];
  const runtime = { callTool: async (_c, _k, name, args) => {
    calls.push({ name, args });
    if (name === "seer/list-card-questions") return page("questions", [fixture.job], args);
    return { status: "ok" };
  } };
  await assert.rejects(recoverWork(config, "", "question", fixture.job.question_id, runtime), { code: "WORK_FENCED" });
  fixture.job.work.lease_until_ms = Date.now() - 1;
  await recoverWork(config, "", "question", fixture.job.question_id, runtime);
  assert.equal(calls.at(-1).name, "seer/recover-work");
  assert.equal(calls.at(-1).args.attempt, "1");
  assert.equal(calls.at(-1).args.lease, "0xb");
});

test("web acquisition rejects private redirects and bounds normalized UTF-8 bytes", async () => {
  const publicLookup = async () => [{ address: "93.184.216.34", family: 4 }];
  let fetches = 0;
  await assert.rejects(fetchWebContext("https://example.com", { lookupImpl: publicLookup,
    fetchImpl: async () => { fetches++; return new Response(null, { status: 302, headers: { location: "http://127.0.0.1/private" } }); },
  }));
  assert.equal(fetches, 1);
  await assert.rejects(fetchWebContext("https://example.com", { lookupImpl: publicLookup,
    maxBytes: 5, fetchImpl: async () => new Response("ééé"),
  }));
  assert.equal(isPrivateContextAddress("::ffff:7f00:1"), true);
  assert.throws(() => validateContextUrl("http://user:password@example.com"));
  assert.equal(normalizeContextContent("<script>secret</script><p>Fact &amp; context</p>", "text/html"), "Fact & context");
});

test("interactive account process has hard byte bounds and never returns child diagnostics on failure", async () => {
  const handle = runInteractive(process.execPath, ["-e", "process.stderr.write('private-secret'.repeat(10000));setInterval(()=>{},1000)"], { timeoutMs: 1000, killAfterMs: 10 });
  await assert.rejects(handle.completion, (error) => error.code === "PROCESS_OUTPUT_LIMIT" && !String(error).includes("private-secret"));
});

test("interactive account process can receive a one-shot code and is cancellable", async () => {
  let handle;
  handle = runInteractive(process.execPath, ["-e", "process.stdout.write('challenge');process.stdin.once('data',()=>process.exit(0))"], {
    timeoutMs: 1000, onOutput() { handle.write("one-shot-code\n"); },
  });
  assert.deepEqual(await handle.completion, { code: 0 });
  const cancelled = runInteractive(process.execPath, ["-e", "setInterval(()=>{},1000)"], { timeoutMs: 1000, killAfterMs: 10 });
  cancelled.kill();
  await assert.rejects(cancelled.completion, { code: "PROCESS_CANCELLED" });
});

test("typed plans allow complete new-stack/card plans but reject duplicate targets", () => {
  const create = { kind: "create-stack", stack_id: "new", title: "New" };
  assert.throws(() => parseStatePlan(JSON.stringify({ summary: "Duplicate", operations: [create, create] })));
  assert.throws(() => parseStatePlan(JSON.stringify({ summary: "Unsafe", operations: [{ kind: "run-hoon", stack_id: "new" }] })));
  assert.throws(() => parseEditResult(JSON.stringify({ title: "x".repeat(241), front: "Q", back: "A", summary: "S" })));
});

test("source cancellation discovered before dispatch stops without a late failure write", async () => {
  const fixture = packetFixture();
  const { runtime, calls } = workRuntime(fixture, async () => assert.fail("cancelled provider invocation"));
  runtime.inspectProvider = async () => {
    fixture.job.status = "cancelled";
    fixture.job.work.execution = "cancelled";
    return { supported: true };
  };
  await assert.rejects(processQuestion(config, "", { codex: "/exact" }, fixture.job, runtime), { code: "WORK_FENCED" });
  assert.equal(calls.some(({ name }) => name === "seer/fail-card-question"), false);
  assert.equal(calls.some(({ name, args }) => name === "seer/checkpoint-work" && args.stage === "provider-started"), false);
});

test("a lost one-shot login code never reaches stdin or triggers another consumption", async () => {
  const fixture = packetFixture();
  const job = { ...fixture.job, ref: ref("login", "login-one"), login_id: "login-one",
    provider: "claude", code_ready: true };
  let consumed = 0, writes = 0, killed = 0;
  let rejectProcess;
  const completion = new Promise((_, reject) => { rejectProcess = reject; });
  const runtime = {
    sleep: async () => {},
    callTool: async (_config, _cookie, name, args) => {
      if (name === "seer/list-login-requests") return page("logins", [job], args);
      if (name === "seer/consume-login-code") {
        consumed++;
        assert.equal(args.content_revision, "2");
        return { receipt: { status: "ok" }, result: { status: "delivery-unavailable" } };
      }
      return { status: "ok" };
    },
    runInteractive(_command, _args, options) {
      queueMicrotask(() => options.onOutput({ stdout: "https://claude.com/cai/oauth/authorize?state=private", stderr: "" }));
      return { completion, write() { writes++; }, kill() {
        killed++; rejectProcess(Object.assign(new Error("private child output"), { code: "PROCESS_CANCELLED" }));
      } };
    },
    claudeLoggedIn: async () => assert.fail("must not certify an undelivered login"),
  };
  assert.equal(await startLogin(config, "", { claude: "/exact" }, job, async () => {}, runtime), false);
  assert.equal(consumed, 1);
  assert.equal(writes, 0);
  assert.ok(killed > 0);
});

async function cancellationServer(t, { acknowledgement = "lost", alterReceipt = (value) => value,
  receiptUnavailable = false } = {}) {
  const { job } = packetFixture();
  const cookie = "urbauth-~zod=owner-test";
  const durable = new Map();
  const observed = { posts: 0, reconciliations: 0, forbiddenCalls: 0, cancelled: false };
  const unknown = (args) => receipt("unknown", args, { status: "outcome-unknown", effect: "unknown" });
  const server = await localMcp(t, (name, args, request, response) => {
    if (request.headers.cookie !== cookie) throw new Error("unauthenticated");
    if (name === "seer/list-card-questions") return page("questions", [job], args);
    if (name !== "seer/get-operation-result") {
      observed.forbiddenCalls++;
      throw new Error("only read-only MCP calls are permitted");
    }
    observed.reconciliations++;
    if (receiptUnavailable) { response.destroy(); return; }
    const result = durable.get(JSON.stringify([args.idempotency_epoch, args.operation_id]));
    return alterReceipt(result || unknown(args));
  }, (fields, request, response) => {
    observed.posts++;
    if (request.url !== "/apps/seer/actions/cancel-work" || request.method !== "POST"
      || request.headers.cookie !== cookie
      || request.headers["content-type"] !== "application/x-www-form-urlencoded"
      || fields.get("idempotency-epoch") !== epoch || !fields.get("operation-id")
      || fields.get("work-kind") !== job.ref.kind || fields.get("work-owner") !== job.ref.owner
      || fields.get("work-scope") !== job.ref.scope || fields.get("work-id") !== job.ref.id) {
      response.writeHead(400); response.end(); return;
    }
    const identity = { idempotency_epoch: fields.get("idempotency-epoch"),
      operation_id: fields.get("operation-id") };
    durable.set(JSON.stringify([identity.idempotency_epoch, identity.operation_id]),
      receipt("cancel-work", identity));
    observed.cancelled = true;
    if (acknowledgement === "lost") { response.destroy(); return; }
    response.writeHead(204); response.end();
  });
  return { ...server, cookie, job, observed,
    hasReceipt: (identity) => durable.has(JSON.stringify([identity.idempotency_epoch, identity.operation_id])) };
}

test("native cancellation reconciles a durable OK receipt with no library effect after a lost acknowledgement without replay", async (t) => {
  const server = await cancellationServer(t);
  const result = await cancelWork(server.config, server.cookie, "question", server.job.question_id);
  assert.equal(result.status, "ok");
  assert.equal(result.effect, "none");
  assert.deepEqual(server.observed, { posts: 1, reconciliations: 1, forbiddenCalls: 0, cancelled: true });
});

test("native cancellation rejects a receipt belonging to another request or action", async (t) => {
  for (const [field, value] of [
    ["idempotency_epoch", "~2026.9.3..00.00.00..0000"],
    ["operation_id", "another-cancellation"],
    ["action", "recover-work"],
  ]) {
    await t.test(field, async (t) => {
      const server = await cancellationServer(t, { alterReceipt: (result) => ({ ...result, [field]: value }) });
      await assert.rejects(cancelWork(server.config, server.cookie, "question", server.job.question_id),
        (error) => error.ambiguous === true);
      assert.deepEqual(server.observed, { posts: 1, reconciliations: 1, forbiddenCalls: 0, cancelled: true });
    });
  }
});

test("a native HTTP acknowledgement cannot substitute for an OK cancellation receipt with no library effect", async (t) => {
  for (const outcome of [
    { status: "ok", effect: "committed" },
    { status: "ok", effect: "staged" },
    { status: "ok", effect: "unknown" },
    { status: "conflict", effect: "none" },
  ]) {
    await t.test(`${outcome.status}/${outcome.effect}`, async (t) => {
      const server = await cancellationServer(t, { acknowledgement: "ok",
        alterReceipt: (result) => ({ ...result, ...outcome }) });
      await assert.rejects(cancelWork(server.config, server.cookie, "question", server.job.question_id));
      assert.deepEqual(server.observed, { posts: 1, reconciliations: 1, forbiddenCalls: 0, cancelled: true });
    });
  }
});

test("unknown native cancellation outcomes remain ambiguous and never authorize another POST", async (t) => {
  for (const receiptUnavailable of [false, true]) {
    await t.test(receiptUnavailable ? "receipt transport lost" : "source outcome unknown", async (t) => {
      const server = await cancellationServer(t, { receiptUnavailable,
        alterReceipt: (result) => ({ ...result, action: "unknown", status: "outcome-unknown", effect: "unknown" }) });
      await assert.rejects(cancelWork(server.config, server.cookie, "question", server.job.question_id),
        (error) => error.ambiguous === true && server.hasReceipt(error.receipt || error));
      assert.deepEqual(server.observed, { posts: 1, reconciliations: 1, forbiddenCalls: 0, cancelled: true });
    });
  }
});
