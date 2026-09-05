import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createServer } from "node:http";
import test from "node:test";
import { checkAlignment } from "./check-ship-alignment.mjs";
import { REQUIRED_SEER_TOOLS, readBoundedPage } from "./seer-ai-bridge.mjs";

const epoch = "~2026.9.4..00.00.00..0000";
const cookie = "urbauth-~zod=release-canary";
const envelope = ["schema_version", "idempotency_epoch", "operation_id"];
const workerFields = ["worker_id", "proof_nonce", "proof", "attempt", "lease"];
const toolContract = JSON.parse(await readFile(
  new URL("./seer-tool-contract.json", import.meta.url), "utf8",
));

function catalog() {
  return Object.entries(toolContract).map(([name, inputSchema]) => ({
    name, inputSchema: structuredClone(inputSchema),
  }));
}

function bounded(query, extra = {}) {
  const envelope = { schema_version: 2, status: "ok", state_revision: 1, observed_at: epoch,
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
        if (name === "seer/agent-context") {
          result = bounded(query, { capabilities_revision: 2, authority: "owner-trusted",
            worker_authority: "paired-proof-seer-bridge-v2", scoped_delegation: false,
            mutation_receipts: true, leased_execution: true, ...orientation });
        } else if (name === "seer/state-context") {
          result = bounded(query, { stacks: [], status: query.since === "release-snapshot" ? "unchanged" : "ok" });
        } else if (name === "seer/get-operation-result") {
          result = alterReceipt({ schema_version: 2, idempotency_epoch: query.idempotency_epoch,
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

test("release canary accepts live schema2 orientation, bounded resume, and an identity-preserving unknown receipt without mutations", async (t) => {
  const ship = await localShip(t);
  const result = await checkAlignment(ship.config, cookie);
  assert.equal(result.schema_version, 2);
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

test("bridge-required tools alone cannot certify the full Seer namespace", async (t) => {
  const tools = catalog().filter((tool) => REQUIRED_SEER_TOOLS.includes(tool.name));
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
    ["seer/checkpoint-work", "missing work scope", (schema) => {
      delete schema.properties.work_scope;
    }],
    ["seer/request-change", "obsolete stack target", (schema) => {
      schema.properties.stack_id = { type: "string" };
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

test("worker definitions must require typed proof and exact lease fencing despite complete name coverage", async (t) => {
  for (const field of workerFields) {
    for (const defect of ["optional", "untyped"]) {
      await t.test(`${field}/${defect}`, async (t) => {
        const tools = catalog();
        const schema = tools.find((tool) => tool.name === "seer/checkpoint-work").inputSchema;
        if (defect === "optional") schema.required = schema.required.filter((name) => name !== field);
        else delete schema.properties[field];
        const ship = await localShip(t, { tools });
        await assert.rejects(checkAlignment(ship.config, cookie));
        assert.deepEqual(ship.calls, ["tools/list"]);
      });
    }
  }
});

test("worker and nonce definitions cannot omit required schema and operation envelopes", async (t) => {
  for (const name of ["seer/checkpoint-work", "seer/issue-bridge-nonce"]) {
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
    ["schema_version", 1], ["capabilities_revision", 1], ["worker_authority", "paired-proof"],
    ["authority", "scoped"], ["scoped_delegation", true], ["mutation_receipts", false], ["leased_execution", false],
  ]) {
    await t.test(field, async (t) => {
      const ship = await localShip(t, { orientation: { [field]: value } });
      await assert.rejects(checkAlignment(ship.config, cookie));
      assert.deepEqual(ship.calls, ["tools/list", "seer/agent-context"]);
    });
  }
});

test("release canary refuses fabricated effects or unrelated identities for an unknown operation", async (t) => {
  for (const mismatch of [
    { operation_id: "unrelated-operation" }, { idempotency_epoch: "~2026.9.3..00.00.00..0000" },
    { schema_version: 1 }, { status: "ok", effect: "committed" },
  ]) {
    await t.test(JSON.stringify(mismatch), async (t) => {
      const ship = await localShip(t, { alterReceipt: (result) => ({ ...result, ...mismatch }) });
      await assert.rejects(checkAlignment(ship.config, cookie));
      assert.deepEqual(ship.calls, alignedCalls);
    });
  }
});
