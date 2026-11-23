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

The review page loads `/apps/seer/rwkv-loader.js` only when `enabled` is set and both artifact fields are present.

## Queue

Predictions are fresh while RWKV is enabled, their `head` equals the newest revlog id, and the ship received them less than 15 minutes ago (`rwkv-max-age`). The queue and the `fresh` field of the scry use the same rule. With fresh predictions the queue is:

1. cards with a prediction below `target`, ascending R;
2. then SM-2 due cards that have no prediction, in SM-2 order;
3. then, while the queue is shorter than `min-daily`, the lowest-R cards not yet in it.

The result is cut to its first `max-daily` cards. Neither field counts cards answered earlier in the day; both bound the queue as it stands.

Any new answer appends to the revlog, so the stored predictions go stale until the browser sends new ones. They also go stale with age, because the engine predicts recall at the time it ran; without that bound, a card held back by a high score would stay out of the queue until the next answer. A `%rwkv-predictions` poke whose `head` is not the newest revlog id is rejected and stores nothing.

## Loader

1. `GET /~/scry/seer/rwkv.json`. Fields: `enabled`, `target_ppm`, `max_daily`, `min_daily`, `artifact_url`, `artifact_hash` (64 hex chars), `head` (newest revlog id or `null`), `fresh`, `idempotency_epoch`, and `revlog`, a list of `{id, owner, stack, item, grade, kind, shown_at, answered_at}` with times in Unix milliseconds.
2. Stop if disabled, unconfigured, `head` is `null`, or `fresh` is true.
3. Fetch the manifest and check its SHA-256 against `artifact_hash`.
4. Fetch the engine and weights named in the manifest and check each against its listed SHA-256.
5. Run the engine and POST the result to `/apps/seer/actions/rwkv-predictions`.

Any failure is logged with `console.warn` and nothing is sent.

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

Form-encoded fields: `idempotency-epoch`, `operation-id`, `head`, and `predictions`, a JSON array of `{"owner": "~zod", "stack": "s1", "item": "c1", "ppm": 830000}`, where `ppm` is R in integer parts per million. `stack` and `item` are the strings from the scry, so any card key round-trips, including imported IDs that start with a digit.

The response is JSON, never a page:

| status | body | meaning |
| --- | --- | --- |
| `200` | operation receipt | stored, or identical to what was stored |
| `400` | `{"code": "invalid-predictions"}` or `{"code": "invalid-operation"}` | the batch or the operation fields did not parse; nothing is applied |
| `409` | operation receipt | the ship rejected the batch, e.g. a stale `head`; the stored predictions are unchanged |
