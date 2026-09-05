import { spawn } from "node:child_process";
import { access, mkdtemp, realpath, rm } from "node:fs/promises";
import { constants } from "node:fs";
import { tmpdir } from "node:os";
import { delimiter, isAbsolute, join, resolve } from "node:path";

const MAX_TIMER_MS = 2_147_483_647;
const MAX_INPUT_BYTES = 262_144;
const ENVIRONMENT_KEYS = [
  "PATH", "HOME", "LANG", "LANGUAGE", "LC_ALL", "LC_CTYPE", "LC_MESSAGES",
  "LC_COLLATE", "LC_NUMERIC", "LC_TIME", "LC_MONETARY",
  "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME", "XDG_STATE_HOME",
  "CODEX_HOME", "CLAUDE_CONFIG_DIR",
];

// Only account *locations* survive. No credential, proxy, shell, Node, harness,
// or Seer environment variables are inherited. Account files stay in place.
export function providerEnvironment(env = process.env) {
  const result = {};
  for (const key of ENVIRONMENT_KEYS) {
    if (typeof env[key] === "string" && !env[key].includes("\0")) result[key] = env[key];
  }
  return result;
}

function failure(code, metadata = {}) {
  return Object.assign(new Error(code), { code, ...metadata });
}

function bound(value, fallback, allowZero = false) {
  const number = value === undefined ? fallback : value;
  if (!Number.isSafeInteger(number) || number < (allowZero ? 0 : 1) || number > MAX_TIMER_MS) {
    throw failure("INVALID_PROCESS_LIMIT");
  }
  return number;
}

function checkSignal(signal) {
  if (signal !== undefined && (
    typeof signal?.aborted !== "boolean" || typeof signal.addEventListener !== "function" ||
    typeof signal.removeEventListener !== "function"
  )) throw failure("INVALID_ABORT_SIGNAL");
  if (signal?.aborted) throw failure("PROCESS_CANCELLED");
}

function inputSize(input, limit) {
  if (typeof input !== "string" && !Buffer.isBuffer(input)) throw failure("INVALID_PROCESS_INPUT");
  const bytes = Buffer.byteLength(input);
  if (bytes > limit) throw failure("PROCESS_STDIN_LIMIT", { stdinBytes: bytes });
  return bytes;
}

