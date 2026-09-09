#!/usr/bin/env node
// Read-only release canary for the installed desk and its MCP definitions.
// Run after installing the desk and reimporting the %seer tools and prompts.
// Connection: SEER_MCP_URL and SEER_MCP_COOKIE, falling back to the mcpUrl and
// cookie fields of ~/.config/seer/ai-bridge.json.
// Exit: 0 aligned, 1 contract drift, 2 connectivity/configuration failure.

import { readFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";
import { join } from "node:path";
import { isDeepStrictEqual } from "node:util";

export const SEER_SCHEMA_VERSION = 3;

// Every tool the schema-3 desk exports, keyed by name, without descriptions.
const TOOL_CONTRACT = JSON.parse(await readFile(
  new URL("./seer-tool-contract.json", import.meta.url), "utf8",
));

// Schema-2 worker and pairing tools. The ship executes its own work now; any of
// these in a live catalogue means stale definitions survived the reimport.
export const RETIRED_SEER_TOOLS = Object.freeze([
  "seer/issue-bridge-nonce",
  "seer/claim-context-source", "seer/finish-context-source", "seer/fail-context-source",
  "seer/replace-assistant-models",
  "seer/claim-card-question", "seer/answer-card-question", "seer/apply-card-edit", "seer/fail-card-question",
  "seer/claim-change", "seer/prepare-change-packet", "seer/finish-change", "seer/fail-change",
  "seer/claim-login", "seer/post-login-challenge", "seer/finish-login", "seer/fail-login",
  "seer/consume-login-code",
  "seer/checkpoint-work", "seer/heartbeat-work", "seer/recover-work",
]);

const READ_STATUSES = new Set(["ok", "unchanged", "snapshot-expired", "not-found", "invalid-query", "limit-exceeded"]);
const bytes = (value) => Buffer.byteLength(JSON.stringify(value), "utf8");

function connectivity(message) {
  return Object.assign(new Error(message), { code: "CONNECTIVITY" });
}

function schemaContract(schema) {
  if (!schema || typeof schema !== "object" || Array.isArray(schema)) return schema;
  const { description, ...contract } = schema;
  if (Array.isArray(contract.required)) contract.required = [...contract.required].sort();
  if (contract.properties && typeof contract.properties === "object" && !Array.isArray(contract.properties)) {
    contract.properties = Object.fromEntries(Object.entries(contract.properties)
      .map(([name, property]) => [name, schemaContract(property)]));
  }
  return contract;
}

export function diffTools(served, required) {
  const have = new Set(served);
  return required.filter((name) => !have.has(name));
}

export function validateToolCatalog(tools) {
  const names = tools.map((tool) => tool.name);
  const retired = RETIRED_SEER_TOOLS.filter((name) => names.includes(name));
  if (retired.length) throw new Error(`retired schema-2 tools still advertised: ${retired.join(", ")}`);
  const missing = diffTools(names, Object.keys(TOOL_CONTRACT));
  if (missing.length) throw new Error(`Seer tools missing: ${missing.join(", ")}`);
  const unknown = names.filter((name) => name.startsWith("seer/") && !Object.hasOwn(TOOL_CONTRACT, name));
  if (unknown.length) throw new Error(`unknown Seer tools advertised: ${unknown.join(", ")}`);
  const definitions = new Map(tools.map((tool) => [tool.name, tool]));
  if (definitions.size !== names.length) throw new Error("duplicate tool definitions");
  for (const [name, expected] of Object.entries(TOOL_CONTRACT)) {
    if (!isDeepStrictEqual(schemaContract(definitions.get(name).inputSchema), expected)) {
      throw new Error(`${name}: input schema differs from the Seer tool contract`);
    }
  }
}

export function validateOrientation(context) {
  if (context.status !== "ok" || context.schema_version !== SEER_SCHEMA_VERSION
    || context.capabilities_revision !== SEER_SCHEMA_VERSION
    || context.authority !== "owner-trusted" || context.scoped_delegation !== false
    || context.mutation_receipts !== true
    || typeof context.execution !== "string" || !context.execution
    || !Array.isArray(context.operations?.planner) || !context.operations.planner.length
    || !context.operations.planner.every((name) => Object.hasOwn(TOOL_CONTRACT, name))
    || typeof context.idempotency_epoch !== "string" || !context.idempotency_epoch.startsWith("~")) {
    throw new Error("live orientation does not describe schema-3 ship-native execution");
  }
  return context;
}

let rpcId = 1_000;

async function limitedResponseText(response, maxBytes) {
  const declared = Number(response.headers.get("content-length") || 0);
  if (declared > maxBytes) { await response.body?.cancel(); throw connectivity("MCP response exceeds byte limit"); }
  if (!response.body) return "";
  const reader = response.body.getReader();
  const chunks = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) throw connectivity("MCP response exceeds byte limit");
      chunks.push(value);
    }
    return new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(chunks, size));
  } catch (error) {
    await reader.cancel().catch(() => {});
    throw error;
  } finally { reader.releaseLock(); }
}

