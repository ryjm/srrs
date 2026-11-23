// The real artifact through the loader. tools/verify-rwkv builds the
// artifact into rwkv-engine/dist (or RWKV_ARTIFACT_DIR) with native-r.json,
// the native engine's output on the fixture, and runs these tests. Only
// fetch and the ship are stubbed. Missing files fail the suite; with
// RWKV_ARTIFACT_OPTIONAL=1 they skip it instead, for a local run that
// has not built them.
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { createRequire } from "node:module";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { Worker } from "node:worker_threads";

const require = createRequire(import.meta.url);
const loaderPath = fileURLToPath(new URL("../desk/lib/web/rwkv-loader.js", import.meta.url));
const { run, sha256Hex, wasmEngine, workerEngine } = require(loaderPath);

// A Node worker thread behind the Web Worker interface workerEngine uses,
// running the loader's own worker side.
function nodeWorker() {
  const thread = new Worker(`
    const { parentPort } = require("node:worker_threads");
    const scope = { postMessage: (message) => parentPort.postMessage(message) };
    parentPort.on("message", (data) => scope.onmessage({ data }));
    require(${JSON.stringify(loaderPath)}).serveEngine(scope);
  `, { eval: true });
  const worker = {
    postMessage: (message) => thread.postMessage(message),
    terminate: () => thread.terminate(),
  };
  thread.on("message", (data) => worker.onmessage({ data }));
  thread.on("error", (error) => worker.onerror(error));
  return worker;
}

const dir = process.env.RWKV_ARTIFACT_DIR ??
  fileURLToPath(new URL("../rwkv-engine/dist/", import.meta.url));
const fixtures = new URL("../rwkv-engine/tests/fixtures/", import.meta.url);
const missing = ["manifest.json", "engine.wasm", "weights.bin", "native-r.json"]
  .filter((name) => !existsSync(join(dir, name)));
const skip = process.env.RWKV_ARTIFACT_OPTIONAL === "1" && missing.length > 0 &&
  `RWKV_ARTIFACT_OPTIONAL=1 and ${missing.join(", ")} missing from ${dir}`;

test("real artifact: the built artifact and native output are present", { skip }, () => {
  assert.deepEqual(missing, [], `missing from ${dir}: run tools/verify-rwkv`);
});

const read = (name) => new Uint8Array(readFileSync(join(dir, name)));
const { now_ms, events } = JSON.parse(readFileSync(new URL("revlog.json", fixtures)));
const fork = JSON.parse(readFileSync(new URL("reference-r.json", fixtures))).cards;
const key = (row) => JSON.stringify([row.owner, row.stack, row.item]);
const cards = new Set(events.map(key));

function maxDiff(rows, reference) {
  const byKey = new Map(reference.map((row) => [key(row), row.r]));
  assert.equal(rows.length, byKey.size);
  return Math.max(...rows.map((row) => Math.abs(row.r - byKey.get(key(row)))));
}

async function quiet(fn) {
  const warn = console.warn;
  console.warn = () => {};
  try {
    return await fn();
  } finally {
    console.warn = warn;
  }
}

// The ship's scry serving `revlog` and the real artifact on a CDN.
async function stubShip(revlog, head, shipNow) {
  const manifestBytes = read("manifest.json");
  const artifactHash = await sha256Hex(manifestBytes);
  const files = {
    "/~/scry/seer/rwkv.json": {
      enabled: true, target_ppm: 900000, max_daily: 200, min_daily: 0,
      artifact_url: "https://cdn.example/rwkv/manifest.json", artifact_hash: artifactHash,
      head, fresh: false, idempotency_epoch: "~2026.9.2", now_ms: shipNow, revlog,
    },
    "https://cdn.example/rwkv/manifest.json": manifestBytes,
    "https://cdn.example/rwkv/engine.wasm": read("engine.wasm"),
    "https://cdn.example/rwkv/weights.bin": read("weights.bin"),
  };
  const posts = [];
  const fetch = async (url, init) => {
    if (init?.method === "POST") {
      posts.push({ url, init });
      return { ok: true };
    }
    const body = files[url];
    if (body === undefined) return { ok: false, status: 404 };
    return {
      ok: true,
      json: async () => body,
      arrayBuffer: async () => body.buffer.slice(body.byteOffset, body.byteOffset + body.byteLength),
    };
  };
  return { fetch, posts, artifactHash };
}

