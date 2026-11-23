import assert from "node:assert/strict";
import { createRequire } from "node:module";
import test from "node:test";

const { run, scheduler, sha256Hex } = createRequire(import.meta.url)("../desk/lib/web/rwkv-loader.js");

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
    head: 3, fresh: false, idempotency_epoch: "~2026.9.2", now_ms: 1000,
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
      assert.equal(input.now_ms, 1000, "the engine queries at the ship's time");
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
    const body = await run({ fetch, engine: stubEngine, base: "http://ship/" });
    assert.equal(body, null);
  } finally {
    console.warn = warn;
  }
  assert.deepEqual(posts, []);
});

for (const name of ["engine.wasm", "weights.bin"]) {
  test(`${name} bytes the manifest does not pin never reach the engine`, async () => {
    const served = await files(await sha256Hex(await manifestBytes()));
    served[`https://cdn.example/rwkv/${name}`] = bytes("tampered");
    const { fetch, posts } = stubFetch(served);
    let engineCalls = 0;
    const engine = async () => {
      engineCalls++;
      return { predict: () => [] };
    };
    const [body, warnings] = await quiet(() => run({ fetch, engine, base: "http://ship/" }));
    assert.equal(body, null);
    assert.equal(engineCalls, 0);
    assert.deepEqual(posts, []);
    assert.match(warnings[0], new RegExp(`hash mismatch for .*${name}`));
  });
}

test("verified artifact with stub engine pokes predictions", async () => {
  const hash = await sha256Hex(await manifestBytes());
  const { fetch, posts } = stubFetch(await files(hash));
  await run({ fetch, engine: stubEngine, base: "http://ship/" });
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
    { ...good, item: "" }, { ...good, owner: "zod" }, null, { ...good, r: 0.25 },
  ];
  for (const bad of bads) {
    const { fetch, posts } = stubFetch(await files(await sha256Hex(await manifestBytes())));
    const [body, warnings] = await quiet(() =>
      run({ fetch, engine: engineOf([good, bad]), base: "http://ship/" }));
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
    run({ fetch, engine: stubEngine, base: "http://ship/" }));
  assert.equal(body, null);
  assert.deepEqual(stub.requests, []);
  assert.match(warnings[0], /config 503/);
});

// the request init of each fetch, POST bodies left out
const inits = (requests) => requests.map(({ url, init }) =>
  [url, init?.credentials, ...(init?.redirect ? [init.redirect] : [])]);

test("artifacts off the ship's store are fetched without cookies", async () => {
  const hash = await sha256Hex(await manifestBytes());
  const { fetch, requests } = stubFetch(await files(hash));
  await run({ fetch, engine: stubEngine, base: "http://ship/" });
  assert.deepEqual(inits(requests), [
    ["/~/scry/seer/rwkv.json", "same-origin"],
    ["https://cdn.example/rwkv/manifest.json", "omit"],
    ["https://cdn.example/rwkv/engine.wasm", "omit"],
    ["https://cdn.example/rwkv/weights.bin", "omit"],
    ["/apps/seer/actions/rwkv-predictions", "same-origin"],
  ]);
  // same-origin paths that are not the manifest's own store entry
  for (const artifactUrl of [
    "/rwkv/manifest.json",
    `/apps/seer/rwkv/${hash}/`,
    `/apps/seer/rwkv/${hash}?v=1`,
    `/apps/seer/rwkv/${"0".repeat(64)}`,
    `http://other.ship/apps/seer/rwkv/${hash}`,
  ]) {
    const stub = stubFetch({ "/~/scry/seer/rwkv.json": { ...config(hash), artifact_url: artifactUrl } });
    await quiet(() => run({ fetch: stub.fetch, engine: stubEngine, base: "http://ship/apps/seer/review" }));
    assert.deepEqual(inits(stub.requests).slice(1), [[new URL(artifactUrl, "http://ship/").href, "omit"]],
      artifactUrl);
  }
});

// The ship's artifact store as the ship answers it: a request without the
// owner's session cookie gets 403.
async function shipStore(manifest) {
  manifest ??= await manifestBytes();
  const hash = await sha256Hex(manifest);
  const blobs = {};
  for (const blob of [manifest, engineBytes, weightBytes]) {
    blobs[`http://ship/apps/seer/rwkv/${await sha256Hex(blob)}`] = blob;
  }
  const stub = stubFetch({
    "/~/scry/seer/rwkv.json": { ...config(hash), artifact_url: `/apps/seer/rwkv/${hash}` },
    ...blobs,
  });
  const fetch = async (url, init) => {
    if (url in blobs && (init?.credentials ?? "same-origin") === "omit") {
      stub.requests.push({ url, init });
      return { ok: false, status: 403 };
    }
    return stub.fetch(url, init);
  };
  return { ...stub, fetch, hash };
}