// POSIX sessions give the supervisor ownership of the complete process group,
// including descendants after the group leader exits. This is not an OS sandbox:
// a hostile executable can escape a group with setsid; provider tools must also be
// disabled at the adapter boundary. Windows needs Job Objects, not child.kill().
export async function runBoundedProcess(command, args, options = {}) {
  checkSignal(options.signal);
  if (process.platform === "win32") throw failure("PROCESS_TREE_UNSUPPORTED");
  const timeoutMs = bound(options.timeoutMs, 180_000);
  const killAfterMs = bound(options.killAfterMs, 1_000, true);
  const maxStdoutBytes = bound(options.maxStdoutBytes, 65_536, true);
  const maxStderrBytes = bound(options.maxStderrBytes, 16_384, true);
  const maxStdinBytes = bound(options.maxStdinBytes, MAX_INPUT_BYTES, true);
  const input = options.stdin === undefined ? "" : options.stdin;
  const stdinBytes = inputSize(input, maxStdinBytes);
  const deadline = Date.now() + timeoutMs;
  if (typeof command !== "string" || !command || command.includes("\0") || !Array.isArray(args) ||
      args.some((arg) => typeof arg !== "string" || arg.includes("\0"))) {
    throw failure("INVALID_PROCESS_COMMAND");
  }

  return new Promise((resolveResult, reject) => {
    let child;
    try {
      child = spawn(command, args, {
        cwd: options.cwd,
        env: options.env === undefined ? providerEnvironment() : options.env,
        detached: true,
        shell: false,
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch {
      reject(failure("PROCESS_SPAWN_FAILED", { stdinBytes }));
      return;
    }
    const chunks = { stdout: [], stderr: [] };
    const bytes = { stdout: 0, stderr: 0 };
    let settled = false;
    let closed = false;
    let errorCode = null;
    let exitCode = null;
    let exitSignal = null;
    let timer;
    let killTimer;

    const metadata = () => ({
      exitCode, signal: exitSignal, stdinBytes,
      stdoutBytes: bytes.stdout, stderrBytes: bytes.stderr,
    });
    const groupExists = () => {
      if (!child.pid) return false;
      try { process.kill(-child.pid, 0); return true; }
      catch (error) { return error.code !== "ESRCH"; }
    };
    const killGroup = (signal) => {
      if (!child.pid) return;
      try { process.kill(-child.pid, signal); }
      catch (error) {
        if (error.code !== "ESRCH") errorCode ||= "PROCESS_TERMINATION_FAILED";
      }
    };
    const finish = () => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      clearTimeout(killTimer);
      options.signal?.removeEventListener("abort", onAbort);
      child.removeListener("spawn", onSpawn);
      child.removeListener("close", onClose);
      child.removeListener("error", onChildError);
      // A spawn error or stream error may already be queued after destruction.
      child.once("error", () => {});
      child.stdin.removeListener("error", onInputError);
      child.stdin.once("error", () => {});
      child.stdout.removeListener("data", onStdout);
      child.stderr.removeListener("data", onStderr);
      child.stdout.removeListener("error", onOutputError);
      child.stderr.removeListener("error", onOutputError);
      child.stdout.once("error", () => {});
      child.stderr.once("error", () => {});
      child.stdin.destroy();
      child.stdout.destroy();
      child.stderr.destroy();
      if (errorCode) {
        chunks.stdout.length = 0;
        chunks.stderr.length = 0;
        reject(failure(errorCode, metadata()));
        return;
      }
      try {
        // Decode once after admission of every byte, preserving split UTF-8
        // characters while rejecting an incomplete or malformed encoding.
        const decoder = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });
        const stdout = decoder.decode(Buffer.concat(chunks.stdout, bytes.stdout));
        const stderr = decoder.decode(Buffer.concat(chunks.stderr, bytes.stderr));
        resolveResult({ stdout, stderr, code: exitCode, signal: exitSignal });
      } catch {
        reject(failure("PROCESS_INVALID_UTF8", metadata()));
      }
    };
    const stop = (code) => {
      if (settled || errorCode) return;
      errorCode = code;
      clearTimeout(timer);
      chunks.stdout.length = 0;
      chunks.stderr.length = 0;
      child.stdin.destroy();
      child.stdout.pause();
      child.stderr.pause();
      killGroup("SIGTERM");
      if (!child.pid || (closed && !groupExists())) { finish(); return; }
      // Do not cancel escalation just because the leader has closed its pipes.
      killTimer = setTimeout(() => {
        killGroup("SIGKILL");
        finish();
      }, killAfterMs);
    };
    const onAbort = () => stop("PROCESS_CANCELLED");
    const onInputError = () => stop("PROCESS_STDIN_FAILED");
    const onOutputError = () => stop("PROCESS_OUTPUT_FAILED");
    const onChildError = () => stop("PROCESS_SPAWN_FAILED");
    const collect = (stream, chunk, limit) => {
      if (settled || errorCode) return;
      bytes[stream] += chunk.length;
      if (bytes[stream] > limit) { stop(`PROCESS_${stream.toUpperCase()}_LIMIT`); return; }
      chunks[stream].push(chunk);
    };
    const onStdout = (chunk) => collect("stdout", chunk, maxStdoutBytes);
    const onStderr = (chunk) => collect("stderr", chunk, maxStderrBytes);
    const onSpawn = () => {
      if (errorCode || settled) { killGroup("SIGTERM"); return; }
      if (options.signal?.aborted) { stop("PROCESS_CANCELLED"); return; }
      if (Date.now() >= deadline) { stop("PROCESS_TIMEOUT"); return; }
      child.stdin.end(input, (error) => { if (error) onInputError(); });
    };
    const onClose = (code, signal) => {
      closed = true;
      exitCode = code;
      exitSignal = signal;
      if (errorCode) {
        if (!groupExists()) finish();
        return;
      }
      if (options.signal?.aborted) { stop("PROCESS_CANCELLED"); return; }
      if (Date.now() >= deadline) { stop("PROCESS_TIMEOUT"); return; }
      if (code !== 0 || signal !== null) { stop("PROCESS_EXIT_FAILED"); return; }
      if (groupExists()) { stop("PROCESS_TREE_REMAINING"); return; }
      finish();
    };
    child.on("spawn", onSpawn);
    child.on("error", onChildError);
    child.on("close", onClose);
    child.stdin.on("error", onInputError);
    child.stdout.on("error", onOutputError);
    child.stderr.on("error", onOutputError);
    child.stdout.on("data", onStdout);
    child.stderr.on("data", onStderr);
    options.signal?.addEventListener("abort", onAbort, { once: true });
    timer = setTimeout(() => stop("PROCESS_TIMEOUT"), Math.max(1, deadline - Date.now()));
    if (options.signal?.aborted) onAbort();
  });
}

