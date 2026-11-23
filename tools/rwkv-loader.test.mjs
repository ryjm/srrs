import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";

const { run, sha256Hex } = createRequire(import.meta.url)("../desk/lib/web/rwkv-loader.js");

const bytes = (text) => new TextEncoder().encode(text);
const engineBytes = bytes("engine");
const weightBytes = bytes("weights");

async function manifestBytes() {
  return bytes(JSON.stringify({
    engine: { url: "engine.wasm", sha256: await sha256Hex(engineBytes) },
    weights: { url: "weights.bin", sha256: await sha256Hex(weightBytes) },
  }));
}

function config(artifactHash) {
  return {
    enabled: true, target_ppm: 900000, max_daily: 200, min_daily: 0,
    artifact_url: "https://cdn.example/rwkv/manifest.json", artifact_hash: artifactHash,
    head: 3, fresh: false, idempotency_epoch: "~2026.9.2",
    revlog: [{ id: 3, owner: "~zod", stack: "s1", item: "c1", grade: "good" }],
  };
}

function stubFetch(files) {
  const posts = [];
  const requests = [];
  const fetch = async (url, init) => {
    requests.push({ url, init });
    if (init?.method === "POST") {
      posts.push({ url, body: init.body });
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
  return { fetch, posts, requests };
}

async function quiet(fn) {
  const warn = console.warn;
  const warnings = [];
  console.warn = (err) => warnings.push(String(err));
  try {
    return [await fn(), warnings];
  } finally {
    console.warn = warn;
  }
}

async function files(artifactHash) {
  return {
    "/~/scry/seer/rwkv.json": config(artifactHash),
    "https://cdn.example/rwkv/manifest.json": await manifestBytes(),
    "https://cdn.example/rwkv/engine.wasm": engineBytes,
    "https://cdn.example/rwkv/weights.bin": weightBytes,
  };
}

const stubEngine = async (engine, weights) => {
  assert.deepEqual(engine, engineBytes);
  assert.deepEqual(weights, weightBytes);
  return {
    predict: (input) => {
      assert.equal(input.events.length, 1);
      return [
        { owner: "~zod", stack: "s1", item: "c1", r: 0.25 },
        { owner: "~zod", stack: "s1", item: "0v5-q3les-klmn1", r: 0.9123456 },
      ];
    },
  };
};

const engineOf = (rows) => async () => ({ predict: () => rows });

test("manifest hash mismatch never pokes", async () => {
  const { fetch, posts } = stubFetch(await files("00".repeat(32)));
  const warn = console.warn;
  console.warn = () => {};
  try {
    const body = await run({ fetch, engine: stubEngine, now: () => 1000, base: "http://ship/" });
    assert.equal(body, null);
  } finally {
    console.warn = warn;
  }
  assert.deepEqual(posts, []);
});

test("verified artifact with stub engine pokes predictions", async () => {
  const hash = await sha256Hex(await manifestBytes());
  const { fetch, posts } = stubFetch(await files(hash));
  await run({ fetch, engine: stubEngine, now: () => 1000, base: "http://ship/" });
  assert.equal(posts.length, 1);
  assert.equal(posts[0].url, "/apps/seer/actions/rwkv-predictions");
  const fields = Object.fromEntries(new URLSearchParams(posts[0].body));
  assert.deepEqual({ ...fields, predictions: JSON.parse(fields.predictions) }, {
    "idempotency-epoch": "~2026.9.2",
    "operation-id": "rwkv-3-1000",
    head: "3",
    artifact: hash,
    predictions: [
      { owner: "~zod", stack: "s1", item: "c1", ppm: 250000 },
      { owner: "~zod", stack: "s1", item: "0v5-q3les-klmn1", ppm: 912346 },
    ],
  });
});

test("one invalid engine row rejects the whole batch", async () => {
  const good = { owner: "~zod", stack: "s1", item: "c1", r: 0.5 };
  const bads = [
    { ...good, r: null }, { ...good, r: 1.25 }, { ...good, r: -0.1 }, { ...good, r: NaN },
    { ...good, item: "" }, { ...good, owner: "zod" }, null,
  ];
  for (const bad of bads) {
    const { fetch, posts } = stubFetch(await files(await sha256Hex(await manifestBytes())));
    const [body, warnings] = await quiet(() =>
      run({ fetch, engine: engineOf([good, bad]), now: () => 1000, base: "http://ship/" }));
    assert.equal(body, null, JSON.stringify(bad));
    assert.deepEqual(posts, [], JSON.stringify(bad));
    assert.match(warnings[0], /bad engine row 1/);
  }
});

test("a failed config fetch stops before any artifact fetch", async () => {
  const hash = await sha256Hex(await manifestBytes());
  const stub = stubFetch(await files(hash));
  const fetch = async (url, init) => url === "/~/scry/seer/rwkv.json"
    ? { ok: false, status: 503, json: async () => config(hash) }
    : stub.fetch(url, init);
  const [body, warnings] = await quiet(() =>
    run({ fetch, engine: stubEngine, now: () => 1000, base: "http://ship/" }));
  assert.equal(body, null);
  assert.deepEqual(stub.requests, []);
  assert.match(warnings[0], /config 503/);
});

test("artifact fetches omit credentials; ship requests stay same-origin", async () => {
  const { fetch, requests } = stubFetch(await files(await sha256Hex(await manifestBytes())));
  await run({ fetch, engine: stubEngine, now: () => 1000, base: "http://ship/" });
  assert.deepEqual(requests.map(({ url, init }) => [url, init?.credentials]), [
    ["/~/scry/seer/rwkv.json", "same-origin"],
    ["https://cdn.example/rwkv/manifest.json", "omit"],
    ["https://cdn.example/rwkv/engine.wasm", "omit"],
    ["https://cdn.example/rwkv/weights.bin", "omit"],
    ["/apps/seer/actions/rwkv-predictions", "same-origin"],
  ]);
});
