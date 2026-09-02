#!/usr/bin/env node
// check-ship-alignment.mjs: bridge/ship drift canary.
//
// Verifies a live ship serves every MCP tool the bridge requires
// (tools/list vs REQUIRED_SEER_TOOLS) and that a read tool answers
// (tools/call seer/list-stacks). Run this after `|commit %seer` and a
// definitions reimport (mcp/import-mcp-tools), before pushing a release.
// Unit tests mock the ship boundary; this is the integration check of
// the desk/%mcp/bridge composition.
//
// Usage: node bridge/check-ship-alignment.mjs
// Config: ~/.config/seer/ai-bridge.json (or $SEER_BRIDGE_CONFIG) supplies
// mcpUrl + cookie; $SEER_MCP_COOKIE overrides the cookie.
// Exit codes: 0 aligned, 1 drift (missing tools / roundtrip error),
// 2 connectivity or configuration failure.

import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { REQUIRED_SEER_TOOLS, extractMcpCookie } from "./seer-ai-bridge.mjs";

export function diffTools(served, required) {
  const have = new Set(served);
  return required.filter((name) => !have.has(name));
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
  if (!cookie) throw new Error(`no Cookie header for ${config.mcpUrl}`);
  return cookie;
}

let rpcId = 1;

async function rpc(config, cookie, method, params) {
  const response = await fetch(config.mcpUrl, {
    signal: AbortSignal.timeout(config.mcpTimeoutMs || 30_000),
    method: "POST",
    headers: {
      "Accept": "application/json, text/event-stream",
      "Content-Type": "application/json",
      "Cookie": cookie,
    },
    body: JSON.stringify({ jsonrpc: "2.0", id: rpcId++, method, ...(params ? { params } : {}) }),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`MCP HTTP ${response.status}: ${text.slice(0, 200)}`);
  const payloads = text
    .split(/\r?\n/)
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trim())
    .filter(Boolean);
  const parsed = JSON.parse(payloads.at(-1) || text.trim());
  if (parsed.error) throw new Error(parsed.error.message || JSON.stringify(parsed.error).slice(0, 200));
  return parsed.result;
}

function isConnectivityError(error) {
  return error?.name === "AbortError" || error?.name === "TimeoutError"
    || error instanceof TypeError || /^MCP HTTP /.test(String(error?.message));
}

async function main() {
  let config, cookie;
  try {
    config = await loadConfig();
    cookie = await resolveCookie(config);
  } catch (error) {
    console.error(`connectivity: cannot resolve MCP config/cookie: ${error.message}`);
    return 2;
  }

  let served;
  try {
    served = ((await rpc(config, cookie, "tools/list"))?.tools || []).map((tool) => tool.name);
  } catch (error) {
    console.error(`connectivity: tools/list against ${config.mcpUrl} failed: ${error.message}`);
    return 2;
  }

  const missing = diffTools(served, REQUIRED_SEER_TOOLS);
  if (missing.length) {
    console.error(`drift: ${missing.length} required tool(s) missing from ${config.mcpUrl}:`);
    for (const name of missing) console.error(`  - ${name}`);
    console.error("run mcp/import-mcp-tools + mcp/import-mcp-prompts for desk %seer, then re-check");
    return 1;
  }

  try {
    const result = await rpc(config, cookie, "tools/call", { name: "seer/list-stacks", arguments: {} });
    if (result?.isError) {
      const message = result.content?.find((part) => part.type === "text")?.text || "tool reported an error";
      throw new Error(message);
    }
  } catch (error) {
    const kind = isConnectivityError(error) ? "connectivity" : "drift";
    console.error(`${kind}: seer/list-stacks roundtrip failed: ${error.message}`);
    return kind === "connectivity" ? 2 : 1;
  }

  console.log(`PASS: ${config.mcpUrl} serves all ${REQUIRED_SEER_TOOLS.length} required seer tools; seer/list-stacks roundtrip ok`);
  return 0;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  process.exitCode = await main();
}
