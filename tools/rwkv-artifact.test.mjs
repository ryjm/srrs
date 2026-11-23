// The real artifact through the loader: tools/build-rwkv-artifact writes it
// to rwkv-engine/dist (or RWKV_ARTIFACT_DIR), and rwkv-engine/parity/run.sh
// adds native-r.json, the native engine's output. Only fetch and the ship
// are stubbed.
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { createRequire } from "node:module";
import test from "node:test";

const require = createRequire(import.meta.url);
const { run, sha256Hex, wasmEngine } = require("../desk/lib/web/rwkv-loader.js");

const dir = process.env.RWKV_ARTIFACT_DIR ??
  new URL("../rwkv-engine/dist/", import.meta.url).pathname;
const fixtures = new URL("../rwkv-engine/tests/fixtures/", import.meta.url);
const skip = !existsSync(`${dir}/manifest.json`) && `no artifact in ${dir}: run tools/build-rwkv-artifact`;
const skipNative = skip || (!existsSync(`${dir}/native-r.json`) &&
  `no native-r.json in ${dir}: run rwkv-engine/parity/run.sh`);

const read = (name) => new Uint8Array(readFileSync(`${dir}/${name}`));
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
async function stubShip(revlog, head) {
  const manifestBytes = read("manifest.json");
  const artifactHash = await sha256Hex(manifestBytes);
  const files = {
    "/~/scry/seer/rwkv.json": {
      enabled: true, target_ppm: 900000, max_daily: 200, min_daily: 0,
      artifact_url: "https://cdn.example/rwkv/manifest.json", artifact_hash: artifactHash,
      head, fresh: false, idempotency_epoch: "~2026.9.2", revlog,
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
  const { fetch, posts, artifactHash } = await stubShip(events, head);
  const body = await run({ fetch, engine: wasmEngine, now: () => now_ms, base: "https://ship.example/" });
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
  const { fetch, posts } = await stubShip(withRetired, 3);
  const body = await quiet(() =>
    run({ fetch, engine: wasmEngine, now: () => at.now_ms, base: "https://ship.example/" }));
  assert.equal(body, null);
  assert.equal(posts.length, 0, "a retired incarnation in the input posts nothing");

  const rows = engine.predict({ ...at, events: live });
  assert.equal(new Set(rows.map((row) => row.r)).size, 3, JSON.stringify(rows));
  assert.deepEqual(engine.predict({ ...at, events: [] }), [], "recreated, not yet answered: no score");
});

test("real artifact: wasm R equals the native engine and the fork", { skip: skipNative }, async () => {
  const engine = await wasmEngine(read("engine.wasm"), read("weights.bin"));
  const rows = engine.predict({ now_ms, events });
  for (const row of rows) assert.ok(row.r >= 0 && row.r <= 1, JSON.stringify(row));
  const native = JSON.parse(readFileSync(`${dir}/native-r.json`));
  const vsNative = maxDiff(rows, native);
  const vsFork = maxDiff(rows, fork);
  console.log(`max |wasm - native| R = ${vsNative}; max |wasm - fork| R = ${vsFork}; ${rows.length} cards`);
  assert.ok(vsNative <= 1e-6, `wasm vs native: ${vsNative}`);
  assert.ok(vsFork <= 1e-4, `wasm vs fork: ${vsFork}`);
});