test("real artifact: verified, predicted, and poked as RWKV.md says", { skip }, async () => {
  const head = events.at(-1).id;
  const { fetch, posts, artifactHash } = await stubShip(events, head, now_ms);
  const body = await run({ fetch, engine: wasmEngine, base: "https://ship.example/" });
  assert.notEqual(body, null, "the run verified every hash and posted");
  assert.equal(posts.length, 1);
  assert.equal(posts[0].url, "/apps/seer/actions/rwkv-predictions");
  assert.equal(posts[0].init.credentials, "same-origin");
  assert.equal(posts[0].init.headers["content-type"], "application/x-www-form-urlencoded");

  const fields = Object.fromEntries(new URLSearchParams(posts[0].init.body));
  assert.deepEqual(Object.keys(fields).sort(),
    ["artifact", "head", "idempotency-epoch", "operation-id", "predictions"]);
  assert.equal(fields.artifact, artifactHash);
  assert.equal(fields.head, String(head));
  assert.equal(fields["idempotency-epoch"], "~2026.9.2");
  assert.equal(fields["operation-id"], `rwkv-${head}-${now_ms}`);
  const predictions = JSON.parse(fields.predictions);
  assert.deepEqual(new Set(predictions.map(key)), cards);
  for (const p of predictions) {
    assert.deepEqual(Object.keys(p).sort(), ["item", "owner", "ppm", "stack"]);
    assert.ok(Number.isInteger(p.ppm) && p.ppm >= 0 && p.ppm <= 1e6, JSON.stringify(p));
  }
  const ppmDiff = maxDiff(predictions.map((p) => ({ ...p, r: p.ppm / 1e6 })), fork);
  assert.ok(ppmDiff <= 1e-4 + 5e-7, `posted ppm vs fork: ${ppmDiff}`);
});

// Same day: A, then B, answered; A deleted, recreated under its name and
// answered; then C. withRetired is the scry before it kept only live card
// incarnations; live is what it sends now.
const T = Date.UTC(2026, 6, 1, 9, 0);
const MINUTE = 60_000;
const learn = (id, item, grade, at) =>
  ({ id, owner: "~zod", stack: "s1", item, grade, kind: "learn", shown_at: at - 5_000, answered_at: at });
const withRetired = [
  learn(0, "a", "good", T), learn(1, "b", "easy", T + MINUTE),
  learn(2, "a", "again", T + 3 * MINUTE), learn(3, "c", "hard", T + 4 * MINUTE),
];
const live = withRetired.slice(1);

test("real artifact: a recreated card is a new card, not the old one", { skip }, async () => {
  const engine = await wasmEngine(read("engine.wasm"), read("weights.bin"));
  const at = { now_ms: T + 10 * MINUTE };
  assert.throws(() => engine.predict({ ...at, events: withRetired }), /predict failed/);
  const { fetch, posts } = await stubShip(withRetired, 3, at.now_ms);
  const body = await quiet(() =>
    run({ fetch, engine: wasmEngine, base: "https://ship.example/" }));
  assert.equal(body, null);
  assert.equal(posts.length, 0, "a retired incarnation in the input posts nothing");

  const rows = engine.predict({ ...at, events: live });
  assert.equal(new Set(rows.map((row) => row.r)).size, 3, JSON.stringify(rows));
  assert.deepEqual(engine.predict({ ...at, events: [] }), [], "recreated, not yet answered: no score");
});

test("real artifact: a query before the newest answer gets no scores", { skip }, async () => {
  const engine = await wasmEngine(read("engine.wasm"), read("weights.bin"));
  const early = events.at(-1).answered_at - 48 * 3_600_000;
  assert.throws(() => engine.predict({ now_ms: early, events }), /predict failed/);
  const { fetch, posts } = await stubShip(events, events.at(-1).id, early);
  assert.equal(await quiet(() => run({ fetch, engine: wasmEngine, base: "https://ship.example/" })), null);
  assert.equal(posts.length, 0);
});

