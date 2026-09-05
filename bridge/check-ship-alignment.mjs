#!/usr/bin/env node
// Read-only release canary for the installed desk, MCP definitions and bridge.
// Run after an explicit pre-release state reset and definition reimport.
// Exit: 0 aligned, 1 contract drift, 2 connectivity/configuration failure.

import { readFile } from "node:fs/promises";
import { randomUUID } from "node:crypto";
import { homedir } from "node:os";
import { join } from "node:path";
import { isDeepStrictEqual } from "node:util";
import {
  REQUIRED_SEER_TOOLS, SEER_SCHEMA_VERSION, callTool, extractMcpCookie,
  listServedTools, readBoundedPage, validateBridgeProtocol,
} from "./seer-ai-bridge.mjs";

// Generated from the observed 48-tool schema-2 catalog, excluding descriptions.
const TOOL_CONTRACT = JSON.parse(await readFile(
  new URL("./seer-tool-contract.json", import.meta.url), "utf8",
));

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
  const missing = diffTools(names, REQUIRED_SEER_TOOLS);
  if (missing.length) throw new Error(`required tools missing: ${missing.join(", ")}`);
  const missingSeer = diffTools(names, Object.keys(TOOL_CONTRACT));
  if (missingSeer.length) throw new Error(`Seer tools missing: ${missingSeer.join(", ")}`);
  const unknownSeer = names.filter((name) => name.startsWith("seer/") && !Object.hasOwn(TOOL_CONTRACT, name));
  if (unknownSeer.length) throw new Error(`unknown Seer tools advertised: ${unknownSeer.join(", ")}`);
  const definitions = new Map(tools.map((tool) => [tool.name, tool]));
  if (definitions.size !== names.length) throw new Error("duplicate tool definitions");
  for (const [name, expected] of Object.entries(TOOL_CONTRACT)) {
    if (!isDeepStrictEqual(schemaContract(definitions.get(name).inputSchema), expected)) {
      throw new Error(`${name}: input schema differs from the Seer tool contract`);
    }
  }
}

const bytes = (value) => Buffer.byteLength(JSON.stringify(value), "utf8");

export async function checkAlignment(config, cookie) {
  const tools = await listServedTools(config, cookie);
  validateToolCatalog(tools);
  const bounds = { limit: 1, max_bytes: 4096 };
  const context = validateBridgeProtocol(await readBoundedPage(
    config, cookie, "seer/agent-context", { ...bounds, max_bytes: 32768 },
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
    schema_version: SEER_SCHEMA_VERSION, required_tools: REQUIRED_SEER_TOOLS.length,
    tool_catalog_calls: 1, bounded_read_calls: 4, resume_status: resumed.status,
    structured_bytes: {
      orientation: bytes(context), library: bytes(library), resumed: bytes(resumed), receipt: bytes(receipt),
    },
  };
}

async function loadConfig() {
  const path = process.env.SEER_BRIDGE_CONFIG || join(homedir(), ".config", "seer", "ai-bridge.json");
  let config = {};
  try {
    config = JSON.parse(await readFile(path, "utf8"));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  config.mcpUrl ||= "http://127.0.0.1:8080/mcp";
  return config;
}

async function resolveCookie(config) {
  if (process.env.SEER_MCP_COOKIE) return process.env.SEER_MCP_COOKIE;
  if (config.cookieEnv && process.env[config.cookieEnv]) return process.env[config.cookieEnv];
  if (config.cookie) return config.cookie;
  const codexConfig = config.codexConfig || join(homedir(), ".codex", "config.toml");
  const cookie = extractMcpCookie(await readFile(codexConfig, "utf8"), config.mcpUrl);
  if (!cookie) throw new Error("no Cookie header for the configured MCP endpoint");
  return cookie;
}

async function main() {
  let config, cookie;
  try {
    config = await loadConfig();
    cookie = await resolveCookie(config);
  } catch (error) {
    console.error(`connectivity: cannot resolve MCP configuration: ${error.message}`);
    return 2;
  }
  try {
    console.log(`PASS: ${JSON.stringify(await checkAlignment(config, cookie))}`);
    return 0;
  } catch (error) {
    const connectivity = ["RPC_FAILED", "MCP_HTTP_FAILED"].includes(error.code);
    console.error(`${connectivity ? "connectivity" : "drift"}: ${error.message}`);
    if (!connectivity) console.error("Install matching desk/bridge code, remove stale MCP definitions, reimport %seer, then rerun. See README.");
    return connectivity ? 2 : 1;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  process.exitCode = await main();
}