function parseMcpResponse(text) {
  const payloads = text.split(/\r?\n/)
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trim())
    .filter(Boolean);
  const rpc = JSON.parse(payloads.at(-1) || text.trim());
  if (rpc.error || rpc.result?.isError) throw new Error(`MCP rejected the call: ${JSON.stringify(rpc.error || rpc.result.content)}`);
  const result = rpc.result;
  if (result?.structuredContent) return result.structuredContent;
  const embedded = result?.content?.find((part) => part.type === "text")?.text;
  return embedded === undefined ? result : JSON.parse(embedded);
}

async function rpc(config, cookie, method, params) {
  const body = JSON.stringify({ jsonrpc: "2.0", id: rpcId++, method, params });
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), Math.min(config.mcpTimeoutMs || 30_000, 30_000));
  let response, text;
  try {
    response = await fetch(config.mcpUrl, {
      signal: controller.signal, redirect: "error", method: "POST",
      headers: { Accept: "application/json, text/event-stream", "Content-Type": "application/json", Cookie: cookie }, body,
    });
    text = await limitedResponseText(response, method === "tools/list" ? 1_048_576 : 524_288);
  } catch (error) {
    throw connectivity(`${method}: ${error.message}`);
  } finally { clearTimeout(timer); }
  if (!response.ok) throw connectivity(`${method}: HTTP ${response.status}`);
  return parseMcpResponse(text);
}

export async function listServedTools(config, cookie) {
  const result = await rpc(config, cookie, "tools/list");
  if (!Array.isArray(result?.tools)) throw new Error("tools/list did not return a tool catalogue");
  return result.tools;
}

export async function callTool(config, cookie, name, toolArgs = {}) {
  return rpc(config, cookie, "tools/call", { name, arguments: { ...toolArgs, schema_version: SEER_SCHEMA_VERSION } });
}

export async function readBoundedPage(config, cookie, tool, scope = {}) {
  const query = { projection: "metadata", limit: 20, max_bytes: 32_768, ...scope };
  // %mcp-server parses JSON numbers as @ud, which rejects undotted thousands.
  const page = await callTool(config, cookie, tool, {
    ...query, limit: String(query.limit), max_bytes: String(query.max_bytes),
  });
  if (page?.schema_version !== SEER_SCHEMA_VERSION || !READ_STATUSES.has(page?.status)
    || typeof page.complete !== "boolean" || !Array.isArray(page.omissions)
    || typeof page.watermark !== "string" || !page.watermark
    || page.state_revision == null || typeof page.observed_at !== "string" || !page.observed_at
    || page.idempotency_epoch == null || page.projection !== query.projection
    || page.limits?.limit !== query.limit || page.limits?.max_bytes !== query.max_bytes
    || !(page.next_cursor === null || (typeof page.next_cursor === "string" && page.next_cursor))
    || (page.complete && page.next_cursor !== null)
    || (page.status === "unchanged" && (!query.since || !page.complete || page.omissions.length))
    || bytes(page) > query.max_bytes) {
    throw new Error(`invalid bounded response from ${tool}`);
  }
  return page;
}

