import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
  RETIRED_SEER_TOOLS, checkAlignment, readBoundedPage, resolveConnection,
} from "./check-ship-alignment.mjs";

const epoch = "~2026.9.4..00.00.00..0000";
const cookie = "urbauth-~zod=release-canary";
const envelope = ["schema_version", "idempotency_epoch", "operation_id"];
const toolContract = JSON.parse(await readFile(
  new URL("./seer-tool-contract.json", import.meta.url), "utf8",
));
const plannerTools = [
  "seer/begin-capture", "seer/prepare-capture", "seer/stage-card", "seer/ask-card", "seer/request-change",
  "seer/propose-change", "seer/attach-context-source", "seer/refresh-context-source",
  "seer/archive-context-source", "seer/rename-context-source",
];
const capabilities = {
  capabilities_revision: 3, authority: "owner-trusted", scoped_delegation: false, mutation_receipts: true,
  execution: "ship-native; outbound requests are the ship's own events, no paired worker",
  operations: { planner: plannerTools, operator: ["/apps/seer/inbox", "/apps/seer/settings"] },
};

function catalog() {
  return Object.entries(toolContract).map(([name, inputSchema]) => ({
    name, inputSchema: structuredClone(inputSchema),
  }));
}

function bounded(query, extra = {}) {
  const envelope = { schema_version: 3, status: "ok", state_revision: 1, observed_at: epoch,
    idempotency_epoch: epoch, watermark: "release-snapshot", projection: "metadata",
    complete: true, next_cursor: null, omissions: [],
    limits: { limit: Number(query.limit), max_bytes: Number(query.max_bytes) } };
  const result = { ...envelope, ...extra };
  if (Buffer.byteLength(JSON.stringify(result), "utf8") <= envelope.limits.max_bytes) return result;
  return { ...envelope, status: "limit-exceeded", complete: false,
    ["stacks" in extra ? "stacks" : "work"]: [],
    omissions: [{ ref: null, reason: "limit-exceeded" }] };
}