test("a manifest in the ship's store loads each file from the store by sha-256, with the cookie and no redirect", async () => {
  const ship = await shipStore();
  const [body, warnings] = await quiet(() =>
    run({ fetch: ship.fetch, engine: stubEngine, base: "http://ship/apps/seer/review" }));
  assert.deepEqual(warnings, []);
  assert.notEqual(body, null);
  assert.equal(ship.posts.length, 1);
  assert.deepEqual(inits(ship.requests), [
    ["/~/scry/seer/rwkv.json", "same-origin"],
    [`http://ship/apps/seer/rwkv/${ship.hash}`, "same-origin", "error"],
    [`http://ship/apps/seer/rwkv/${await sha256Hex(engineBytes)}`, "same-origin", "error"],
    [`http://ship/apps/seer/rwkv/${await sha256Hex(weightBytes)}`, "same-origin", "error"],
    ["/apps/seer/actions/rwkv-predictions", "same-origin"],
  ]);
});

test("a digest that is not 64 hex digits is never fetched", async () => {
  // in the config: nothing past the config read
  for (const artifactHash of ["../actions/rwkv-predictions", "ab".repeat(31), `${"ab".repeat(32)}/`, 7]) {
    const ship = await shipStore();
    const fetch = async (url, init) => url === "/~/scry/seer/rwkv.json"
      ? { ok: true, json: async () => ({ ...config(ship.hash), artifact_url: "/rwkv/m.json", artifact_hash: artifactHash }) }
      : ship.fetch(url, init);
    const [body, warnings] = await quiet(() =>
      run({ fetch, engine: stubEngine, base: "http://ship/apps/seer/review" }));
    assert.equal(body, null);
    assert.deepEqual(ship.requests, [], String(artifactHash));
    assert.match(warnings[0], /not a sha-256/);
  }
  // in a stored manifest: nothing past the manifest
  for (const sha256 of ["../../actions/rwkv-predictions", `..%2F${"0".repeat(58)}`, undefined]) {
    const ship = await shipStore(bytes(JSON.stringify({
      engine: { url: "engine.wasm", sha256 },
      weights: { url: "weights.bin", sha256: await sha256Hex(weightBytes) },
    })));
    const [body, warnings] = await quiet(() =>
      run({ fetch: ship.fetch, engine: stubEngine, base: "http://ship/apps/seer/review" }));
    assert.equal(body, null);
    assert.deepEqual(inits(ship.requests).map(([url]) => url), [
      "/~/scry/seer/rwkv.json", `http://ship/apps/seer/rwkv/${ship.hash}`,
    ], String(sha256));
    assert.match(warnings[0], /not a sha-256/);
  }
});

// Holds the first weights fetch until release(); atWeights settles when a
// run is parked there.
async function heldRun() {
  const hash = await sha256Hex(await manifestBytes());
  const served = await files(hash);
  const stub = stubFetch(served);
  let release;
  let parked;
  const gate = new Promise((resolve) => { release = resolve; });
  const atWeights = new Promise((resolve) => { parked = resolve; });
  let held = false;
  const fetch = async (url, init) => {
    if (url.endsWith("/weights.bin") && !held) {
      held = true;
      parked();
      await gate;
    }
    return stub.fetch(url, init);
  };
  const refreshes = [];
  const request = scheduler({
    fetch, engine: stubEngine, base: "http://ship/",
    refresh: () => refreshes.push(true),
  });
  const setHead = (head) => { served["/~/scry/seer/rwkv.json"] = { ...config(hash), head }; };
  return { request, release, atWeights, posts: stub.posts, refreshes, setHead };
}

const postedHeads = (posts) => posts.map((p) => new URLSearchParams(p.body).get("head"));

test("a run that outlives its review view posts but does not refresh", async () => {
  const held = await heldRun();
  const view = { isConnected: true };
  const done = held.request(view);
  await held.atWeights;
  view.isConnected = false;
  held.release();
  await done;
  assert.deepEqual(postedHeads(held.posts), ["3"]);
  assert.deepEqual(held.refreshes, []);
});

test("requests during a run coalesce into one rerun at the latest head", async () => {
  const held = await heldRun();
  const views = [{ isConnected: true }, { isConnected: true }, { isConnected: true }];
  const done = held.request(views[0]);
  await held.atWeights;
  held.setHead(4);
  views[0].isConnected = false;
  held.request(views[1]);
  views[1].isConnected = false;
  held.request(views[2]);
  held.release();
  await done;
  assert.deepEqual(postedHeads(held.posts), ["3", "4"]);
  assert.deepEqual(held.refreshes, [true]);
});
