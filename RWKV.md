# RWKV scheduling

%seer can order reviews by RWKV retrievability predictions computed in the browser. The ship stores the predictions; it never runs the model. When RWKV is off, or the predictions are missing or stale, the queue is the SM-2 queue.

## Configuration

`%set-rwkv-config` on the `%seer-action` mark sets:

| field | default | meaning |
| --- | --- | --- |
| `enabled` | `%.n` | use predictions when fresh |
| `target` | `.~0.9` | cards with predicted R below this are due |
| `max-daily` | `200` | cap on the whole queue, unpredicted SM-2 cards included |
| `min-daily` | `0` | pad with the lowest-R cards up to this many |
| `artifact-url` | `~` | manifest URL |
| `artifact-hash` | `~` | SHA-256 of the manifest bytes |

The ship rejects a config whose `target` is not a finite number in `[0, 1]`, whose `min-daily` exceeds `max-daily`, or whose `artifact-hash` is wider than 256 bits (receipt status `invalid`, reason `invalid-rwkv-config`), and keeps the previous config. It rejects a predictions batch with any probability outside `[0, 1]` (`invalid-predictions`), a stale `head` (`conflict`, `stale-predictions`), or an `artifact` other than the configured `artifact-hash` (`conflict`, `stale-artifact`), and keeps the stored predictions.

Stored predictions belong to the artifact that made them. A config that changes `artifact-url` or `artifact-hash` drops them; a change to `target`, `max-daily`, or `min-daily` keeps them.

The review page loads `/apps/seer/rwkv-loader.js` only when `enabled` is set and both artifact fields are present.

## Queue

Predictions are fresh while RWKV is enabled, their `head` equals the newest revlog id, their `artifact` equals the configured `artifact-hash`, and the ship received them less than 15 minutes ago (`rwkv-max-age`). The queue and the `fresh` field of the scry use the same rule. With fresh predictions the queue is:

1. cards with a prediction below `target`, ascending R;
2. then SM-2 due cards that have no prediction, in SM-2 order;
3. then, while the queue is shorter than `min-daily`, the lowest-R cards not yet in it.

The result is cut to its first `max-daily` cards. Neither field counts cards answered earlier in the day; both bound the queue as it stands.

Any new answer appends to the revlog, so the stored predictions go stale until the browser sends new ones. They also go stale with age, because the engine predicts recall at the time it ran; without that bound, a card held back by a high score would stay out of the queue until the next answer. A `%rwkv-predictions` poke whose `head` is not the newest revlog id is rejected and stores nothing.

## Loader

1. `GET /~/scry/seer/rwkv.json`. Fields: `enabled`, `target_ppm`, `max_daily`, `min_daily`, `artifact_url`, `artifact_hash` (64 hex chars), `head` (newest revlog id or `null`), `fresh`, `idempotency_epoch`, and `revlog`, a list of `{id, owner, stack, item, grade, kind, shown_at, answered_at}` with times in Unix milliseconds. A non-2xx response stops the run.
2. Stop if disabled, unconfigured, `head` is `null`, or `fresh` is true.
3. Fetch the manifest and check its SHA-256 against `artifact_hash`.
4. Fetch the engine and weights named in the manifest and check each against its listed SHA-256.
5. Run the engine. If any output row lacks a string `owner` starting with `~`, a non-empty `stack` or `item`, or an `r` in `[0, 1]`, drop the whole output.
6. POST the result to `/apps/seer/actions/rwkv-predictions`.

Any failure is logged with `console.warn` and nothing is sent.

Requests to the ship use `credentials: "same-origin"`. The manifest, engine, and weights are fetched with `credentials: "omit"`: they are public and pinned by hash, and a CDN that answers `Access-Control-Allow-Origin: *` cannot serve a credentialed request.

htmx runs the script again each time it swaps in a review view. One run is in flight per page. A request that arrives during a run waits, replacing any earlier waiting request, and gets one more run against the latest config and head when the current run ends. After a run the ship accepted (HTTP 200), the loader refreshes `#seer-app` only if the review view that made the latest request is still in the document, so a late result never replaces another page.

### Manifest

```json
{
  "engine":  { "url": "engine.wasm", "sha256": "<64 hex>" },
  "weights": { "url": "weights.bin", "sha256": "<64 hex>" }
}
```

URLs resolve relative to the manifest URL.

### Engine ABI

`engine.wasm` is instantiated with an empty import object and exports:

| export | signature | meaning |
| --- | --- | --- |
| `memory` | memory | linear memory |
| `alloc` | `(len: i32) -> i32` | pointer to `len` writable bytes |
| `load_weights` | `(ptr: i32, len: i32) -> i32` | load the weights; `0` on success |
| `predict` | `(ptr: i32, len: i32) -> i32` | run on UTF-8 JSON input; pointer to output, `0` on failure |
| `output_len` | `() -> i32` | byte length of the last `predict` output |

Input: `{"now_ms": <Unix ms>, "events": <revlog from the scry>}`.

Output: UTF-8 JSON `[{"owner": "~zod", "stack": "s1", "item": "c1", "r": 0.83}, ...]`, with `r` the predicted probability of recall now, in `[0, 1]`.

### Predictions POST

Form-encoded fields: `idempotency-epoch`, `operation-id`, `head`, `artifact` (the `artifact_hash` the loader verified the manifest against), and `predictions`, a JSON array of `{"owner": "~zod", "stack": "s1", "item": "c1", "ppm": 830000}`, where `ppm` is R in integer parts per million. `stack` and `item` are the strings from the scry, so any card key round-trips, including imported IDs that start with a digit.

The response is JSON, never a page:

| status | body | meaning |
| --- | --- | --- |
| `200` | operation receipt | stored, or identical to what was stored |
| `400` | `{"code": "invalid-predictions"}` or `{"code": "invalid-operation"}` | the batch or the operation fields did not parse; nothing is applied |
| `409` | operation receipt | the ship rejected the batch, e.g. a stale `head` or `artifact`; the stored predictions are unchanged |