async function executablePath(command, env) {
  if (typeof command !== "string" || !command || command.includes("\0")) throw failure("INVALID_PROCESS_COMMAND");
  const candidates = isAbsolute(command) || command.includes("/")
    ? [resolve(command)]
    : (env.PATH || "/usr/local/bin:/usr/bin:/bin").split(delimiter)
      .filter((directory) => isAbsolute(directory)).map((directory) => join(directory, command));
  for (const candidate of candidates) {
    try {
      await access(candidate, constants.X_OK);
      return await realpath(candidate);
    } catch {}
  }
  throw failure("PROVIDER_EXECUTABLE_UNAVAILABLE");
}

function unsupported(reason, version = null) {
  return { supported: false, reason, version };
}

// No model calls, auth changes, persistent capability cache, or provider-result
// cache. Re-read version/help for the resolved executable on each inspection.
export async function inspectProvider(command, provider, options = {}) {
  checkSignal(options.signal);
  if (provider !== "codex" && provider !== "claude") return unsupported("provider_unknown");
  if (process.platform === "win32") return unsupported("process_tree_unsupported");
  const env = providerEnvironment(options.env);
  const timeoutMs = Math.min(bound(options.timeoutMs, 15_000), 15_000);
  const deadline = Date.now() + timeoutMs;
  let directory;
  let version = null;
  try {
    const executable = await executablePath(command, env);
    checkSignal(options.signal);
    directory = await mkdtemp(join(tmpdir(), "seer-provider-inspect-"));
    const probe = (args, maxStdoutBytes) => {
      checkSignal(options.signal);
      const remaining = deadline - Date.now();
      if (remaining <= 0) throw failure("PROCESS_TIMEOUT");
      return runBoundedProcess(executable, args, {
        cwd: directory, env, signal: options.signal, timeoutMs: remaining,
        maxStdoutBytes, maxStderrBytes: 16_384, maxStdinBytes: 0,
      });
    };
    const versionOutput = await probe(["--version"], 1_024);
    const versionPattern = provider === "codex"
      ? /^codex-cli (\d{1,6}\.\d{1,6}\.\d{1,6}(?:[-+][A-Za-z0-9.-]{1,64})?)\s*$/
      : /^(\d{1,6}\.\d{1,6}\.\d{1,6}(?:[-+][A-Za-z0-9.-]{1,64})?) \(Claude Code\)\s*$/;
    version = versionOutput.stdout.match(versionPattern)?.[1] || null;
    if (!version) return unsupported("provider_version_unrecognized");
    const { stdout: help } = await probe(provider === "codex" ? ["exec", "--help"] : ["--help"], 65_536);
    if (provider === "codex") {
      if (!["--ignore-user-config", "--ignore-rules", "--ephemeral", "--json"].every((flag) => help.includes(flag))) {
        return unsupported("codex_isolation_flags_unavailable", version);
      }
      // The rust-v0.151.0 config schema has shell/plan/input feature switches,
      // but spec_plan.rs:add_core_utility_tools adds ApplyPatchHandler whenever
      // the environment exists and the exact model advertises apply_patch.
      // apply_patch_freeform changes its format; it does not disable the tool.
      // https://github.com/openai/codex/blob/rust-v0.151.0/codex-rs/core/src/tools/spec_plan.rs
      // https://github.com/openai/codex/blob/rust-v0.151.0/codex-rs/core/config.schema.json
      return unsupported("codex_no_tools_envelope_unavailable", version);
    }
    if (!["--tools", "--safe-mode", "--setting-sources", "--strict-mcp-config", "--no-session-persistence"].every((flag) => help.includes(flag))) {
      return unsupported("claude_isolation_flags_unavailable", version);
    }
    // Claude 2.1.257: --safe-mode and disableAllHooks still permit managed hooks
    // and policy env/config, including policies fetched after account login.
    // --bare does not read OAuth/account files. Using an API key or helper is a
    // different authentication contract, not an acceptable silent fallback.
    // https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration
    // https://code.claude.com/docs/en/headless#start-faster-with-bare-mode
    return unsupported("claude_account_auth_isolation_unavailable", version);
  } catch (error) {
    if (error?.code === "PROCESS_CANCELLED") throw error;
    const reasons = {
      PROVIDER_EXECUTABLE_UNAVAILABLE: "provider_executable_unavailable",
      PROCESS_TIMEOUT: "provider_inspection_timeout",
      PROCESS_STDOUT_LIMIT: "provider_inspection_output_limit",
      PROCESS_STDERR_LIMIT: "provider_inspection_output_limit",
    };
    return unsupported(reasons[error?.code] || "provider_inspection_failed", version);
  } finally {
    if (directory) {
      try { await rm(directory, { recursive: true, force: true }); }
      catch { throw failure("PROVIDER_CLEANUP_FAILED"); }
    }
  }
}

