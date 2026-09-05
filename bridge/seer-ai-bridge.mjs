#!/usr/bin/env node

import { access, readFile, stat } from "node:fs/promises";
import { constants as fsConstants } from "node:fs";
import { homedir, hostname } from "node:os";
import { join } from "node:path";
import { spawn } from "node:child_process";
import { createHash, createHmac, randomUUID } from "node:crypto";
import { lookup } from "node:dns/promises";
import { isIP } from "node:net";
import { request as httpRequest } from "node:http";
import { request as httpsRequest } from "node:https";
import { inspectProvider, providerEnvironment, runBoundedProcess, runProvider } from "./seer-provider.mjs";
import { Readable } from "node:stream";

const DEFAULT_CONFIG = join(homedir(), ".config", "seer", "ai-bridge.json");
const args = new Set(process.argv.slice(2));
const once = args.has("--once");
const configFlag = process.argv.indexOf("--config");
const configPath = configFlag >= 0 ? process.argv[configFlag + 1] : (process.env.SEER_BRIDGE_CONFIG || DEFAULT_CONFIG);

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
let rpcId = 1_000;
const activeLogins = new Map();
const activeSessions = new Set();
let shutdownRequested = false;
let shutdownHandlersInstalled = false;


export function codexProfilesFromCatalog(payload) {
  const models = Array.isArray(payload?.models) ? payload.models : [];
  const families = new Map();
  for (const entry of models) {
    const match = String(entry?.slug || "").match(/^gpt-(\d+)\.(\d+)-(luna|terra|sol)$/);
    if (!match || entry.visibility !== "list") continue;
    const version = `${match[1]}.${match[2]}`;
    if (!families.has(version)) families.set(version, new Map());
    families.get(version).set(match[3], entry);
  }
  const latest = [...families.keys()]
    .filter((version) => families.get(version).size === 3)
    .sort((a, b) => {
      const [aMajor, aMinor] = a.split(".").map(Number);
      const [bMajor, bMinor] = b.split(".").map(Number);
      return bMajor - aMajor || bMinor - aMinor;
    })[0];
  const makeProfile = (entry, role) => ({
    id: `${role}-codex-${entry.slug.replace(/[^a-z0-9]+/g, "-")}`,
    provider: "codex",
    role,
    selector: `openai-codex/${entry.slug}`,
    model: entry.slug,
    label: entry.display_name || entry.slug,
    description: entry.description || "Uses the signed-in Codex account.",
  });
  if (!latest) return [];
  const roles = { luna: "smol", terra: "default", sol: "slow" };
  return ["luna", "terra", "sol"].map((tier) => (
    makeProfile(families.get(latest).get(tier), roles[tier])
  ));
}

export function claudeProfiles() {
  return [
    {
      id: "smol-claude-haiku-4-5",
      provider: "claude",
      role: "smol",
      selector: "anthropic/claude-haiku-4-5",
      model: "claude-haiku-4-5",
      label: "Claude Haiku 4.5",
      description: "Use for simple questions and small card edits.",
    },
    {
      id: "default-claude-sonnet-5",
      provider: "claude",
      role: "default",
      selector: "anthropic/claude-sonnet-5",
      model: "claude-sonnet-5",
      label: "Claude Sonnet 5",
      description: "Use for routine questions and card edits. Supports a one-million-token context.",
    },
    {
      id: "slow-claude-opus-5",
      provider: "claude",
      role: "slow",
      selector: "anthropic/claude-opus-5",
      model: "claude-opus-5",
      label: "Claude Opus 5",
      description: "Use for difficult explanations and large card edits.",
    },
    {
      id: "slow-claude-fable-5",
      provider: "claude",
      role: "slow",
      selector: "anthropic/claude-fable-5",
      model: "claude-fable-5",
      label: "Claude Fable 5",
      description: "Use for long tasks. This model can consume account credits.",
    },
  ];
}