export async function checkAlignment(config, cookie) {
  const tools = await listServedTools(config, cookie);
  validateToolCatalog(tools);
  const bounds = { limit: 1, max_bytes: 4096 };
  const context = validateOrientation(await readBoundedPage(
    config, cookie, "seer/agent-context", { ...bounds, max_bytes: 32_768 },
  ));
  const library = await readBoundedPage(config, cookie, "seer/state-context", bounds);
  if (library.status !== "ok" || !Array.isArray(library.stacks)) {
    throw new Error("bounded library metadata unavailable");
  }
  const resumed = await readBoundedPage(config, cookie, "seer/state-context", {
    ...bounds, since: library.watermark,
  });
  if (resumed.status !== "unchanged"
    && !(resumed.status === "ok" && resumed.watermark !== library.watermark)) {
    throw new Error("watermark reconciliation did not report unchanged or a new snapshot");
  }
  const operation = randomUUID();
  const receipt = await callTool(config, cookie, "seer/get-operation-result", {
    idempotency_epoch: context.idempotency_epoch, operation_id: operation,
  });
  if (receipt?.schema_version !== SEER_SCHEMA_VERSION
    || receipt.idempotency_epoch !== context.idempotency_epoch || receipt.operation_id !== operation
    || receipt.status !== "outcome-unknown" || receipt.effect !== "unknown" || bytes(receipt) > 4096) {
    throw new Error("unknown operation reconciliation fabricated an effect or lost its identity");
  }
  return {
    schema_version: SEER_SCHEMA_VERSION, seer_tools: Object.keys(TOOL_CONTRACT).length,
    planner_tools: context.operations.planner.length,
    tool_catalog_calls: 1, bounded_read_calls: 4, resume_status: resumed.status,
    structured_bytes: {
      orientation: bytes(context), library: bytes(library), resumed: bytes(resumed), receipt: bytes(receipt),
    },
  };
}

// SEER_MCP_URL and SEER_MCP_COOKIE win; ~/.config/seer/ai-bridge.json supplies
// whichever is unset from its mcpUrl and cookie fields.
export async function resolveConnection(env = process.env, configPath = join(homedir(), ".config", "seer", "ai-bridge.json")) {
  let file = {};
  if (!env.SEER_MCP_URL || !env.SEER_MCP_COOKIE) {
    try {
      file = JSON.parse(await readFile(configPath, "utf8"));
    } catch (error) {
      if (error.code !== "ENOENT") throw error;
    }
  }
  const mcpUrl = env.SEER_MCP_URL || file.mcpUrl;
  const cookie = env.SEER_MCP_COOKIE || file.cookie;
  if (!mcpUrl) throw new Error(`set SEER_MCP_URL or mcpUrl in ${configPath}`);
  if (!cookie) throw new Error(`set SEER_MCP_COOKIE or cookie in ${configPath}`);
  return { config: { mcpUrl }, cookie };
}

async function main() {
  let connection;
  try {
    connection = await resolveConnection();
  } catch (error) {
    console.error(`connectivity: cannot resolve MCP configuration: ${error.message}`);
    return 2;
  }
  try {
    console.log(`PASS: ${JSON.stringify(await checkAlignment(connection.config, connection.cookie))}`);
    return 0;
  } catch (error) {
    const connectivity = error.code === "CONNECTIVITY";
    console.error(`${connectivity ? "connectivity" : "drift"}: ${error.message}`);
    if (!connectivity) console.error("Install the current desk, |nuke %mcp-server to drop stale definitions, reimport %seer tools and prompts, then rerun. See README.");
    return connectivity ? 2 : 1;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  process.exitCode = await main();
}