async function localShip(t, { tools = catalog(), orientation = {}, alterReceipt = (value) => value } = {}) {
  const calls = [];
  const server = createServer(async (request, response) => {
    try {
      let body = "";
      for await (const chunk of request) body += chunk;
      const rpc = JSON.parse(body);
      calls.push(rpc.method === "tools/list" ? "tools/list" : rpc.params?.name);
      if (request.url !== "/mcp" || request.method !== "POST" || request.headers.cookie !== cookie) {
        response.writeHead(403); response.end(); return;
      }
      let result;
      if (rpc.method === "tools/list") result = { tools };
      else if (rpc.method === "tools/call") {
        const { name, arguments: query } = rpc.params;
        if (query.schema_version !== 3) throw new Error("read without schema_version 3");
        if (name === "seer/agent-context") {
          result = bounded(query, { ...capabilities, ...orientation });
        } else if (name === "seer/state-context") {
          result = bounded(query, { stacks: [], status: query.since === "release-snapshot" ? "unchanged" : "ok" });
        } else if (name === "seer/get-operation-result") {
          result = alterReceipt({ schema_version: 3, idempotency_epoch: query.idempotency_epoch,
            operation_id: query.operation_id, action: "unknown", status: "outcome-unknown", effect: "unknown" });
        } else throw new Error("canary attempted a non-read tool");
        result = { structuredContent: result };
      } else throw new Error("unexpected MCP method");
      response.writeHead(200, { "Content-Type": "application/json" });
      response.end(JSON.stringify({ jsonrpc: "2.0", id: rpc.id, result }));
    } catch {
      response.writeHead(500); response.end();
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(async () => {
    server.closeAllConnections();
    await new Promise((resolve) => server.close(resolve));
  });
  return { calls, config: { mcpUrl: `http://127.0.0.1:${server.address().port}/mcp`, mcpTimeoutMs: 1000 } };
}

const alignedCalls = ["tools/list", "seer/agent-context", "seer/state-context",
  "seer/state-context", "seer/get-operation-result"];

test("the contract names exactly the 27 schema-3 tools and none of the retired ones", () => {
  const names = Object.keys(toolContract);
  assert.equal(names.length, 27);
  assert.equal(RETIRED_SEER_TOOLS.length, 21);
  assert.deepEqual(names.filter((name) => RETIRED_SEER_TOOLS.includes(name)), []);
  for (const name of plannerTools) assert.ok(names.includes(name), name);
});

test("release canary accepts live schema-3 orientation, bounded resume, and an identity-preserving unknown receipt without mutations", async (t) => {
  const ship = await localShip(t);
  const result = await checkAlignment(ship.config, cookie);
  assert.equal(result.schema_version, 3);
  assert.equal(result.seer_tools, 27);
  assert.equal(result.planner_tools, plannerTools.length);
  assert.equal(result.resume_status, "unchanged");
  assert.deepEqual(ship.calls, alignedCalls);
});

test("a valid active-work orientation exceeding 4 KiB is not reported as protocol drift", async (t) => {
  const orientation = JSON.parse(await readFile(
    new URL("./fixtures/active-work-orientation.json", import.meta.url), "utf8",
  ));
  const ship = await localShip(t, { orientation });
  const constrained = await readBoundedPage(ship.config, cookie, "seer/agent-context", {
    limit: 1, max_bytes: 4096,
  });
  assert.equal(constrained.status, "limit-exceeded");
  const result = await checkAlignment(ship.config, cookie);
  assert.equal(result.resume_status, "unchanged");
  assert.ok(result.structured_bytes.orientation > 4096);
});

test("a complete catalog cannot hide an unlisted stale Seer tool", async (t) => {
  const tools = catalog();
  tools.push({ name: "seer/legacy-provider-status", inputSchema: { type: "object", properties: {} } });
  const ship = await localShip(t, { tools });
  await assert.rejects(checkAlignment(ship.config, cookie), /unknown Seer tools/);
  assert.deepEqual(ship.calls, ["tools/list"]);
});

test("any surviving schema-2 worker or pairing tool fails the catalogue by name", async (t) => {
  for (const name of RETIRED_SEER_TOOLS) {
    await t.test(name, async (t) => {
      const tools = catalog();
      tools.push({ name, inputSchema: { type: "object", properties: {}, required: [] } });
      const ship = await localShip(t, { tools });
      await assert.rejects(checkAlignment(ship.config, cookie), /retired schema-2 tools still advertised/);
      assert.deepEqual(ship.calls, ["tools/list"]);
    });
  }
});

test("planner tools alone cannot certify the full Seer namespace", async (t) => {
  const tools = catalog().filter((tool) => plannerTools.includes(tool.name));
  const ship = await localShip(t, { tools });
  await assert.rejects(checkAlignment(ship.config, cookie), /Seer tools missing/);
  assert.deepEqual(ship.calls, ["tools/list"]);
});

test("descriptions, catalog and schema ordering, and unrelated MCP tools do not cause drift", async (t) => {
  const tools = catalog().reverse().map((tool) => ({
    ...tool,
    description: "Updated tool help",
    inputSchema: {
      properties: Object.fromEntries(Object.entries(tool.inputSchema.properties).reverse()
        .map(([name, property]) => [name, { description: "Updated field help", ...property }])),
      type: tool.inputSchema.type,
      required: [...tool.inputSchema.required].reverse(),
      description: "Updated schema help",
    },
  }));
  tools.push({ name: "other/create-stack", inputSchema: { type: "object", properties: {} } });
  const ship = await localShip(t, { tools });
  const result = await checkAlignment(ship.config, cookie);
  assert.equal(result.resume_status, "unchanged");
  assert.deepEqual(ship.calls, alignedCalls);
});

test("unchanged envelopes cannot hide action-specific schema drift", async (t) => {
  for (const [name, defect, alterSchema] of [
    ["seer/request-change", "optional model", (schema) => {
      schema.required = schema.required.filter((field) => field !== "model_id");
    }],
    ["seer/attach-context-source", "numeric scope", (schema) => {
      schema.properties.scope_id.type = "number";
    }],
    ["seer/ask-card", "missing evidence selections", (schema) => {
      delete schema.properties.selections;
    }],
    ["seer/request-change", "obsolete stack target", (schema) => {
      schema.properties.stack_id = { type: "string" };
    }],
    ["seer/get-stack", "optional stack scope", (schema) => {
      schema.required = [];
    }],
  ]) {
    await t.test(defect, async (t) => {
      const tools = catalog();
      alterSchema(tools.find((tool) => tool.name === name).inputSchema);
      const ship = await localShip(t, { tools });
      await assert.rejects(checkAlignment(ship.config, cookie), /input schema differs/);
      assert.deepEqual(ship.calls, ["tools/list"]);
    });
  }
});

test("mutation definitions cannot omit the schema and operation envelope", async (t) => {
  for (const name of ["seer/propose-change", "seer/begin-capture"]) {
    for (const field of envelope) {
      await t.test(`${name}/${field}`, async (t) => {
        const tools = catalog();
        const schema = tools.find((tool) => tool.name === name).inputSchema;
        schema.required = schema.required.filter((name) => name !== field);
        const ship = await localShip(t, { tools });
        await assert.rejects(checkAlignment(ship.config, cookie));
        assert.deepEqual(ship.calls, ["tools/list"]);
      });
    }
  }
});

test("read definitions must advertise a numeric schema envelope, not only current tool names", async (t) => {
  const tools = catalog();
  tools.find((tool) => tool.name === "seer/agent-context").inputSchema.properties.schema_version.type = "string";
  const ship = await localShip(t, { tools });
  await assert.rejects(checkAlignment(ship.config, cookie));
  assert.deepEqual(ship.calls, ["tools/list"]);
});

test("a current catalog cannot certify schema-incompatible live orientation", async (t) => {
  for (const [field, value] of [
    ["schema_version", 2], ["capabilities_revision", 2],
    ["authority", "scoped"], ["scoped_delegation", true], ["mutation_receipts", false],
    ["execution", undefined], ["execution", ""],
    ["operations", undefined], ["operations", { planner: [] }], ["operations", { operator: ["/apps/seer/inbox"] }],
    ["operations", { planner: ["seer/claim-change"] }],
  ]) {
    await t.test(`${field}=${JSON.stringify(value)}`, async (t) => {
      const ship = await localShip(t, { orientation: { [field]: value } });
      await assert.rejects(checkAlignment(ship.config, cookie));
      assert.deepEqual(ship.calls, ["tools/list", "seer/agent-context"]);
    });
  }
});

test("release canary refuses fabricated effects or unrelated identities for an unknown operation", async (t) => {
  for (const mismatch of [
    { operation_id: "unrelated-operation" }, { idempotency_epoch: "~2026.9.3..00.00.00..0000" },
    { schema_version: 2 }, { status: "ok", effect: "committed" },
  ]) {
    await t.test(JSON.stringify(mismatch), async (t) => {
      const ship = await localShip(t, { alterReceipt: (result) => ({ ...result, ...mismatch }) });
      await assert.rejects(checkAlignment(ship.config, cookie));
      assert.deepEqual(ship.calls, alignedCalls);
    });
  }
});

test("MCP connection comes from SEER_MCP_URL/SEER_MCP_COOKIE, then the local config file", async () => {
  const dir = await mkdtemp(join(tmpdir(), "seer-canary-"));
  const configPath = join(dir, "ai-bridge.json");
  await writeFile(configPath, JSON.stringify({ mcpUrl: "http://127.0.0.1:8080/mcp", cookie: "urbauth-~zod=file" }));
  assert.deepEqual(await resolveConnection({ SEER_MCP_URL: "http://ship.example/mcp", SEER_MCP_COOKIE: "urbauth-~zod=env" }, configPath),
    { config: { mcpUrl: "http://ship.example/mcp" }, cookie: "urbauth-~zod=env" });
  assert.deepEqual(await resolveConnection({ SEER_MCP_COOKIE: "urbauth-~zod=env" }, configPath),
    { config: { mcpUrl: "http://127.0.0.1:8080/mcp" }, cookie: "urbauth-~zod=env" });
  assert.deepEqual(await resolveConnection({}, configPath),
    { config: { mcpUrl: "http://127.0.0.1:8080/mcp" }, cookie: "urbauth-~zod=file" });
  await assert.rejects(resolveConnection({ SEER_MCP_URL: "http://ship.example/mcp" }, join(dir, "missing.json")), /SEER_MCP_COOKIE/);
  await assert.rejects(resolveConnection({}, join(dir, "missing.json")), /SEER_MCP_URL/);
});