test("real artifact: the ABI refuses negative lengths and null pointers", { skip }, async () => {
  const { instance } = await WebAssembly.instantiate(read("engine.wasm"), {});
  const x = instance.exports;
  const put = (bytes) => {
    const ptr = x.alloc(bytes.length);
    new Uint8Array(x.memory.buffer, ptr, bytes.length).set(bytes);
    return ptr;
  };
  assert.equal(x.alloc(-1), 0, "alloc refuses a negative length");
  assert.notEqual(x.load_weights(0, 4), 0, "load_weights refuses a null pointer");
  assert.notEqual(x.load_weights(x.alloc(4), -1), 0, "load_weights refuses a negative length");
  const weights = read("weights.bin");
  assert.equal(x.load_weights(put(weights), weights.length), 0);
  const input = new TextEncoder().encode(JSON.stringify({ now_ms, events }));
  assert.equal(x.predict(0, input.length), 0, "predict refuses a null pointer");
  assert.equal(x.predict(x.alloc(4), -1), 0, "predict refuses a negative length");
  assert.notEqual(x.predict(put(input), input.length), 0, "the instance still predicts");
  assert.equal(JSON.parse(new TextDecoder().decode(
    new Uint8Array(x.memory.buffer, x.predict(put(input), input.length), x.output_len()),
  )).length, cards.size);
});

test("real artifact: wasm R equals the native engine and the fork", { skip }, async () => {
  const engine = await wasmEngine(read("engine.wasm"), read("weights.bin"));
  const rows = engine.predict({ now_ms, events });
  for (const row of rows) assert.ok(row.r >= 0 && row.r <= 1, JSON.stringify(row));
  const native = JSON.parse(readFileSync(join(dir, "native-r.json")));
  const vsNative = maxDiff(rows, native);
  const vsFork = maxDiff(rows, fork);
  console.log(`max |wasm - native| R = ${vsNative}; max |wasm - fork| R = ${vsFork}; ${rows.length} cards`);
  assert.ok(vsNative <= 1e-6, `wasm vs native: ${vsNative}`);
  assert.ok(vsFork <= 1e-4, `wasm vs fork: ${vsFork}`);
});

test("real artifact: the worker engine posts what the page-thread engine would", { skip }, async () => {
  const head = events.at(-1).id;
  const bodies = [];
  for (const engine of [wasmEngine, workerEngine(nodeWorker)]) {
    const { fetch } = await stubShip(events, head, now_ms);
    bodies.push(await run({ fetch, engine, base: "https://ship.example/" }));
  }
  assert.notEqual(bodies[1], null);
  assert.equal(bodies[1], bodies[0], "same head, artifact and scores");
});

// 4,096 answers over 256 cards, one learning start each, a day apart.
function largeRevlog() {
  const grades = ["again", "hard", "good", "easy"];
  const DAY = 86_400_000;
  const log = [];
  for (let i = 0; i < 4096; i++) {
    const card = i % 256;
    const round = Math.floor(i / 256);
    const at = T + round * DAY + card * 60_000;
    log.push({
      id: i, owner: "~zod", stack: `s${card % 4}`, item: `c${card}`,
      grade: grades[(i * 7) % 4], kind: round === 0 ? "learn" : "review",
      shown_at: at - 8_000, answered_at: at,
    });
  }
  return { now_ms: T + 16 * DAY, events: log };
}

test("real artifact: a long replay in the worker leaves the page thread free", { skip }, async () => {
  const input = largeRevlog();
  const engineBytes = read("engine.wasm");
  const weightBytes = read("weights.bin");
  const inline = await wasmEngine(engineBytes, weightBytes);
  const started = performance.now();
  const expected = inline.predict(input);
  const blocked = performance.now() - started;

  const engine = await workerEngine(nodeWorker)(engineBytes, weightBytes);
  let ticks = 0;
  let longest = 0;
  let last = performance.now();
  let done = false;
  const tick = () => {
    const now = performance.now();
    longest = Math.max(longest, now - last);
    last = now;
    ticks++;
    if (!done) setTimeout(tick, 0);
  };
  setTimeout(tick, 0);
  const rows = await engine.predict(input);
  done = true;
  console.log(`page thread: ${blocked.toFixed(0)} ms blocked inline; ` +
    `${ticks} timer ticks, longest gap ${longest.toFixed(1)} ms with the worker`);
  assert.deepEqual(rows, expected);
  assert.ok(ticks > 10, `timers ran ${ticks} times during the worker's replay`);
  assert.ok(longest < blocked / 2, `longest gap ${longest} ms against ${blocked} ms inline`);
});
