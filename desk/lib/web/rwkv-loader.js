// RWKV loader for the %seer review page. See RWKV.md for the manifest
// format and the engine ABI. Any failure logs and leaves SM-2 in charge.
(function () {
  "use strict";

  var CONFIG_URL = "/~/scry/seer/rwkv.json";
  var POKE_URL = "/apps/seer/actions/rwkv-predictions";

  async function sha256Hex(bytes) {
    var digest = await crypto.subtle.digest("SHA-256", bytes);
    return Array.from(new Uint8Array(digest), function (b) {
      return b.toString(16).padStart(2, "0");
    }).join("");
  }

  async function fetchVerified(fetchFn, url, hex) {
    var res = await fetchFn(url);
    if (!res.ok) throw new Error("rwkv: fetch " + url + " " + res.status);
    var bytes = new Uint8Array(await res.arrayBuffer());
    var got = await sha256Hex(bytes);
    if (got !== String(hex).toLowerCase()) {
      throw new Error("rwkv: hash mismatch for " + url);
    }
    return bytes;
  }

  // rows: [{owner, stack, item, r}] with 0 <= r <= 1
  function pokeBody(config, rows, operationId) {
    var lines = [];
    rows.forEach(function (row) {
      if (!Number.isFinite(row.r)) return;
      var ppm = Math.round(Math.min(1, Math.max(0, row.r)) * 1e6);
      lines.push([row.owner, row.stack, row.item, ppm].join(","));
    });
    return new URLSearchParams({
      "idempotency-epoch": config.idempotency_epoch,
      "operation-id": operationId,
      head: String(config.head),
      r: lines.join("\n"),
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

  // deps: {fetch, engine, now}. Returns the poke body sent, or null.
  async function run(deps) {
    try {
      var config = await (await deps.fetch(CONFIG_URL)).json();
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
      var rows = engine.predict({ now_ms: deps.now(), events: config.revlog });
      var body = pokeBody(config, rows, "rwkv-" + config.head + "-" + deps.now());
      var res = await deps.fetch(POKE_URL, {
        method: "POST",
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

  if (typeof module === "object" && module.exports) {
    module.exports = { sha256Hex: sha256Hex, pokeBody: pokeBody, run: run };
    return;
  }
  run({
    fetch: function (url, init) {
      return fetch(url, Object.assign({ credentials: "include" }, init));
    },
    engine: wasmEngine,
    now: Date.now,
    base: location.href,
  }).then(function (body) {
    if (body && window.htmx) {
      htmx.ajax("GET", "/apps/seer/review", {
        target: "#seer-app", select: "#seer-app", swap: "outerHTML",
      });
    }
  });
})();