export function extractMcpCookie(toml, wantedUrl, env = process.env) {
  const sections = toml.split(/^\s*\[(?=mcp_servers\.)/m).slice(1);
  for (const raw of sections) {
    const body = raw.split(/^\s*\[/m)[0];
    const url = body.match(/^\s*url\s*=\s*"([^"]+)"/m)?.[1];
    if (wantedUrl && url !== wantedUrl) continue;

    const direct = body.match(/^\s*http_headers\s*=.*["']Cookie["']\s*=\s*"([^"]+)"/m)?.[1];
    if (direct) return direct;

    const envName = body.match(/^\s*env_http_headers\s*=.*["']Cookie["']\s*=\s*"([^"]+)"/m)?.[1];
    if (envName && env[envName]) return env[envName];
  }
  return null;
}

async function readLocalText(path, maxBytes) {
  if ((await stat(path)).size > maxBytes) throw bridgeError("LOCAL_FILE_LIMIT");
  const data = await readFile(path);
  if (data.length > maxBytes) throw bridgeError("LOCAL_FILE_LIMIT");
  return new TextDecoder("utf-8", { fatal: true }).decode(data);
}

async function loadConfig() {
  let config = {};
  try {
    config = JSON.parse(await readLocalText(configPath, 65_536));
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
  config.mcpUrl ||= "http://127.0.0.1:8080/mcp";
  config.pollIntervalMs ||= 2_000;
  config.catalogRefreshMs ||= 300_000;
  config.timeoutMs ||= 180_000;
  config.mcpTimeoutMs ||= 30_000;
  config.contextMaxBytes ||= 131_072;
  config.contextFetchTimeoutMs ||= 20_000;
  config.workerId ||= `${hostname()}-${process.pid}`;
  config.codex ||= {};
  config.claude ||= {};
  return config;
}

async function executable(path) {
  if (!path) return false;
  try {
    await access(path, fsConstants.X_OK);
    return true;
  } catch {
    return false;
  }
}

async function commandFromPath(name) {
  for (const dir of (process.env.PATH || "").split(":")) {
    const candidate = join(dir, name);
    if (await executable(candidate)) return candidate;
  }
  return null;
}


async function resolveProviderCommands(config) {
  const codex = config.codex.enabled === false ? null : (
    process.env.CODEX_BIN || config.codex.command || await commandFromPath("codex")
  );
  const claude = config.claude.enabled === false ? null : (
    process.env.CLAUDE_BIN || config.claude.command || await commandFromPath("claude")
  );
  return {
    codex: await executable(codex) ? codex : null,
    claude: await executable(claude) ? claude : null,
  };
}

async function resolveProviders(config, commands) {
  commands ||= await resolveProviderCommands(config);
  const codex = commands.codex && await codexLoggedIn(commands.codex, config)
    ? commands.codex
    : null;
  const claude = commands.claude && await claudeLoggedIn(commands.claude, config)
    ? commands.claude
    : null;
  return { codex, claude };
}

async function codexLoggedIn(command, config) {
  const env = providerEnvironment();
  try {
    const { stdout, stderr } = await runBoundedProcess(command, ["login", "status"], {
      env,
      timeoutMs: Math.min(config.timeoutMs || 180_000, 15_000),
    });
    const status = `${stdout}\n${stderr}`;
    return /logged in using/i.test(status) && !/not logged in/i.test(status);
  } catch {
    return false;
  }
}

async function claudeLoggedIn(command, config) {
  const env = providerEnvironment();
  try {
    const { stdout } = await runBoundedProcess(command, ["auth", "status"], {
      env,
      timeoutMs: Math.min(config.timeoutMs || 180_000, 15_000),
    });
    return JSON.parse(stdout)?.loggedIn === true;
  } catch {
    return false;
  }
}

async function resolveCookie(config) {
  if (process.env.SEER_MCP_COOKIE) return process.env.SEER_MCP_COOKIE;
  if (config.cookieEnv && process.env[config.cookieEnv]) return process.env[config.cookieEnv];
  if (config.cookie) return config.cookie;
  const codexConfig = config.codexConfig || join(homedir(), ".codex", "config.toml");
  const toml = await readLocalText(codexConfig, 262_144);
  const cookie = extractMcpCookie(toml, config.mcpUrl);
  if (!cookie) throw bridgeError("MCP_COOKIE_UNAVAILABLE");
  return cookie;
}

function parseMcpResponse(text, requireJson) {
  const payloads = text
    .split(/\r?\n/)
    .filter((line) => line.startsWith("data:"))
    .map((line) => line.slice(5).trim())
    .filter(Boolean);
  const raw = payloads.at(-1) || text.trim();
  const rpc = JSON.parse(raw);
  if (rpc.error) throw bridgeError("MCP_REJECTED");
  const result = rpc.result;
  if (result?.isError) {
    throw bridgeError("MCP_REJECTED");
  }
  if (result?.structuredContent) return result.structuredContent;
  const embedded = result?.content?.find((part) => part.type === "text")?.text;
  if (embedded === undefined) return result;
  return requireJson ? JSON.parse(embedded) : embedded;
}

export const SEER_SCHEMA_VERSION = 2;

export const READ_CAPS = Object.freeze({
  pageRows: 20, pageBytes: 32_768, detailBytes: 65_536,
  activeLogins: 4, historyRows: 6, historyBytes: 32_768,
  contextSources: 8, contextBytes: 64_000, sourceBytes: 24_000,
  libraryStacks: 6, libraryCards: 24, cardsPerStack: 8, libraryBytes: 98_304,
  libraryMetadataRows: 100, libraryMetadataBytes: 32_768,
});
const READ_COLLECTIONS = {
  "seer/list-context-sources": ["contexts", "context_id"],
  "seer/list-card-questions": ["questions", "question_id"],
  "seer/list-change-requests": ["changes", "change_id"],
  "seer/list-login-requests": ["logins", "login_id"],
};
const READ_STATUSES = new Set(["ok", "unchanged", "snapshot-expired", "not-found", "invalid-query", "limit-exceeded"]);
const jsonBytes = (value) => Buffer.byteLength(JSON.stringify(value), "utf8");

export async function readBoundedPage(config, cookie, tool, scope = {}, dependencies = {}) {
  const call = dependencies.callTool || callTool;
  const query = { projection: "metadata", limit: READ_CAPS.pageRows, max_bytes: READ_CAPS.pageBytes, ...scope };
  if (!["metadata", "detail"].includes(query.projection)
    || !Number.isInteger(query.limit) || query.limit < 1 || query.limit > 100
    || !Number.isInteger(query.max_bytes) || query.max_bytes < 1024 || query.max_bytes > 262_144
    || ["cursor", "since"].some((key) => query[key] !== undefined && (typeof query[key] !== "string" || !query[key]))
    || (query.cursor !== undefined && query.since !== undefined)) {
    throw new Error(`Invalid bounded query for ${tool}`);
  }
  // %mcp-server parses JSON numbers as @ud, which rejects undotted thousands.
  const page = await call(config, cookie, tool, {
    ...query, limit: String(query.limit), max_bytes: String(query.max_bytes),
  });
  if (page?.schema_version !== SEER_SCHEMA_VERSION || !READ_STATUSES.has(page?.status)
    || typeof page.complete !== "boolean" || !Array.isArray(page.omissions)
    || typeof page.watermark !== "string" || !page.watermark
    || page.state_revision == null || typeof page.observed_at !== "string" || !page.observed_at || page.idempotency_epoch == null
    || page.projection !== query.projection
    || page.limits?.limit !== query.limit || page.limits?.max_bytes !== query.max_bytes
    || !(page.next_cursor === null || (typeof page.next_cursor === "string" && page.next_cursor))
    || (page.complete && page.next_cursor !== null)
    || jsonBytes(page) > query.max_bytes) {
    throw new Error(`Invalid bounded response from ${tool}`);
  }
  const [collection, idKey] = READ_COLLECTIONS[tool]
    || (tool === "seer/state-context" ? (query.stack_id ? ["cards", "card_id"] : ["stacks", "stack_id"]) : []);
  if (collection) {
    const rows = page[collection];
    if (tool === "seer/state-context" && query.projection === "metadata" && page.status === "ok") {
      requireLibraryMetadata(rows, idKey);
    }
    if ((page.status === "ok" && !Array.isArray(rows))
      || (rows !== undefined && (!Array.isArray(rows) || rows.length > query.limit
        || rows.some((row) => !row || typeof row[idKey] !== "string" || !row[idKey]
          || (READ_COLLECTIONS[tool] && (typeof row.status !== "string" || (query.status && row.status !== query.status))))
        || new Set(rows.map((row) => row[idKey])).size !== rows.length))
      || (page.status !== "ok" && rows?.length)
      || (query.id && rows?.some((row) => row[idKey] !== query.id))) {
      throw new Error(`Invalid ${collection} page from ${tool}`);
    }
  }
  if ((page.status === "unchanged" && (!query.since || !page.complete || page.omissions.length))
    || (page.status === "ok" && !page.complete && page.next_cursor === null && !page.omissions.length)
    || (query.cursor && page.next_cursor === query.cursor)) {
    throw new Error(`Invalid bounded continuation from ${tool}`);
  }
  if (page.status === "invalid-query") throw bridgeError("INVALID_BOUNDED_QUERY");
  return page;
}

export async function readBoundedDetail(config, cookie, tool, id, scope = {}, dependencies = {}) {
  const page = await readBoundedPage(config, cookie, tool, {
    ...scope, id, projection: "detail", limit: 1, max_bytes: scope.max_bytes ?? READ_CAPS.detailBytes,
  }, dependencies);
  const [collection] = READ_COLLECTIONS[tool]
    || (tool === "seer/state-context" ? (scope.stack_id ? ["cards"] : ["stacks"]) : []);
  if (page.status === "ok" && page.complete && page[collection]?.length !== 1) {
    throw bridgeError("DETAIL_UNAVAILABLE");
  }
  const row = page.status === "ok" && page.complete && page[collection]?.length === 1
    ? page[collection][0] : null;
  return { row, page };
}

function readOmissions(page, scope) {
  const omissions = [...page.omissions];
  if (!page.complete || page.status !== "ok") {
    omissions.push({ scope, reason: page.status === "ok" ? "page-incomplete" : page.status, next_cursor: page.next_cursor });
  }
  return omissions;
}

export function createReadScan() {
  return { pending: [], cursor: null, watermark: null, complete: false, done: false };
}

// Retain one metadata page, not the queue. Mutations can expire the continuation,
// but the IDs already discovered remain usable through independent exact reads.
export async function nextReadJob(config, cookie, tool, scope, scan, dependencies = {}) {
  if (scan.done) return null;
  if (!scan.pending.length) {
    const continuation = scan.cursor ? { cursor: scan.cursor } : scan.watermark ? { since: scan.watermark } : {};
    const page = await readBoundedPage(config, cookie, tool, { ...scope, ...continuation }, dependencies);
    if (page.status === "snapshot-expired") {
      scan.cursor = null;
      scan.watermark = null;
      scan.complete = false;
      (dependencies.onSnapshotExpired || ((name) => console.warn(`[seer-ai] ${name} snapshot expired; bounded refresh deferred to next tick`)))(tool);
      return null;
    }
    if (page.status === "unchanged") return null;
    if (page.status !== "ok" || (!page.complete && !page.next_cursor)) {
      throw bridgeError("INCOMPLETE_QUEUE");
    }
    if (page.omissions.length) console.warn("[seer-ai] queue metadata contains omissions");
    const [collection] = READ_COLLECTIONS[tool];
    scan.pending = page[collection];
    scan.cursor = page.next_cursor;
    scan.watermark = page.complete ? page.watermark : null;
    scan.complete = page.complete;
  }
  return scan.pending.shift() || null;
}

function requireDetailFields(row, fields, label) {
  if (fields.some((field) => typeof row[field] !== "string")) {
    throw new Error(`Incomplete ${label} detail`);
  }
}

function requireLibraryMetadata(rows, idKey) {
  const kind = idKey === "stack_id" ? "stack" : "card";
  const fail = (field) => {
    throw Object.assign(new Error(`Incomplete ${kind} metadata read: invalid or omitted ${field}`), {
      code: "INCOMPLETE_LIBRARY_METADATA",
    });
  };
  if (!Array.isArray(rows)) fail(`${kind} rows`);
  for (const row of rows) {
    if (typeof row?.[idKey] !== "string" || !/^[a-z][a-z0-9-]{0,127}$/u.test(row[idKey])) fail(idKey);
    if (typeof row.title !== "string" || row.title_omitted === true) fail("title");
  }
}

function explicitLibraryStacks(prompt) {
  const targets = [];
  const seen = new Set();
  // IDs are slugs, not arbitrary quoted prose. URL owners remain part of the
  // exact read scope so a linked remote stack cannot resolve to a local one.
  const references = /\/apps\/seer\/stack\/(?<owner>~[a-z]+(?:-[a-z]+)*)\/(?<urlId>[a-z][a-z0-9-]{0,127})(?=$|[\s/?#"'`<>).,;!])|\bstack(?:_id|[- ]id| identifier)?["'`]?\s*(?:[:=]\s*|\s+)["'`]?(?<named>[a-z][a-z0-9-]{0,127})(?=$|[\s"'`<>).,;!?])|(?<quote>["'`])(?<quoted>[a-z][a-z0-9-]{0,127})\k<quote>/giu;
  for (const match of prompt.matchAll(references)) {
    const { owner, urlId, named, quoted } = match.groups;
    const id = urlId || named || quoted;
    if (!/^[a-z][a-z0-9-]{0,127}$/u.test(id)) continue;
    const key = `${owner || ""}/${id}`;
    if (seen.has(key)) continue;
    if (targets.length === READ_CAPS.libraryStacks) return { targets, capped: true };
    seen.add(key);
    targets.push({ id, ...(owner ? { owner } : {}) });
  }
  return { targets, capped: false };
}


export async function loadLibraryContext(config, cookie, job, dependencies = {}) {
  const context = { stacks: [], complete: false, omissions: [] };
  let bytes = 0;
  let cards = 0;
  const candidates = new Map();
  const key = (row) => `${row.ref?.owner || ""}/${row.stack_id}`;
  const explicit = explicitLibraryStacks(job.prompt);
  if (explicit.capped) context.omissions.push({ reason: "library-explicit-stack-cap" });
  // Exact metadata reads precede discovery and body expansion. At most six
  // targets cost at most 24 KiB, independent of the library's page count.
  for (const target of explicit.targets) {
    const exact = await readBoundedPage(config, cookie, "seer/state-context", {
      ...target, limit: 1, max_bytes: 4096,
    }, dependencies);
    bytes += jsonBytes(exact);
    context.omissions.push(...readOmissions(exact, { stack_id: target.id, ...(target.owner ? { owner: target.owner } : {}) }));
    if (exact.status !== "ok") continue;
    if (exact.complete && exact.stacks.length !== 1) {
      throw Object.assign(new Error("Incomplete stack metadata read: exact stack omitted"), {
        code: "INCOMPLETE_LIBRARY_METADATA",
      });
    }
    for (const row of exact.stacks) candidates.set(key(row), { row, owner: target.owner, epoch: exact.idempotency_epoch });
  }
  const page = await readBoundedPage(config, cookie, "seer/state-context", {
    limit: READ_CAPS.libraryMetadataRows,
    max_bytes: Math.min(READ_CAPS.libraryMetadataBytes, READ_CAPS.libraryBytes - bytes),
  }, dependencies);
  bytes += jsonBytes(page);
  context.omissions.push(...readOmissions(page, "stacks"));
  // Search only the bounded discovery page; its continuation/omissions remain
  // visible even when every explicitly requested stack was resolved.
  const instruction = job.prompt.toLowerCase();
  const words = new Set(instruction.split(/[^a-z0-9-]+/u));
  const relevance = (row, id) => Number(words.has(row[id].toLowerCase())) * 2
    + Number(row.title.toLowerCase().split(/[^a-z0-9-]+/u).some((word) => word.length > 3 && words.has(word)));
  const discovered = page.status === "ok"
    ? [...page.stacks].sort((a, b) => relevance(b, "stack_id") - relevance(a, "stack_id")) : [];
  for (const row of discovered) {
    if (!candidates.has(key(row))) candidates.set(key(row), { row, epoch: page.idempotency_epoch });
  }
  const stacks = [...candidates.values()];
  for (const { row: stack, owner, epoch } of stacks.slice(0, READ_CAPS.libraryStacks)) {
    const scope = { stack_id: stack.stack_id, ...(owner ? { owner } : {}) };
    const selected = { stack_id: stack.stack_id, title: stack.title, ref: stack.ref, cards: [], cards_complete: false };
    context.stacks.push(selected);
    if (cards >= READ_CAPS.libraryCards || READ_CAPS.libraryBytes - bytes < 1024) {
      context.omissions.push({ stack_id: stack.stack_id, reason: "library-cap" });
      continue;
    }
    const cardPage = await readBoundedPage(config, cookie, "seer/state-context", {
      ...scope, limit: READ_CAPS.libraryMetadataRows,
      max_bytes: Math.min(READ_CAPS.libraryMetadataBytes, READ_CAPS.libraryBytes - bytes),
    }, dependencies);
    bytes += jsonBytes(cardPage);
    const omissions = readOmissions(cardPage, { stack_id: stack.stack_id });
    if (cardPage.idempotency_epoch !== epoch) {
      omissions.push({ stack_id: stack.stack_id, reason: "snapshot-changed" });
    }
    if (cardPage.status === "ok") {
      const candidates = [...cardPage.cards].sort((a, b) => relevance(b, "card_id") - relevance(a, "card_id"));
      const selectedCards = candidates.slice(0, Math.min(READ_CAPS.cardsPerStack, READ_CAPS.libraryCards - cards));
      if (selectedCards.length < candidates.length) {
        omissions.push({ stack_id: stack.stack_id, reason: "library-card-cap" });
      }
      for (const card of selectedCards) {
        const maxBytes = Math.min(16_384, READ_CAPS.libraryBytes - bytes);
        if (maxBytes < 1024) {
          omissions.push({ stack_id: stack.stack_id, reason: "library-byte-cap" });
          break;
        }
        cards += 1;
        const detail = await readBoundedDetail(config, cookie, "seer/state-context", card.card_id, {
          ...scope, max_bytes: maxBytes,
        }, dependencies);
        bytes += jsonBytes(detail.page);
        omissions.push(...readOmissions(detail.page, { stack_id: stack.stack_id, card_id: card.card_id }));
        if (detail.page.idempotency_epoch !== cardPage.idempotency_epoch
          || (detail.row && (!card.ref || !detail.row.ref
            || ["kind", "owner", "scope", "id", "incarnation", "content_revision"].some((key) => card.ref[key] !== detail.row.ref[key])))) {
          omissions.push({ stack_id: stack.stack_id, card_id: card.card_id, reason: "snapshot-changed" });
        }
        if (!detail.row) continue;
        requireDetailFields(detail.row, ["title", "front", "back"], "card");
        selected.cards.push(detail.row);
      }
      const loaded = new Set(selected.cards.map((card) => card.card_id));
      selected.card_index = cardPage.cards.map((card) => ({
        card_id: card.card_id, title: card.title, ref: card.ref, content_loaded: loaded.has(card.card_id),
      }));
    }
    selected.cards_complete = cardPage.status === "ok" && cardPage.complete
      && omissions.length === 0 && selected.cards.length === cardPage.cards.length;
    context.omissions.push(...omissions);
  }
  if (stacks.length > READ_CAPS.libraryStacks) context.omissions.push({ reason: "library-stack-cap" });
  context.complete = page.status === "ok" && page.complete && context.omissions.length === 0;
  return context;
}

export function libraryObservations(context) {
  const observations = [];
  for (const stack of context.stacks) {
    observations.push(observedPrecondition(stack.ref, true));
    for (const card of stack.cards) observations.push(observedPrecondition(card.ref, true));
  }
  if (observations.length > 128) throw bridgeError("OBSERVATION_LIMIT");
  return observations;
}

export function observedPrecondition(ref, content = false) {
  if (!ref || !["stack", "card"].includes(ref.kind)) throw bridgeError("INVALID_OBSERVATION");
  const { kind, owner, scope, id, incarnation, content_revision, review_revision } = ref;
  const condition = { ref: { kind, owner, scope, id },
    version: { incarnation, content_revision, review_revision, present: true }, content, review: false };
  flattenPreconditions([condition]);
  return condition;
}

const WORKER_ACTIONS = new Map([
  ["claim-card-question", "question_id"], ["answer-card-question", "question_id"],
  ["apply-card-edit", "question_id"], ["fail-card-question", "question_id"],
  ["claim-change", "change_id"], ["prepare-change-packet", "change_id"],
  ["finish-change", "change_id"], ["fail-change", "change_id"],
  ["claim-context-source", "context_id"], ["finish-context-source", "context_id"],
  ["fail-context-source", "context_id"], ["claim-login", "login_id"],
  ["post-login-challenge", "login_id"], ["consume-login-code", "login_id"],
  ["finish-login", "login_id"], ["fail-login", "login_id"],
  ["replace-assistant-models", null], ["checkpoint-work", "work_id"],
  ["heartbeat-work", "work_id"], ["recover-work", "work_id"],
]);
const ARRAY_FIELDS = ["profiles", "observations", "selections", "operations", "citations", "preconditions"];
const READ_TOOLS = new Set([
  "agent-context", "get-operation-result", "get-context-packet", "get-evidence-snapshot",
  "list-card-questions", "list-change-requests", "list-context-sources",
  "list-login-requests", "state-context", "lookup-learning",
]);
const RECEIPT_STATUSES = new Set(["ok", "blocked", "conflict", "invalid", "unauthorized",
  "budget-exhausted", "outcome-unknown", "replay-expired"]);

function bridgeError(code, metadata = {}) {
  return Object.assign(new Error(code), { code, ...metadata });
}

function decimal(value) {
  const text = String(value);
  if (!/^(?:0|[1-9][0-9]*)$/.test(text) || !Number.isSafeInteger(Number(text))) {
    throw bridgeError("INVALID_DECIMAL");
  }
  return text;
}

function canonicalHex(value) {
  if (typeof value !== "string" || !/^0x[0-9a-f]+(?:\.[0-9a-f]{4})*$/.test(value)
    || formatHoonHex(value.slice(2).replaceAll(".", "")) !== value) throw bridgeError("INVALID_HEX");
  return value;
}

function checkedArray(value, max) {
  if (!Array.isArray(value) || value.length > max) throw bridgeError("INVALID_LIST");
  return value;
}

const counted = (rows, flatten) => [decimal(rows.length), ...rows.flatMap(flatten)];
const textField = (value) => {
  if (typeof value !== "string" || value.includes("\0")) throw bridgeError("INVALID_TEXT");
  return value;
};
const booleanField = (value) => {
  if (typeof value !== "boolean") throw bridgeError("INVALID_BOOLEAN");
  return String(value);
};
const refFields = (ref) => ["kind", "owner", "scope", "id"].map((field) => textField(ref?.[field]));
const OPERATION_FIELDS = ["kind", "stack_id", "card_id", "title", "front", "back",
  "original_title", "original_front", "original_back"];

export function flattenPreconditions(rows) {
  return counted(checkedArray(rows, 128), ({ ref, version, content, review }) => [
    ...refFields(ref), version === null ? "none" : "some",
    ...(version === null ? [] : [decimal(version.incarnation), decimal(version.content_revision),
      decimal(version.review_revision), booleanField(version.present)]),
    booleanField(content), booleanField(review),
  ]);
}

export function workerActionFields(action, values) {
  const citations = () => counted(checkedArray(values.citations, 32), (row) =>
    [canonicalHex(row.snapshot_ref), decimal(row.start), decimal(row.end), textField(row.quote)]);
  if (action === "consume-login-code") return [decimal(values.content_revision)];
  if (action.startsWith("claim-") || action === "finish-login") return [];
  if (action.startsWith("fail-")) return [textField(values.error)];
  switch (action) {
    case "answer-card-question": return [textField(values.answer), ...citations()];
    case "apply-card-edit": return [...["title", "front", "back", "summary"].map((key) => textField(values[key])), ...citations()];
    case "finish-context-source": return ["label", "content", "final_locator"].map((key) => textField(values[key]));
    case "post-login-challenge": return ["auth_url", "user_code"].map((key) => textField(values[key]));
    case "finish-change": return [textField(values.summary), textField(values.artifact),
      ...counted(checkedArray(values.operations, 64), (row) => OPERATION_FIELDS.map((key) => textField(row[key]))), ...citations()];
    case "prepare-change-packet": return [
      ...flattenPreconditions(values.observations),
      textField(values.read_report),
      ...counted(checkedArray(values.selections, 32), (row) => [textField(row.source_id),
        decimal(row.start), row.end === null ? "" : decimal(row.end), booleanField(row.include), booleanField(row.mandatory)]),
      decimal(values.max_bytes), decimal(values.excerpt_bytes),
    ];
    case "replace-assistant-models": return counted(checkedArray(values.profiles, 128),
      (row) => ["model_id", "provider", "role", "selector", "model", "label", "description"].map((key) => textField(row[key])));
    case "checkpoint-work":
    case "heartbeat-work":
    case "recover-work": return [...["work_kind", "owner", "work_scope", "work_id"].map((key) => textField(values[key])),
      ...(action === "checkpoint-work" ? [textField(values.stage)] : [])];
    default: throw bridgeError("UNKNOWN_WORKER_ACTION");
  }
}

async function rpc(config, cookie, method, params) {
  const body = JSON.stringify({ jsonrpc: "2.0", id: rpcId++, method, params });
  if (Buffer.byteLength(body) > 524_288) throw bridgeError("RPC_INPUT_LIMIT");
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), Math.min(config.mcpTimeoutMs || 30_000, 30_000));
  try {
    const response = await fetch(config.mcpUrl, {
      signal: config.signal ? AbortSignal.any([controller.signal, config.signal]) : controller.signal,
      redirect: "error", method: "POST",
      headers: { Accept: "application/json, text/event-stream", "Content-Type": "application/json", Cookie: cookie }, body,
    });
    const text = await limitedResponseText(response, method === "tools/list" ? 1_048_576 : 524_288);
    if (!response.ok) throw bridgeError("MCP_HTTP_FAILED");
    return parseMcpResponse(text, method === "tools/call" && params?.name?.startsWith("seer/"));
  } catch (error) {
    throw bridgeError(error?.code === "MCP_REJECTED" ? "MCP_REJECTED" : "RPC_FAILED");
  } finally { clearTimeout(timer); }
}

function checkedReceipt(result, action, values) {
  const receipt = result?.receipt || result;
  if (receipt?.schema_version !== 2 || receipt.idempotency_epoch !== values.idempotency_epoch
    || receipt.operation_id !== values.operation_id || !RECEIPT_STATUSES.has(receipt.status)
    || (receipt.action !== action && receipt.status !== "outcome-unknown")
    || !["none", "staged", "committed", "unknown"].includes(receipt.effect)) {
    throw bridgeError("INVALID_RECEIPT", { ambiguous: true });
  }
  if (receipt.status !== "ok") throw bridgeError("MUTATION_STOPPED", { receipt, ambiguous: receipt.status === "outcome-unknown" });
  canonicalHex(receipt.payload_digest);
  return result;
}

export function seerToolClass(name) {
  if (!name.startsWith("seer/")) return null;
  const action = name.slice(5);
  if (READ_TOOLS.has(action)) return "read";
  if (WORKER_ACTIONS.has(action)) return "worker";
  return action === "issue-bridge-nonce" ? "planner" : null;
}

export async function callTool(config, cookie, name, toolArgs = {}) {
  if (jsonBytes(toolArgs) > 262_144) throw bridgeError("RPC_INPUT_LIMIT");
  if (!name.startsWith("seer/")) return rpc(config, cookie, "tools/call", { name, arguments: toolArgs });
  const action = name.slice(5);
  const role = seerToolClass(name);
  if (role === "read") return rpc(config, cookie, "tools/call", {
    name, arguments: { ...toolArgs, schema_version: 2 },
  });
  if (!role) {
    throw bridgeError("UNSUPPORTED_MUTATION");
  }
  if (!config.idempotencyEpoch) await ensureBridgeProtocol(config, cookie);
  const values = { ...toolArgs, schema_version: 2,
    idempotency_epoch: toolArgs.idempotency_epoch || config.idempotencyEpoch,
    operation_id: toolArgs.operation_id || randomUUID() };
  if (toolArgs.operation_id) {
    const durable = await callTool(config, cookie, "seer/get-operation-result", {
      idempotency_epoch: values.idempotency_epoch, operation_id: values.operation_id,
    });
    checkedReceipt(durable, action, values);
    if (!toolArgs.payload_digest || canonicalHex(toolArgs.payload_digest) !== (durable.receipt || durable).payload_digest) {
      throw bridgeError("RECONCILIATION_REQUIRED", { ambiguous: true });
    }
    return durable;
  }
  if (role === "worker") {
    values.worker_id = config.workerId;
    values.attempt = decimal(values.attempt);
    values.lease = canonicalHex(values.lease);
    const fields = workerActionFields(action, values);
    const nonce = formatHoonHex(randomUUID().replaceAll("-", ""));
    await callTool(config, cookie, "seer/issue-bridge-nonce", { nonce });
    values.proof_nonce = nonce;
    const idKey = WORKER_ACTIONS.get(action);
    values.proof = createBridgeProof(requireBridgeSecret(config), action,
      idKey === null ? "catalog" : textField(values[idKey]), config.workerId, nonce,
      ["2", values.idempotency_epoch, values.operation_id, values.attempt, values.lease, ...fields]);
  }
  for (const key of ARRAY_FIELDS) if (values[key] !== undefined) values[key] = JSON.stringify(values[key]);
  let result;
  try {
    result = await rpc(config, cookie, "tools/call", { name, arguments: values });
  } catch {
    // A lost acknowledgement is not permission to repeat any mutation.
    try {
      result = await callTool(config, cookie, "seer/get-operation-result", {
        idempotency_epoch: values.idempotency_epoch, operation_id: values.operation_id,
      });
    } catch {
      throw bridgeError("OUTCOME_UNKNOWN", { ambiguous: true,
        operation_id: values.operation_id, idempotency_epoch: values.idempotency_epoch });
    }
  }
  return checkedReceipt(result, action, values);
}

export const REQUIRED_SEER_TOOLS = [
  ...[...READ_TOOLS, ...WORKER_ACTIONS.keys(), "issue-bridge-nonce"].map((name) => `seer/${name}`),
];

export async function listServedTools(config, cookie) {
  const result = await rpc(config, cookie, "tools/list");
  if (!Array.isArray(result?.tools)) throw bridgeError("INVALID_TOOL_CATALOG");
  return result.tools;
}

export async function reimportDefinitions(config, cookie, dependencies = {}) {
  const call = dependencies.callTool || callTool;
  // Import the exporting agent, not every agent on the desk (%seer-cli has no MCP API).
  for (const mark of ["import-tools", "import-prompts"]) {
    await call(config, cookie, "mcp/poke-our-agent", { agent: "mcp-server", mark, data: "'seer'" });
  }
}

export async function ensureToolCoverage(config, cookie, dependencies = {}) {
  const listTools = dependencies.listServedTools || listServedTools;
  const served = (await listTools(config, cookie)).map((tool) => tool.name);
  const missing = REQUIRED_SEER_TOOLS.filter((name) => !served.includes(name));
  if (!missing.length) return [];
  console.log(`[seer-ai] importing Seer MCP definitions: ${missing.length} tools missing (${missing.slice(0, 3).join(", ")}${missing.length > 3 ? ", ..." : ""})`);
  await reimportDefinitions(config, cookie, dependencies);
  const after = (await listTools(config, cookie)).map((tool) => tool.name);
  const still = REQUIRED_SEER_TOOLS.filter((name) => !after.includes(name));
  if (still.length) {
    throw bridgeError("MCP_TOOLS_UNAVAILABLE");
  }
  return missing;
}

export function validateBridgeProtocol(context) {
  if (context.status !== "ok" || context?.schema_version !== SEER_SCHEMA_VERSION
    || context?.capabilities_revision !== SEER_SCHEMA_VERSION
    || context?.worker_authority !== "paired-proof-seer-bridge-v2"
    || context?.authority !== "owner-trusted"
    || context?.scoped_delegation !== false
    || context.mutation_receipts !== true || context.leased_execution !== true
    || typeof context.idempotency_epoch !== "string" || !context.idempotency_epoch.startsWith("~")) {
    throw bridgeError("BRIDGE_PROTOCOL_UNSUPPORTED");
  }
  return context;
}

export async function ensureBridgeProtocol(config, cookie, dependencies = {}) {
  requireBridgeSecret(config);
  const context = validateBridgeProtocol(await readBoundedPage(
    config, cookie, "seer/agent-context", {}, dependencies,
  ));
  config.idempotencyEpoch = context.idempotency_epoch;
  return context;
}


async function discoverModelProfiles(providers, config) {
  const profiles = [];
  if (providers.codex) {
    const env = providerEnvironment();
    const { stdout } = await runBoundedProcess(providers.codex, ["debug", "models"], {
      env,
      timeoutMs: Math.min(config.timeoutMs || 180_000, 45_000),
    });
    const codexProfiles = codexProfilesFromCatalog(JSON.parse(stdout));
    if (codexProfiles.length !== 3) {
      throw new Error("Codex model catalog has no complete luna/terra/sol tier family; update the Codex CLI");
    }
    profiles.push(...codexProfiles);
  }
  if (providers.claude) profiles.push(...claudeProfiles());
  return profiles;
}

export async function publishModelProfiles(config, cookie, profiles, dependencies = {}) {
  const call = dependencies.callTool || callTool;
  return call(config, cookie, "seer/replace-assistant-models", {
    worker_id: config.workerId, attempt: "0", lease: "0x0",
    profiles: profiles.map(({ id, ...profile }) => ({ model_id: id, ...profile })),
  });
}


function decodeHtmlEntities(text) {
  const named = new Map([
    ["amp", "&"], ["lt", "<"], ["gt", ">"], ["quot", "\""],
    ["apos", "'"], ["nbsp", " "], ["ndash", "–"], ["mdash", "—"],
  ]);
  return text.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (match, entity) => {
    if (entity[0] !== "#") return named.get(entity.toLowerCase()) ?? match;
    const base = entity[1]?.toLowerCase() === "x" ? 16 : 10;
    const raw = base === 16 ? entity.slice(2) : entity.slice(1);
    const code = Number.parseInt(raw, base);
    return Number.isFinite(code) && code > 0 && code <= 0x10ffff
      ? String.fromCodePoint(code)
      : match;
  });
}

export function normalizeContextContent(raw, contentType = "text/plain") {
  let text = String(raw || "").replace(/\0/g, "");
  if (/json/i.test(contentType)) {
    try {
      text = JSON.stringify(JSON.parse(text), null, 2);
    } catch {
      // Preserve malformed JSON as text; the source remains useful context.
    }
  } else if (/(?:html|xml)/i.test(contentType)) {
    text = text
      .replace(/<!--[\s\S]*?-->/g, " ")
      .replace(/<(script|style|noscript|svg|template)\b[\s\S]*?<\/\1>/gi, " ")
      .replace(/<\/?(?:article|aside|blockquote|br|dd|div|dl|dt|figcaption|figure|footer|h[1-6]|header|hr|li|main|nav|ol|p|pre|section|table|tbody|td|th|thead|tr|ul)\b[^>]*>/gi, "\n")
      .replace(/<[^>]+>/g, " ");
    text = decodeHtmlEntities(text);
  }
  return text
    .replace(/\r\n?/g, "\n")
    .split("\n")
    .map((line) => line.replace(/[ \t]+/g, " ").trim())
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function contextTitleFromHtml(raw) {
  const title = String(raw || "").match(/<title\b[^>]*>([\s\S]*?)<\/title>/i)?.[1];
  return title ? normalizeContextContent(title, "text/html").slice(0, 240) : "";
}

function privateIpv4(address) {
  const octets = address.split(".").map(Number);
  if (octets.length !== 4 || octets.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return true;
  const [a, b] = octets;
  return a === 0 || a === 10 || a === 127 || a >= 224
    || (a === 100 && b >= 64 && b <= 127)
    || (a === 169 && b === 254)
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && b === 168)
    || (a === 198 && (b === 18 || b === 19));
}

export function isPrivateContextAddress(rawAddress) {
  const address = String(rawAddress || "").replace(/^\[|\]$/g, "").toLowerCase();
  const version = isIP(address);
  if (version === 4) return privateIpv4(address);
  if (version !== 6) return true;
  // Only ordinary global unicast; exclude mapped, translation, and tunnel ranges.
  return !/^[23][0-9a-f]{3}:/.test(address)
    || /^(?:2001:(?:0:|db8:)|2002:)/.test(address);
}

export function validateContextUrl(raw) {
  let url;
  try {
    url = new URL(String(raw || ""));
  } catch {
    throw new Error("Enter a valid HTTP or HTTPS URL");
  }
  if (!["http:", "https:"].includes(url.protocol)) throw new Error("Only HTTP and HTTPS sources are supported");
  if (url.username || url.password) throw new Error("Source URLs cannot contain credentials");
  const hostname = url.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  if (!hostname || hostname === "localhost" || hostname.endsWith(".localhost")
    || hostname.endsWith(".local") || hostname.endsWith(".internal")) {
    throw new Error("Local and private hostnames are not allowed");
  }
  if (isIP(hostname) && isPrivateContextAddress(hostname)) {
    throw new Error("Private network addresses are not allowed");
  }
  url.hash = "";
  return url;
}

async function publicContextAddresses(url, lookupImpl) {
  const hostname = url.hostname.replace(/^\[|\]$/g, "");
  const addresses = isIP(hostname) ? [{ address: hostname, family: isIP(hostname) }]
    : await lookupImpl(hostname, { all: true, verbatim: true });
  if (!addresses.length || addresses.some(({ address }) => isPrivateContextAddress(address))) {
    throw bridgeError("SOURCE_NETWORK_BLOCKED");
  }
  return addresses;
}

async function limitedResponseText(response, maxBytes) {
  const declared = Number(response.headers.get("content-length") || 0);
  if (declared > maxBytes) { await response.body?.cancel(); throw bridgeError("RESPONSE_BYTE_LIMIT"); }
  if (!response.body) return "";
  if (!response.body.getReader) throw bridgeError("UNBOUNDED_RESPONSE");
  const reader = response.body.getReader();
  const chunks = [];
  let size = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > maxBytes) throw bridgeError("RESPONSE_BYTE_LIMIT");
      chunks.push(value);
    }
    return new TextDecoder("utf-8", { fatal: true }).decode(Buffer.concat(chunks, size));
  } catch (error) {
    await reader.cancel().catch(() => {});
    throw error;
  } finally { reader.releaseLock(); }
}

function fetchPinnedContext(url, options) {
  return new Promise((resolve, reject) => {
    const address = options.addresses[0];
    const request = (url.protocol === "https:" ? httpsRequest : httpRequest)(url, {
      signal: options.signal, headers: options.headers, agent: false,
      lookup(_host, lookupOptions, callback) {
        callback(null, lookupOptions.all ? [address] : address.address, address.family);
      },
    }, (response) => {
      const headers = new Headers();
      for (const [key, value] of Object.entries(response.headers)) {
        if (value !== undefined) headers.set(key, Array.isArray(value) ? value.join(", ") : value);
      }
      resolve({
        status: response.statusCode, ok: response.statusCode >= 200 && response.statusCode < 300,
        headers, body: Readable.toWeb(response),
      });
    });
    request.on("error", () => reject(bridgeError("SOURCE_FETCH_FAILED")));
    request.end();
  });
}

export async function fetchWebContext(rawUrl, options = {}) {
  const fetchImpl = options.fetchImpl || fetchPinnedContext;
  const lookupImpl = options.lookupImpl || lookup;
  const maxBytes = Math.min(options.maxBytes || 131_072, 131_072);
  const controller = new AbortController();
  const onAbort = () => controller.abort();
  options.signal?.addEventListener("abort", onAbort, { once: true });
  if (options.signal?.aborted) controller.abort();
  const timer = setTimeout(onAbort, Math.min(options.timeoutMs || 20_000, 20_000));
  let rejectAbort;
  const aborted = new Promise((_, reject) => { rejectAbort = reject; });
  const stop = () => rejectAbort(bridgeError("SOURCE_FETCH_STOPPED"));
  controller.signal.addEventListener("abort", stop, { once: true });
  const run = async () => {
    let url = validateContextUrl(rawUrl);
    for (let redirects = 0; redirects <= 5; redirects += 1) {
      const addresses = await publicContextAddresses(url, lookupImpl);
      if (controller.signal.aborted) throw bridgeError("SOURCE_FETCH_STOPPED");
      const response = await fetchImpl(url, {
        addresses, redirect: "manual", signal: controller.signal,
        headers: { Accept: "text/html,text/plain,application/json,application/xml",
          "Accept-Encoding": "identity", "User-Agent": "Seer-Context/2.0" },
      });
      if ([301, 302, 303, 307, 308].includes(response.status)) {
        await response.body?.cancel();
        const location = response.headers.get("location");
        if (!location || redirects === 5) throw bridgeError("SOURCE_REDIRECT_FAILED");
        url = validateContextUrl(new URL(location, url).toString());
        continue;
      }
      if (!response.ok) { await response.body?.cancel(); throw bridgeError("SOURCE_HTTP_FAILED"); }
      const contentType = response.headers.get("content-type")?.split(";")[0].trim().toLowerCase() || "text/plain";
      if (!(contentType.startsWith("text/") || /^application\/(?:json|(?:[\w.+-]+\+)?xml|rss\+xml|atom\+xml)$/.test(contentType))) {
        await response.body?.cancel(); throw bridgeError("SOURCE_CONTENT_UNSUPPORTED");
      }
      const raw = await limitedResponseText(response, maxBytes);
      const content = normalizeContextContent(raw, contentType);
      if (!content || Buffer.byteLength(content) > maxBytes) throw bridgeError("SOURCE_CONTENT_LIMIT");
      const title = /html/i.test(contentType) ? contextTitleFromHtml(raw) : "";
      return { label: title || url.hostname, content, url: url.toString() };
    }
    throw bridgeError("SOURCE_REDIRECT_FAILED");
  };
  try {
    if (controller.signal.aborted) stop();
    return await Promise.race([run(), aborted]);
  } catch {
    throw bridgeError("SOURCE_FETCH_FAILED");
  } finally {
    clearTimeout(timer); controller.abort();
    controller.signal.removeEventListener("abort", stop);
    options.signal?.removeEventListener("abort", onAbort);
  }
}


export function parseEditResult(raw) {
  const payload = jsonObjectFromProvider(raw);
  const edit = {};
  const limits = { title: 240, front: 16_000, back: 16_000, summary: 1_200 };
  for (const field of ["title", "front", "back", "summary"]) {
    if (typeof payload[field] !== "string" || !payload[field].trim()) {
      throw new Error(`The provider omitted the card ${field}`);
    }
    edit[field] = payload[field].trim();
    if (edit[field].includes("\0")) throw new Error(`The card ${field} contains an invalid character`);
    if (Buffer.byteLength(edit[field], "utf8") > limits[field]) {
      throw new Error(`The provider returned an oversized card ${field}`);
    }
  }
  return edit;
}

const STATE_OPERATION_KINDS = new Set([
  "create-stack", "rename-stack", "delete-stack", "create-card", "edit-card", "delete-card", "queue-card",
]);

function jsonObjectFromProvider(raw) {
  if (typeof raw !== "string" || Buffer.byteLength(raw) > 65_536) throw bridgeError("INVALID_PROVIDER_OUTPUT");
  try {
    const payload = JSON.parse(raw);
    if (!payload || Array.isArray(payload) || typeof payload !== "object") throw bridgeError("INVALID_PROVIDER_OUTPUT");
    return payload;
  } catch {
    throw bridgeError("INVALID_PROVIDER_OUTPUT");
  }
}


function checkedText(value, field, maxBytes) {
  if (typeof value !== "string" || !value.trim()) throw new Error(`The provider omitted ${field}`);
  const text = value.trim();
  if (text.includes("\0")) throw new Error(`${field} contains an invalid character`);
  if (Buffer.byteLength(text, "utf8") > maxBytes) throw new Error(`The provider returned oversized ${field}`);
  return text;
}

export function parseStatePlan(raw) {
  const payload = jsonObjectFromProvider(raw);
  const summary = checkedText(payload.summary, "the plan summary", 2_000);
  if (!Array.isArray(payload.operations)) throw bridgeError("INVALID_PROVIDER_OUTPUT");
  if (payload.operations.length === 0) throw bridgeError("NO_SUPPORTED_CANDIDATE");
  if (payload.operations.length > 64) throw bridgeError("OPERATION_LIMIT");
  const operations = payload.operations.map((input, index) => {
    if (!input || Array.isArray(input) || typeof input !== "object") {
      throw new Error(`Operation ${index + 1} is invalid`);
    }
    const kind = String(input.kind || "");
    if (!STATE_OPERATION_KINDS.has(kind)) throw bridgeError("INVALID_OPERATION");
    const operation = { kind };
    const requiredByKind = {
      "create-stack": ["stack_id", "title"],
      "rename-stack": ["stack_id", "title", "original_title"],
      "delete-stack": ["stack_id", "original_title"],
      "create-card": ["stack_id", "card_id", "title", "front", "back"],
      "edit-card": ["stack_id", "card_id", "title", "front", "back", "original_title", "original_front", "original_back"],
      "delete-card": ["stack_id", "card_id", "original_title", "original_front", "original_back"],
      "queue-card": ["stack_id", "card_id", "original_title", "original_front", "original_back"],
    }[kind];
    for (const field of ["stack_id", "card_id", "title", "front", "back", "original_title", "original_front", "original_back"]) {
      if (input[field] === undefined && !requiredByKind.includes(field)) operation[field] = "";
      else if (typeof input[field] !== "string") throw new Error(`Operation ${index + 1} omitted ${field}`);
      else operation[field] = input[field];
      if (requiredByKind.includes(field) && !operation[field].trim()) {
        throw new Error(`Operation ${index + 1} returned an empty ${field}`);
      }
      if (operation[field].includes("\0")) throw new Error(`Operation ${index + 1} contains an invalid character`);
      if (Buffer.byteLength(operation[field], "utf8") > 16_000) throw new Error(`Operation ${index + 1} has an oversized ${field}`);
    }
    if (!/^[a-z0-9][a-z0-9-]*$/.test(operation.stack_id)) throw new Error(`Operation ${index + 1} has an invalid stack_id`);
    const isStack = ["create-stack", "rename-stack", "delete-stack"].includes(kind);
    if (isStack ? operation.card_id !== "" : !/^[a-z0-9][a-z0-9-]*$/.test(operation.card_id)) {
      throw new Error(`Operation ${index + 1} has an invalid card_id`);
    }
    return operation;
  });

  const createdStacks = new Set(operations.filter((op) => op.kind === "create-stack").map((op) => op.stack_id));
  const deletedStacks = new Set(operations.filter((op) => op.kind === "delete-stack").map((op) => op.stack_id));
  const targets = new Set();
  for (const op of operations) {
    if (!["create-stack", "create-card"].includes(op.kind) && createdStacks.has(op.stack_id)) {
      throw bridgeError("INVALID_PLAN_DEPENDENCY");
    }
    if (!["delete-stack"].includes(op.kind) && deletedStacks.has(op.stack_id)) {
      throw bridgeError("CONFLICTING_OPERATIONS");
    }
    const target = op.card_id ? `${op.stack_id}/${op.card_id}` : op.stack_id;
    if (targets.has(target)) throw bridgeError("DUPLICATE_OPERATION");
    targets.add(target);
  }
  return { summary, operations };
}

export function parseDeskPlan(raw) {
  const payload = jsonObjectFromProvider(raw);
  return {
    summary: checkedText(payload.summary, "the brief summary", 2_000),
    artifact: checkedText(payload.artifact, "the implementation brief", 32_000),
  };
}


const ANSI_ESCAPE = /\u001b\[[0-9;?]*[ -/]*[@-~]/g;
const MAX_INTERACTIVE_OUTPUT = 64 * 1024;

export function stripAnsi(value) {
  return String(value || "").replace(ANSI_ESCAPE, "");
}

function allowedCodexAuthUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && [
      "auth.openai.com",
      "chatgpt.com",
      "platform.openai.com",
    ].includes(url.hostname);
  } catch {
    return false;
  }
}

export function parseCodexDeviceAuth(buffer) {
  const text = stripAnsi(buffer);
  const urls = text.match(/https:\/\/[^\s<>"']+/g) || [];
  const authUrl = urls.find(allowedCodexAuthUrl);
  if (!authUrl) return null;

  const codeCandidates = text.toUpperCase().match(/\b[A-Z0-9]{4,10}(?:-[A-Z0-9]{4,10})+\b/g) || [];
  const userCode = codeCandidates.find((candidate) => !authUrl.toUpperCase().includes(candidate));
  if (!userCode) return null;

  return { authUrl, userCode };
}


function allowedClaudeAuthUrl(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname === "claude.com" && url.pathname === "/cai/oauth/authorize";
  } catch {
    return false;
  }
}

export function parseClaudeAuthChallenge(buffer) {
  const text = stripAnsi(buffer);
  const urls = text.match(/https:\/\/[^\s<>"']+/g) || [];
  const authUrl = urls.find(allowedClaudeAuthUrl);
  return authUrl ? { authUrl } : null;
}


export function runInteractive(command, childArgs, options = {}) {
  if (process.platform === "win32") throw bridgeError("PROCESS_TREE_UNSUPPORTED");
  const child = spawn(command, childArgs, {
    cwd: options.cwd, env: providerEnvironment(options.env), detached: true,
    stdio: ["pipe", "pipe", "pipe"],
  });
  const chunks = { stdout: [], stderr: [] };
  const bytes = { stdout: 0, stderr: 0 };
  let inputBytes = 0;
  let settled = false;
  let failure = null;
  let killTimer;
  let resolveCompletion, rejectCompletion;
  const completion = new Promise((resolve, reject) => { resolveCompletion = resolve; rejectCompletion = reject; });
  const killGroup = (signal) => {
    if (!child.pid) return;
    try { process.kill(-child.pid, signal); } catch (error) { if (error.code !== "ESRCH") failure ||= "PROCESS_TERMINATION_FAILED"; }
  };
  const groupExists = () => {
    if (!child.pid) return false;
    try { process.kill(-child.pid, 0); return true; } catch (error) { return error.code !== "ESRCH"; }
  };
  const finish = () => {
    if (settled) return;
    settled = true;
    clearTimeout(timer); clearTimeout(killTimer);
    options.signal?.removeEventListener("abort", onAbort);
    child.stdin.destroy(); child.stdout.destroy(); child.stderr.destroy();
    chunks.stdout.length = 0; chunks.stderr.length = 0;
    if (failure) rejectCompletion(bridgeError(failure));
    else resolveCompletion({ code: 0 });
  };
  const stop = (code = "PROCESS_CANCELLED") => {
    if (settled) return;
    failure ||= code;
    killGroup("SIGTERM");
    child.stdin.destroy();
    if (!killTimer) killTimer = setTimeout(() => { killGroup("SIGKILL"); finish(); }, Math.min(options.killAfterMs ?? 1000, 5000));
    if (!child.pid) finish();
  };
  const onAbort = () => stop();
  const timer = setTimeout(() => stop("PROCESS_TIMEOUT"), Math.min(options.timeoutMs || 180_000, 180_000));
  for (const stream of ["stdout", "stderr"]) {
    child[stream].on("data", (chunk) => {
      if (settled || failure) return;
      bytes[stream] += chunk.length;
      if (bytes[stream] > MAX_INTERACTIVE_OUTPUT) { stop("PROCESS_OUTPUT_LIMIT"); return; }
      chunks[stream].push(chunk);
      try {
        options.onOutput?.({
          stdout: Buffer.concat(chunks.stdout).toString("utf8"),
          stderr: Buffer.concat(chunks.stderr).toString("utf8"),
        });
      } catch { stop("LOGIN_CHALLENGE_FAILED"); }
    });
    child[stream].on("error", () => stop("PROCESS_OUTPUT_FAILED"));
  }
  child.stdin.on("error", () => stop("PROCESS_STDIN_FAILED"));
  child.on("error", () => stop("PROCESS_SPAWN_FAILED"));
  child.on("spawn", () => { if (failure || options.signal?.aborted) stop(); });
  child.on("close", (code, signal) => {
    if (settled) return;
    if (code !== 0 || signal !== null) failure ||= "PROCESS_EXIT_FAILED";
    if (groupExists()) { stop("PROCESS_TREE_REMAINING"); return; }
    finish();
  });
  options.signal?.addEventListener("abort", onAbort, { once: true });
  if (options.signal?.aborted) stop();
  const writeInput = (value = "", end = false) => {
    inputBytes += Buffer.byteLength(value);
    if (inputBytes > 16_384) { stop("PROCESS_INPUT_LIMIT"); throw bridgeError("PROCESS_INPUT_LIMIT"); }
    if (settled || failure || !child.stdin.writable) throw bridgeError("PROCESS_STDIN_FAILED");
    if (end) child.stdin.end(value); else child.stdin.write(value);
  };
  return { completion, write: (value) => writeInput(value), end: (value) => writeInput(value, true),
    kill: () => stop() };
}

const SAFE_ERROR_CODES = new Set(["PROVIDER_UNSUPPORTED", "OUTCOME_UNKNOWN", "MUTATION_STOPPED",
  "INVALID_RECEIPT", "RPC_FAILED", "WORK_FENCED", "WORK_DEADLINE", "PACKET_BLOCKED",
  "PACKET_MISMATCH", "PROVIDER_UNAVAILABLE", "INVALID_PROVIDER_OUTPUT", "LOGIN_FAILED",
  "INVALID_BOUNDED_QUERY", "INCOMPLETE_LIBRARY_METADATA", "INVALID_LIBRARY_READ_REPORT",
  "INCOMPLETE_LIBRARY_READ", "LIBRARY_READ_REPORT_LIMIT", "NO_SUPPORTED_CANDIDATE"]);

function redactError(error) {
  // Never derive persisted or printed diagnostics from child/RPC/provider text.
  return SAFE_ERROR_CODES.has(error?.code) ? error.code : "BRIDGE_OPERATION_FAILED";
}

const WORK_TYPES = {
  question: { tool: "seer/list-card-questions", id: "question_id", claim: "claim-card-question", fail: "fail-card-question" },
  change: { tool: "seer/list-change-requests", id: "change_id", claim: "claim-change", fail: "fail-change" },
  context: { tool: "seer/list-context-sources", id: "context_id", claim: "claim-context-source", fail: "fail-context-source" },
  login: { tool: "seer/list-login-requests", id: "login_id", claim: "claim-login", fail: "fail-login" },
};

function workFields(job) {
  const [kind, owner, scope, id] = refFields(job.ref);
  return { work_kind: kind, owner, work_scope: scope, work_id: id };
}

function assertWork(job, config, previous = null) {
  const work = job?.work;
  if (!work || !["working", "challenge"].includes(job.status)
    || work.worker !== config.workerId || work.schema_version !== 2 || work.execution !== "running"
    || Number(decimal(work.attempt)) < 1 || canonicalHex(work.lease) === "0x0"
    || !Number.isSafeInteger(work.deadline_ms) || !Number.isSafeInteger(work.lease_until_ms)
    || Math.min(work.deadline_ms, work.lease_until_ms) <= Date.now()
    || (previous && (work.attempt !== previous.attempt || work.lease !== previous.lease))) {
    throw bridgeError("WORK_FENCED");
  }
  return work;
}

async function claimWork(config, cookie, kind, job, dependencies = {}) {
  if (shutdownRequested) throw bridgeError("WORK_FENCED");
  const call = dependencies.callTool || callTool;
  const type = WORK_TYPES[kind];
  const receipt = await call(config, cookie, `seer/${type.claim}`, {
    [type.id]: job[type.id], worker_id: config.workerId, attempt: "0", lease: "0x0",
  });
  if ((receipt?.receipt || receipt)?.status !== "ok") throw bridgeError("MUTATION_STOPPED");
  const detail = await readBoundedDetail(config, cookie, type.tool, job[type.id], {}, dependencies);
  const work = assertWork(detail.row, config);
  if (shutdownRequested) throw bridgeError("WORK_FENCED");
  const controller = new AbortController();
  let current = detail.row;
  let timer;
  let checking = false;
  let stopped = false;
  const values = () => ({ worker_id: config.workerId, attempt: decimal(work.attempt), lease: work.lease });
  const refresh = async () => {
    try {
      const result = await readBoundedDetail({ ...config, signal: controller.signal }, cookie, type.tool, job[type.id], {}, dependencies);
      assertWork(result.row, config, work);
      current = result.row;
      return current;
    } catch {
      controller.abort();
      throw bridgeError("WORK_FENCED");
    }
  };
  const mutation = async (action, fields = {}) => {
    if (stopped || controller.signal.aborted) throw bridgeError("WORK_FENCED");
    const request = WORKER_ACTIONS.get(action);
    const identity = request === type.id ? { [type.id]: job[type.id] } : {};
    const result = await call({ ...config, signal: controller.signal }, cookie, `seer/${action}`,
      { ...identity, ...values(), ...fields });
    if ((result?.receipt || result)?.status !== "ok") throw bridgeError("MUTATION_STOPPED", { ambiguous: true });
    return result;
  };
  const checkpoint = (stage) => mutation("checkpoint-work", { ...workFields(current), stage });
  const tick = async () => {
    if (stopped || checking) return;
    checking = true;
    try {
      await refresh();
      await mutation("heartbeat-work", workFields(current));
    } catch { controller.abort(); }
    finally {
      checking = false;
      if (!stopped && !controller.signal.aborted) timer = setTimeout(tick, 15_000);
    }
  };
  timer = setTimeout(tick, 15_000);
  const deadlineTimer = setTimeout(() => controller.abort(), Math.max(1, work.deadline_ms - Date.now()));
  const session = {
    get job() { return current; }, signal: controller.signal, refresh, mutation, checkpoint,
    stop() { stopped = true; clearTimeout(timer); clearTimeout(deadlineTimer); controller.abort(); activeSessions.delete(session); },
  };
  activeSessions.add(session);
  return session;
}

export function promptDigest(text) {
  // @ux atoms display the SHA-256 byte string as a little-endian integer.
  return formatHoonHex(createHash("sha256").update(text, "utf8").digest().reverse().toString("hex"));
}

const FAILED_LIBRARY_READS = new Set(["invalid-query", "limit-exceeded", "snapshot-expired", "snapshot-changed"]);

function libraryReadReport(report, scope) {
  if (!report || report.scope !== scope || typeof report.complete !== "boolean"
    || !Array.isArray(report.omissions) || report.omissions.length > 128
    || (report.complete && report.omissions.length)
    || report.omissions.some((row) => !row || Array.isArray(row)
      || typeof row.reason !== "string" || !row.reason || row.reason.length > 128)) {
    throw bridgeError("INVALID_LIBRARY_READ_REPORT");
  }
  if (report.omissions.some((row) => FAILED_LIBRARY_READS.has(row.reason))) {
    throw bridgeError("INCOMPLETE_LIBRARY_READ");
  }
  const encoded = JSON.stringify(report);
  if (Buffer.byteLength(encoded) > 16_384) throw bridgeError("LIBRARY_READ_REPORT_LIMIT");
  return encoded;
}

export function validateContextPacket(packet, job) {
  const work = job.work;
  const profile = packet?.profile;
  if (packet?.blocked_reason !== null || typeof packet.canonical_prompt !== "string") throw bridgeError("PACKET_BLOCKED");
  const mode = job.ref?.kind === "question" ? job.mode : job.target;
  if (!["ask", "edit", "library", "desk"].includes(mode) || packet.mode !== mode) throw bridgeError("PACKET_MISMATCH");
  if (packet.schema_version !== 2 || packet.output_schema_version !== 2
    || packet.packet_ref !== work.packet_ref || packet.prompt_digest !== work.packet_digest
    || packet.prompt_digest !== promptDigest(packet.canonical_prompt)
    || packet.input_bytes !== Buffer.byteLength(packet.canonical_prompt)
    || !Number.isSafeInteger(work.max_input_bytes) || work.max_input_bytes < 1
    || packet.input_bytes > Math.min(work.max_input_bytes, 131_072)
    || packet.input_bytes !== work.input_bytes || !Array.isArray(packet.entries) || packet.entries.length > 32
    || typeof packet.complete !== "boolean"
    || !Number.isSafeInteger(packet.prompt_version) || packet.prompt_version !== work.prompt_version
    || !profile || profile.provider !== job.provider || profile.provider !== work.provider
    || typeof profile.profile_id !== "string" || typeof profile.selector !== "string"
    || !["smol", "default", "slow"].includes(profile.role)
    || profile.profile_id !== job.model_id || profile.profile_id !== work.model_id
    || profile.model !== job.model || !profile.model || profile.model === "default"
    || profile.selector !== job.model_selector || profile.role !== job.model_role
    || !Number.isSafeInteger(work.model_revision) || work.model_revision < 1
    || Number(decimal(work.invocations)) >= Math.min(Number(decimal(work.max_invocations)), 1)
    || !Number.isSafeInteger(work.max_output_bytes) || work.max_output_bytes < 1
    || !Number.isSafeInteger(work.max_operations) || work.max_operations < 1) throw bridgeError("PACKET_MISMATCH");
  canonicalHex(packet.input_digest);
  // Verify the separately hashed source JSON bytes without reconstructing them.
  const marker = "\nBEGIN UNTRUSTED INPUT JSON\n";
  const end = "\nEND UNTRUSTED INPUT JSON\n";
  const start = packet.canonical_prompt.indexOf(marker);
  if (start < 0 || !packet.canonical_prompt.endsWith(end)) throw bridgeError("PACKET_MISMATCH");
  const input = packet.canonical_prompt.slice(start + marker.length, -end.length);
  if (promptDigest(input) !== packet.input_digest) throw bridgeError("PACKET_MISMATCH");
  if (mode === "library") {
    let library;
    try {
      library = JSON.parse(JSON.parse(input).card.front);
    } catch {
      throw bridgeError("INVALID_LIBRARY_READ_REPORT");
    }
    libraryReadReport(library?.read_report, "local-library");
    if (!Array.isArray(library.observations) || typeof library.source_coverage?.complete !== "boolean"
      || (library.read_report.complete && !library.source_coverage.complete)) {
      throw bridgeError("INVALID_LIBRARY_READ_REPORT");
    }
  }
  return packet.canonical_prompt;
}

function parseProviderOutput(raw, maxBytes) {
  if (typeof raw !== "string" || Buffer.byteLength(raw) > Math.min(maxBytes, 65_536)) throw bridgeError("INVALID_PROVIDER_OUTPUT");
  let result;
  try { result = JSON.parse(raw); } catch { throw bridgeError("INVALID_PROVIDER_OUTPUT"); }
  if (!result || Array.isArray(result) || typeof result !== "object") throw bridgeError("INVALID_PROVIDER_OUTPUT");
  const citations = checkedArray(result.citations, 32);
  workerActionFields("answer-card-question", { answer: "", citations });
  return result;
}

async function changeEvidenceSelections(config, cookie, id, dependencies) {
  const sources = await readBoundedPage(config, cookie, "seer/list-context-sources", {
    scope_type: "change", scope_id: id, limit: 64, max_bytes: 32_768,
  }, dependencies);
  if (sources.status !== "ok" || !sources.complete || sources.omissions.length) throw bridgeError("PACKET_BLOCKED");
  const selected = sources.contexts.filter((row) => row.active);
  if (selected.length > 32) throw bridgeError("PACKET_BLOCKED");
  return selected.map((row) => ({ source_id: row.context_id, start: 0, end: null,
    include: true, mandatory: true }));
}

async function processProviderWork(config, cookie, providers, kind, job, dependencies = {}) {
  const session = await claimWork(config, cookie, kind, job, dependencies);
  const call = dependencies.callTool || callTool;
  let invoked = false;
  let outputReceived = false;
  let published = false;
  try {
    job = session.job;
    if (!["codex", "claude"].includes(job.provider) || !providers[job.provider]) throw bridgeError("PROVIDER_UNAVAILABLE");
    if (kind === "change" && !session.job.work.packet_ref) {
      const context = job.target === "desk" ? { stacks: [], complete: true, omissions: [] }
        : await loadLibraryContext(config, cookie, job, dependencies);
      const scope = job.target === "desk" ? "not-applicable" : "local-library";
      const readReport = libraryReadReport({ scope, complete: context.complete, omissions: context.omissions }, scope);
      const selections = await changeEvidenceSelections(config, cookie, job.change_id, dependencies);
      await session.mutation("prepare-change-packet", {
        observations: libraryObservations(context), read_report: readReport, selections,
        max_bytes: "131072", excerpt_bytes: "24000",
      });
      await session.refresh();
    }
    const packet = await call(config, cookie, "seer/get-context-packet", {
      packet_ref: session.job.work.packet_ref, max_bytes: "262144",
    });
    const prompt = validateContextPacket(packet, session.job);
    // Retrieval is source-scoped; returned model-derived memory is not prompt authority.
    await call(config, cookie, "seer/lookup-learning", {
      scope_type: packet.scope.kind, scope_id: packet.scope.id || packet.scope.stack_id,
      owner: packet.scope.owner, card_id: packet.scope.card_id || "",
      objective: packet.objective, provider: packet.profile.provider, limit: "8", max_bytes: "32768",
    });
    const capability = await (dependencies.inspectProvider || inspectProvider)(providers[job.provider], job.provider, {
      signal: session.signal, timeoutMs: Math.max(1, Math.min(15_000, session.job.work.deadline_ms - Date.now())),
    });
    if (!capability.supported) throw bridgeError("PROVIDER_UNSUPPORTED");
    await session.checkpoint("context-frozen");
    await session.refresh();
    await session.checkpoint("provider-started");
    invoked = true;
    const raw = await (dependencies.runProvider || runProvider)({
      command: providers[job.provider], provider: packet.profile.provider, prompt,
      job: { model: packet.profile.model, model_role: packet.profile.role }, config,
      signal: session.signal, deadlineAtMs: session.job.work.deadline_ms,
      maxOutputBytes: Math.min(session.job.work.max_output_bytes, 65_536),
    });
    outputReceived = true;
    const result = parseProviderOutput(raw, session.job.work.max_output_bytes);
    await session.checkpoint("output-received");
    if (kind === "question") {
      if (session.job.mode === "edit") {
        const edit = parseEditResult(JSON.stringify({ ...result, summary: result.answer }));
        await session.mutation("apply-card-edit", { ...edit, citations: result.citations });
      } else {
        await session.mutation("answer-card-question", {
          answer: checkedText(result.answer, "answer", 60_000), citations: result.citations,
        });
      }
    } else {
      const plan = session.job.target === "desk" ? { ...parseDeskPlan(raw), operations: [] }
        : { ...parseStatePlan(raw), artifact: "" };
      if (plan.operations.length > session.job.work.max_operations) throw bridgeError("OPERATION_LIMIT");
      await session.mutation("finish-change", { ...plan, citations: result.citations });
    }
    published = true;
    return true;
  } catch (error) {
    if (!published && !error?.ambiguous && !session.signal.aborted) {
      const code = error?.code === "NO_SUPPORTED_CANDIDATE" ? error.code
        : invoked && !outputReceived && error?.code !== "PROVIDER_UNSUPPORTED"
          ? "OUTCOME_UNKNOWN" : outputReceived ? "INVALID_PROVIDER_OUTPUT" : redactError(error);
      await session.mutation(WORK_TYPES[kind].fail, { error: code });
    }
    throw bridgeError(redactError(error), { ambiguous: Boolean(error?.ambiguous) });
  } finally { session.stop(); }
}

export const processQuestion = (config, cookie, providers, job, dependencies = {}) =>
  processProviderWork(config, cookie, providers, "question", job, dependencies);
export const processChange = (config, cookie, providers, job, dependencies = {}) =>
  processProviderWork(config, cookie, providers, "change", job, dependencies);

export async function processContextSource(config, cookie, job, dependencies = {}) {
  const session = await claimWork(config, cookie, "context", job, dependencies);
  try {
    await session.checkpoint("provider-started");
    const fetched = await fetchWebContext(session.job.locator, {
      fetchImpl: dependencies.fetchImpl, lookupImpl: dependencies.lookupImpl,
      maxBytes: Math.min(config.contextMaxBytes || 131_072, 131_072),
      timeoutMs: Math.min(config.contextFetchTimeoutMs || 20_000, 20_000), signal: session.signal,
    });
    await session.checkpoint("output-received");
    await session.mutation("finish-context-source", {
      label: fetched.label || session.job.label, content: fetched.content, final_locator: fetched.url,
    });
    return true;
  } catch (error) {
    if (!error?.ambiguous && !session.signal.aborted) await session.mutation("fail-context-source", { error: "SOURCE_FETCH_FAILED" });
    throw error;
  } finally { session.stop(); }
}
function requireBridgeSecret(config) {
  const secret = process.env.SEER_BRIDGE_SECRET || config.bridgeSecret;
  if (!secret || Buffer.byteLength(secret, "utf8") < 32) {
    throw new Error("Set SEER_BRIDGE_SECRET or config.bridgeSecret to the >=32-byte secret paired in Seer");
  }
  return secret;
}

function canonicalField(value) {
  const text = String(value ?? "");
  return `${Buffer.byteLength(text, "utf8")}:${text}`;
}

function formatHoonHex(hex) {
  let remaining = hex.replace(/^0+/, "") || "0";
  const groups = [];
  while (remaining.length > 4) {
    groups.unshift(remaining.slice(-4));
    remaining = remaining.slice(0, -4);
  }
  groups.unshift(remaining);
  return `0x${groups.join(".")}`;
}

export function createBridgeProof(secret, action, requestId, workerId, nonce, fields = []) {
  const payload = ["seer-bridge-v2", action, requestId, workerId, nonce, ...fields]
    .map(canonicalField)
    .join("");
  return formatHoonHex(createHmac("sha256", secret).update(payload, "utf8").digest("hex"));
}

export async function reconcileActiveLogins(config, cookie, dependencies = {}) {
  for (const entry of activeLogins.values()) {
    if (!entry.session) continue;
    try { await entry.session.refresh(); }
    catch { entry.stopped = true; entry.session.stop(); entry.handle?.kill(); }
  }
}

export function startLogin(config, cookie, commands, job, refreshCatalog, dependencies = {}) {
  if (activeLogins.has(job.login_id)) return activeLogins.get(job.login_id).task;
  if (activeLogins.size >= READ_CAPS.activeLogins
    || [...activeLogins.values()].some((entry) => entry.provider === job.provider)) return null;
  const entry = { provider: job.provider, handle: null, session: null, stopped: false, task: null };
  activeLogins.set(job.login_id, entry);
  entry.task = (async () => {
    let published = false;
    let challengeTask;
    let challengeError;
    let externalStarted = false;
    try {
      entry.session = await claimWork(config, cookie, "login", job, dependencies);
      const session = entry.session;
      const command = commands[job.provider];
      if (!command || !["codex", "claude"].includes(job.provider)) throw bridgeError("PROVIDER_UNAVAILABLE");
      const loggedIn = job.provider === "claude"
        ? (dependencies.claudeLoggedIn || claudeLoggedIn) : (dependencies.codexLoggedIn || codexLoggedIn);
      await session.checkpoint("provider-started");
      externalStarted = true;
      if (job.login_id.startsWith("logout-")) {
        await (dependencies.runBoundedProcess || runBoundedProcess)(command,
          job.provider === "claude" ? ["auth", "logout"] : ["logout"], {
            env: providerEnvironment(), signal: session.signal,
            timeoutMs: Math.max(1, Math.min(30_000, session.job.work.deadline_ms - Date.now())),
            maxStdoutBytes: 16_384, maxStderrBytes: 16_384, maxStdinBytes: 0,
          });
        if (await loggedIn(command, config)) throw bridgeError("LOGIN_FAILED");
      } else {
        const interactiveArgs = job.provider === "claude" ? ["auth", "login", "--claudeai"] : ["login", "--device-auth"];
        entry.handle = (dependencies.runInteractive || runInteractive)(command, interactiveArgs, {
          env: providerEnvironment(), signal: session.signal,
          timeoutMs: Math.max(1, session.job.work.deadline_ms - Date.now()),
          onOutput({ stdout, stderr }) {
            if (challengeTask || entry.stopped) return;
            const challenge = job.provider === "claude"
              ? parseClaudeAuthChallenge(`${stdout}\n${stderr}`) : parseCodexDeviceAuth(`${stdout}\n${stderr}`);
            if (!challenge) return;
            challengeTask = (async () => {
              await session.mutation("post-login-challenge", {
                auth_url: challenge.authUrl, user_code: challenge.userCode || "",
              });
              if (job.provider !== "claude") return;
              while (!entry.stopped && !session.signal.aborted) {
                await (dependencies.sleep || sleep)(Math.min(config.pollIntervalMs || 2000, 5000));
                if (entry.stopped || session.signal.aborted) return;
                const latest = await session.refresh();
                if (!latest.code_ready) continue;
                const consumed = await session.mutation("consume-login-code", {
                  content_revision: decimal(latest.ref.content_revision),
                });
                const code = consumed?.result?.code;
                if (typeof code !== "string" || !code || Buffer.byteLength(code) > 8192 || /[\r\n\0]/.test(code)) {
                  throw bridgeError("OUTCOME_UNKNOWN", { ambiguous: true });
                }
                entry.handle.write(`${code}\n`);
                return;
              }
            })().catch((error) => {
              challengeError = error;
              entry.handle?.kill();
            });
          },
        });
        await entry.handle.completion;
        entry.stopped = true;
        if (challengeTask) await challengeTask;
        if (challengeError) throw challengeError;
        if (!challengeTask || !await loggedIn(command, config)) throw bridgeError("LOGIN_FAILED");
      }
      await session.checkpoint("output-received");
      await session.mutation("finish-login");
      published = true;
      session.stop();
      await refreshCatalog();
      return true;
    } catch (error) {
      if (entry.session && !published && !error?.ambiguous && !challengeError?.ambiguous && !entry.session.signal.aborted) {
        try { await entry.session.mutation("fail-login", { error: externalStarted ? "OUTCOME_UNKNOWN" : "LOGIN_FAILED" }); }
        catch { /* The durable attempt remains authoritative; never retry here. */ }
      }
      console.error(`[seer-ai] login stopped: ${redactError(error)}`);
      return false;
    } finally {
      entry.stopped = true;
      entry.session?.stop();
      entry.handle?.kill();
      if (entry.handle) await entry.handle.completion.catch(() => {});
      if (challengeTask) await challengeTask;
      activeLogins.delete(job.login_id);
    }
  })();
  return entry.task;
}

export async function recoverWork(config, cookie, kind, id, dependencies = {}) {
  const type = WORK_TYPES[kind];
  if (!type) throw bridgeError("INVALID_WORK_KIND");
  const { row } = await readBoundedDetail(config, cookie, type.tool, id, {}, dependencies);
  if (!row?.work || !Number.isSafeInteger(row.work.lease_until_ms)
    || row.work.lease_until_ms > Date.now()) throw bridgeError("WORK_FENCED");
  return (dependencies.callTool || callTool)(config, cookie, "seer/recover-work", {
    ...workFields(row), worker_id: config.workerId, attempt: decimal(row.work.attempt), lease: canonicalHex(row.work.lease),
  });
}

export async function cancelWork(config, cookie, kind, id, dependencies = {}) {
  const type = WORK_TYPES[kind];
  if (!type) throw bridgeError("INVALID_WORK_KIND");
  const { row } = await readBoundedDetail(config, cookie, type.tool, id, {}, dependencies);
  if (!row?.work) throw bridgeError("WORK_FENCED");
  if (!config.idempotencyEpoch) await ensureBridgeProtocol(config, cookie);
  const values = { idempotency_epoch: config.idempotencyEpoch, operation_id: randomUUID() };
  const fields = new URLSearchParams({
    "idempotency-epoch": values.idempotency_epoch, "operation-id": values.operation_id,
    "work-kind": row.ref.kind, "work-owner": row.ref.owner,
    "work-scope": row.ref.scope, "work-id": row.ref.id,
  });
  // This explicit operator CLI command uses authenticated Eyre, never a planner tool.
  // Whatever happens to its acknowledgement, reconcile once; do not replay the POST.
  try {
    const response = await fetch(new URL("/apps/seer/actions/cancel-work", config.mcpUrl), {
      method: "POST", redirect: "error",
      signal: AbortSignal.timeout(Math.min(config.mcpTimeoutMs || 30_000, 30_000)),
      headers: { Cookie: cookie, "Content-Type": "application/x-www-form-urlencoded" },
      body: fields,
    });
    await response.body?.cancel();
  } catch {}
  let result;
  try {
    result = checkedReceipt(await (dependencies.callTool || callTool)(
      config, cookie, "seer/get-operation-result", values,
    ), "cancel-work", values);
    // Cancellation commits work fences, not a library edit or a staged plan.
    if ((result.receipt || result).effect !== "none") {
      throw bridgeError("INVALID_RECEIPT", { ambiguous: true });
    }
  } catch (error) {
    if (["INVALID_RECEIPT", "MUTATION_STOPPED"].includes(error.code)) {
      Object.assign(error, values);
      throw error;
    }
    throw bridgeError("OUTCOME_UNKNOWN", { ambiguous: true, ...values });
  }
  for (const session of activeSessions) {
    if (session.job.ref.kind === row.ref.kind && session.job.ref.owner === row.ref.owner
      && session.job.ref.scope === row.ref.scope && session.job.ref.id === row.ref.id) session.stop();
  }
  return result;
}

export function stopActiveLogins(signal = "SIGTERM") {
  for (const entry of activeLogins.values()) {
    entry.stopped = true;
    entry.session?.stop();
    entry.handle?.kill(signal);
  }
}

export async function drainActiveLogins(timeoutMs = 7_000) {
  const tasks = [...activeLogins.values()].map((entry) => entry.task).filter(Boolean);
  if (tasks.length === 0) return true;
  stopActiveLogins("SIGTERM");
  let settled = false;
  const all = Promise.allSettled(tasks).then(() => { settled = true; });
  await Promise.race([all, sleep(timeoutMs)]);
  if (settled) return true;
  stopActiveLogins("SIGKILL");
  await Promise.race([all, sleep(1_000)]);
  return settled;
}

function installShutdownHandlers() {
  if (shutdownHandlersInstalled) return;
  shutdownHandlersInstalled = true;
  const shutdown = () => {
    shutdownRequested = true;
    for (const session of activeSessions) session.stop();
    stopActiveLogins("SIGTERM");
  };
  process.once("SIGTERM", shutdown);
  process.once("SIGINT", shutdown);
}

async function guarded(label, run) {
  try {
    await run();
  } catch (error) {
    console.error(`[seer-ai] ${label} failed: ${redactError(error)}`);
  }
}

export function createBridgeReadState() {
  return {
    queues: Object.fromEntries(Object.keys(READ_COLLECTIONS).map((tool) => [tool, createReadScan()])),
    active: new Map(), turn: 0,
  };
}

export async function poll(config, cookie, providers, commands, refreshCatalog, state, dependencies = {}) {
  await reconcileActiveLogins(config, cookie, dependencies);
  const queues = Object.entries(state.queues);
  const start = state.turn;
  state.turn = (state.turn + 1) % queues.length;
  let admitted = 0;
  for (let offset = 0; offset < queues.length; offset += 1) {
    if (shutdownRequested) break;
    const [tool, scan] = queues[(start + offset) % queues.length];
    // One slot per queue: a slow provider never occupies another class's slot.
    if (state.active.has(tool)) continue;
    try {
      const metadata = await nextReadJob(config, cookie, tool, { status: "pending" }, scan, dependencies);
      if (!metadata) continue;
      const [, idKey] = READ_COLLECTIONS[tool];
      const { row: job } = await readBoundedDetail(config, cookie, tool, metadata[idKey], {}, dependencies);
      if (!job || job.status !== "pending") continue;
      let task;
      if (tool === "seer/list-context-sources") {
        if (!job.active || job.kind !== "web") continue;
        task = (dependencies.processContextSource || processContextSource)(config, cookie, job, dependencies);
      } else if (tool === "seer/list-card-questions") {
        task = (dependencies.processQuestion || processQuestion)(config, cookie, providers, job, dependencies);
      } else if (tool === "seer/list-change-requests") {
        task = (dependencies.processChange || processChange)(config, cookie, providers, job, dependencies);
      } else {
        task = (dependencies.startLogin || startLogin)(config, cookie, commands, job, refreshCatalog, dependencies);
        if (!task) continue;
      }
      const settled = Promise.resolve(task).catch((error) => {
        console.error(`[seer-ai] work stopped: ${redactError(error)}; inspect durable work before an explicit new attempt`);
      }).finally(() => state.active.delete(tool));
      state.active.set(tool, settled);
      admitted += 1;
    } catch (error) {
      console.error(`[seer-ai] queue read stopped: ${redactError(error)}`);
    }
  }
  return admitted;
}


async function main() {
  installShutdownHandlers();
  const config = await loadConfig();
  const cookie = await resolveCookie(config);
  await ensureToolCoverage(config, cookie);
  await ensureBridgeProtocol(config, cookie);
  for (const [flag, operation] of [["--recover", recoverWork], ["--cancel", cancelWork]]) {
    if (!args.has(flag)) continue;
    const index = process.argv.indexOf(flag);
    const kind = process.argv[index + 1], id = process.argv[index + 2];
    if (!kind || !id || id.startsWith("--")) throw bridgeError("WORK_ID_REQUIRED");
    await operation(config, cookie, kind, id);
    console.log("[seer-ai] explicit work action received an authoritative receipt");
    return;
  }
  let commands = await resolveProviderCommands(config);
  let providers = {};
  let profiles = [];
  let nextCatalogRefresh = Date.now() + config.catalogRefreshMs;
  const refreshCatalog = async () => {
    await ensureBridgeProtocol(config, cookie);
    commands = await resolveProviderCommands(config);
    providers = await resolveProviders(config, commands);
    profiles = await discoverModelProfiles(providers, config);
    await publishModelProfiles(config, cookie, profiles);
    nextCatalogRefresh = Date.now() + config.catalogRefreshMs;
    console.log(`[seer-ai] refreshed account catalog: codex=${providers.codex ? "signed-in" : "unavailable"}, claude=${providers.claude ? "signed-in" : "unavailable"}, models=${profiles.length}; provider isolation is checked before each dispatch`);
  };

  await guarded("initial catalog refresh", refreshCatalog);
  const readState = createBridgeReadState();
  console.log(`[seer-ai] bridge running; ${profiles.length} exact account profiles; no automatic work recovery`);
  if (once) {
    await poll(config, cookie, providers, commands, refreshCatalog, readState);
    await Promise.allSettled([...readState.active.values()]);
    return;
  }
  while (!shutdownRequested) {
    try {
      if (Date.now() >= nextCatalogRefresh) await refreshCatalog();
      await poll(config, cookie, providers, commands, refreshCatalog, readState);
    } catch (error) {
      console.error(`[seer-ai] poll failed: ${redactError(error)}`);
      if (Date.now() >= nextCatalogRefresh) nextCatalogRefresh = Date.now() + 30_000;
    }
    await sleep(config.pollIntervalMs);
  }
  await drainActiveLogins();
  await Promise.allSettled([...readState.active.values()]);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(async (error) => {
    stopActiveLogins("SIGTERM");
    await drainActiveLogins();
    console.error(`[seer-ai] fatal: ${redactError(error)}`);
    if (error.operation_id && error.idempotency_epoch) {
      console.error(`[seer-ai] reconcile with seer/get-operation-result: ${JSON.stringify({
        idempotency_epoch: error.idempotency_epoch, operation_id: error.operation_id,
      })}`);
    }
    process.exitCode = 1;
  });
}