// Fail closed before any prompt reaches an executable. Neither inspected CLI
// currently satisfies the account-file + no-tools/no-hooks/config contract.
// Unsupported is a complete adapter outcome, not an invitation to use the old
// sandbox-only path. In particular there is no raw-text parser fallback, partial
// result, fabricated usage, or speculative invocation behind this boundary.
export async function runProvider({ command, provider, prompt, job, config = {}, signal, deadlineAtMs, maxOutputBytes = 65_536 }) {
  checkSignal(signal);
  if (typeof prompt !== "string") throw failure("INVALID_PROVIDER_PROMPT");
  inputSize(prompt, MAX_INPUT_BYTES);
  bound(maxOutputBytes, 65_536);
  if (typeof job?.model !== "string" || !job.model.trim() || job.model !== job.model.trim() ||
      job.model === "default" || job.model.includes("\0")) throw failure("PROVIDER_EXACT_MODEL_REQUIRED");
  const timeoutMs = bound(config.timeoutMs, 180_000);
  if (deadlineAtMs !== undefined && (!Number.isSafeInteger(deadlineAtMs) || deadlineAtMs < 0)) {
    throw failure("INVALID_PROVIDER_DEADLINE");
  }
  const deadline = Math.min(deadlineAtMs ?? Date.now() + timeoutMs, Date.now() + timeoutMs);
  if (deadline <= Date.now()) throw failure("PROCESS_TIMEOUT");
  const inspection = await inspectProvider(command, provider, {
    signal, timeoutMs: Math.max(1, Math.min(15_000, deadline - Date.now())),
  });
  checkSignal(signal);
  if (deadline <= Date.now()) throw failure("PROCESS_TIMEOUT");
  throw failure("PROVIDER_UNSUPPORTED", { reason: inspection.reason, version: inspection.version });
}
