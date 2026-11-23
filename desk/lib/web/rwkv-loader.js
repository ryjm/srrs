// RWKV loader for the %seer review page. See RWKV.md for the manifest
// format and the engine ABI. Any failure logs and leaves SM-2 in charge.
(function () {
  "use strict";

  var CONFIG_URL = "/~/scry/seer/rwkv.json";
  var POKE_URL = "/apps/seer/actions/rwkv-predictions";
  // this script; as a Web Worker it runs the engine (serveEngine)
  var LOADER_URL = "/apps/seer/rwkv-loader.js";

  async function sha256Hex(bytes) {
    var digest = await crypto.subtle.digest("SHA-256", bytes);
    return Array.from(new Uint8Array(digest), function (b) {
      return b.toString(16).padStart(2, "0");
    }).join("");
  }

  // artifacts are public and hash-pinned: no cookies, so a CDN serving
  // Access-Control-Allow-Origin: * can answer
  async function fetchVerified(fetchFn, url, hex) {
    var res = await fetchFn(url, { credentials: "omit" });
    if (!res.ok) throw new Error("rwkv: fetch " + url + " " + res.status);
    var bytes = new Uint8Array(await res.arrayBuffer());
    var got = await sha256Hex(bytes);
    if (got !== String(hex).toLowerCase()) {
      throw new Error("rwkv: hash mismatch for " + url);
    }
    return bytes;
  }

  // rows: the engine output, [{owner, stack, item, r}]. One row without a
  // card key, with r outside [0, 1], or repeating a card rejects the batch.
  function pokeBody(config, rows, operationId) {
    if (!Array.isArray(rows)) throw new Error("rwkv: engine output is not a list");
    var seen = new Set();
    var predictions = rows.map(function (row, i) {
      var ok = row !== null && typeof row === "object" &&
        typeof row.owner === "string" && row.owner.charAt(0) === "~" &&
        typeof row.stack === "string" && row.stack !== "" &&
        typeof row.item === "string" && row.item !== "" &&
        typeof row.r === "number" && row.r >= 0 && row.r <= 1;
      var key = ok && JSON.stringify([row.owner, row.stack, row.item]);
      if (!ok || seen.has(key)) {
        throw new Error("rwkv: bad engine row " + i + ": " + JSON.stringify(row));
      }
      seen.add(key);
      return {
        owner: row.owner, stack: row.stack, item: row.item,
        ppm: Math.round(row.r * 1e6),
      };
    });
    return new URLSearchParams({
      "idempotency-epoch": config.idempotency_epoch,
      "operation-id": operationId,
      head: String(config.head),
      artifact: config.artifact_hash,
      predictions: JSON.stringify(predictions),
    }).toString();
  }

  async function wasmEngine(engineBytes, weightBytes) {
    var mod = await WebAssembly.instantiate(engineBytes, {});
    var x = mod.instance.exports;
    var enc = new TextEncoder();
    function put(bytes) {
      var ptr = x.alloc(bytes.length);
      new Uint8Array(x.memory.buffer, ptr, bytes.length).set(bytes);
      return ptr;
    }
    if (x.load_weights(put(weightBytes), weightBytes.length) !== 0) {
      throw new Error("rwkv: engine rejected weights");
    }
    return {
      predict: function (input) {
        var bytes = enc.encode(JSON.stringify(input));
        var out = x.predict(put(bytes), bytes.length);
        if (out === 0) throw new Error("rwkv: engine predict failed");
        var text = new TextDecoder().decode(
          new Uint8Array(x.memory.buffer, out, x.output_len()),
        );
        return JSON.parse(text);
      },
    };
  }

  // The engine in a Web Worker, so a long replay never blocks the page.
  // makeWorker() returns a worker running serveEngine; it gets the bytes
  // run() already checked against the manifest, and serves one prediction.
  function workerEngine(makeWorker) {
    return async function (engineBytes, weightBytes) {
      return {
        predict: function (input) {
          return new Promise(function (resolve, reject) {
            var worker = makeWorker();
            worker.onmessage = function (e) {
              worker.terminate();
              if (e.data.error) reject(new Error(e.data.error));
              else resolve(e.data.rows);
            };
            worker.onerror = function (e) {
              worker.terminate();
              reject(new Error("rwkv: engine worker: " + (e && e.message)));
            };
            worker.postMessage({ engine: engineBytes, weights: weightBytes, input: input });
          });
        },
      };
    };
  }

  // The worker side of workerEngine; scope is the worker's global.
  function serveEngine(scope) {
    scope.onmessage = async function (e) {
      try {
        var engine = await wasmEngine(e.data.engine, e.data.weights);
        scope.postMessage({ rows: engine.predict(e.data.input) });
      } catch (err) {
        scope.postMessage({ error: String((err && err.message) || err) });
      }
    };
  }

  // deps: {fetch, engine, now}. Returns the poke body sent, or null.
  async function run(deps) {
    try {
      var configRes = await deps.fetch(CONFIG_URL, { credentials: "same-origin" });
      if (!configRes.ok) throw new Error("rwkv: config " + configRes.status);
      var config = await configRes.json();
      if (!config.enabled || !config.artifact_url || !config.artifact_hash) return null;
      if (config.head === null || config.fresh) return null;
      var base = new URL(config.artifact_url, deps.base);
      var manifest = JSON.parse(new TextDecoder().decode(
        await fetchVerified(deps.fetch, base.href, config.artifact_hash),
      ));
      var engineBytes = await fetchVerified(
        deps.fetch, new URL(manifest.engine.url, base).href, manifest.engine.sha256,
      );
      var weightBytes = await fetchVerified(
        deps.fetch, new URL(manifest.weights.url, base).href, manifest.weights.sha256,
      );
      var engine = await deps.engine(engineBytes, weightBytes);
      var rows = await engine.predict({ now_ms: deps.now(), events: config.revlog });
      var body = pokeBody(config, rows, "rwkv-" + config.head + "-" + deps.now());
      var res = await deps.fetch(POKE_URL, {
        method: "POST",
        credentials: "same-origin",
        headers: { "content-type": "application/x-www-form-urlencoded" },
        body: body,
      });
      if (!res.ok) throw new Error("rwkv: poke " + res.status);
      return body;
    } catch (err) {
      console.warn(err);
      return null;
    }
  }

  // One run at a time per page. A request that arrives during a run waits,
  // replacing any earlier waiting request; when the run ends, one more run
  // serves it against the latest config and head. The page refreshes only
  // if some run was accepted and the latest requesting review view is
  // still in the document. deps: run's deps plus refresh().
  function scheduler(deps) {
    var busy = null;
    var next = null;
    async function loop(view) {
      var accepted = false;
      for (;;) {
        if (await run(deps)) accepted = true;
        if (!next) break;
        view = next;
        next = null;
      }
      busy = null;
      if (accepted && view.isConnected) deps.refresh();
    }
    return function request(view) {
      if (busy) {
        next = view;
        return busy;
      }
      busy = loop(view);
      return busy;
    };
  }

  if (typeof WorkerGlobalScope !== "undefined" && self instanceof WorkerGlobalScope) {
    serveEngine(self);
    return;
  }
  if (typeof module === "object" && module.exports) {
    module.exports = {
      sha256Hex: sha256Hex, pokeBody: pokeBody, run: run, scheduler: scheduler,
      wasmEngine: wasmEngine, workerEngine: workerEngine, serveEngine: serveEngine,
    };
    return;
  }
  // htmx re-runs this script each time it swaps in a review view
  if (!window.seerRwkvRequest) {
    window.seerRwkvRequest = scheduler({
      fetch: window.fetch.bind(window),
      engine: workerEngine(function () { return new Worker(LOADER_URL); }),
      now: Date.now,
      base: location.href,
      refresh: function () {
        if (!window.htmx) return;
        htmx.ajax("GET", "/apps/seer/review", {
          target: "#seer-app", select: "#seer-app", swap: "outerHTML",
        });
      },
    });
  }
  var script = document.currentScript;
  var view = script && script.closest("[data-review]");
  if (view) window.seerRwkvRequest(view);
})();
