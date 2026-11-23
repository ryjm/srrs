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
5. Run the engine. If any output row lacks a string `owner` starting with `~`, a non-empty `stack` or `item`, or an `r` in `[0, 1]`, or repeats an earlier row's card, drop the whole output.
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

A buffer from `alloc` belongs to the call it is passed to; `load_weights` and `predict` free it.

Input: `{"now_ms": <Unix ms>, "events": <revlog from the scry>}`.

Output: UTF-8 JSON `[{"owner": "~zod", "stack": "s1", "item": "c1", "r": 0.83}, ...]`, with `r` the predicted probability of recall now, in `[0, 1]`, one row per card in the revlog.

### Replay

The engine in `rwkv-engine/` runs RWKV-Instant model SM98 from the Anki fork [JSchoreels/anki](https://github.com/JSchoreels/anki) ("the fork"; commit in [Artifact](#artifact)). It was trained on Anki revlog rows, so each predict replays the whole scry revlog as Anki rows, from a fresh state, in `answered_at` order (ties by `id`), then asks for each card's recall at `now_ms`:

| model input | from the scry |
| --- | --- |
| card | one id per `owner`/`stack`/`item`; its note is itself |
| deck | one id per `owner`/`stack`; one preset for all |
| rating | `again` 1, `hard` 2, `good` 3, `easy` 4 |
| answer time | `answered_at - shown_at`, capped at 60 s like Anki's default |
| day | Unix time rolled over at 04:00 UTC; the scry has no time zone |
| elapsed time | since the card's previous answer, in days and seconds; none on its first answer |
| state | `learn` 0 (learning start); `relearn` 1 before the card's first `review` (Anki's later learning step), 3 after; `review` 2; `manual` 5 |
| query | at `now_ms`: elapsed time since the card's last answer, as the fork does for the time a card is shown |

State is kept in f32; the fork's desktop default quantizes it to save memory across sessions, which a run that replays and discards does not need.

### Predictions POST

Form-encoded fields: `idempotency-epoch`, `operation-id`, `head`, `artifact` (the `artifact_hash` the loader verified the manifest against), and `predictions`, a JSON array of `{"owner": "~zod", "stack": "s1", "item": "c1", "ppm": 830000}`, where `ppm` is R in integer parts per million. `stack` and `item` are the strings from the scry, so any card key round-trips, including imported IDs that start with a digit. A batch that names the same card twice does not parse.

The response is JSON, never a page:

| status | body | meaning |
| --- | --- | --- |
| `200` | operation receipt | stored, or identical to what was stored |
| `400` | `{"code": "invalid-predictions"}` or `{"code": "invalid-operation"}` | the batch or the operation fields did not parse; nothing is applied |
| `409` | operation receipt | the ship rejected the batch, e.g. a stale `head` or `artifact`; the stored predictions are unchanged |

## Artifact

`tools/build-rwkv-artifact [OUT]` writes `engine.wasm`, `weights.bin` and `manifest.json` to `OUT` (default `rwkv-engine/dist/`, not committed) and prints the manifest SHA-256, the value for `artifact-hash`. It builds the engine with the toolchain pinned in `rwkv-engine/rust-toolchain.toml` and `Cargo.lock`, and downloads the weights, `sm98/weights.int8.bin` from the fork at commit `17c63ab7f985b11c013dc02b35d8606b5bb0a586` (tag `26.09.4+fsrs7.build.115`), refusing any file whose SHA-256 is not the one pinned in the script. Two builds from the same commit give the same bytes. Needs `rustup`, `curl` and `sha256sum` or `shasum`.

To host it, put the three files in one directory on any static host that answers with `Access-Control-Allow-Origin: *`, then poke `%set-rwkv-config` with `artifact-url` set to the URL of `manifest.json` and `artifact-hash` set to the printed hash. The loader checks every file against the hashes, so the host does not need to be trusted, only reachable.

`rwkv-engine/parity/run.sh` checks the engine against the fork: it builds the fork's own runtime at the pinned commit, runs it and this engine on the synthetic revlog in `rwkv-engine/tests/fixtures/`, and fails if any card's final R, or the R predicted before any answer, differs by more than `1e-4`. `node --test tools/rwkv-artifact.test.mjs` then runs the built artifact through the loader with a stubbed ship.

### Licenses

The engine is the fork's code and stays under AGPL-3.0-or-later; its source is `rwkv-engine/`. The fork's own `LICENSE` names the AGPL without its text, so `rwkv-engine/LICENSE` is the GNU AGPL v3 text and `NOTICE` quotes the fork's statement and names the upstream files. Whoever serves `engine.wasm` to browsers distributes AGPL object code and must offer that source.

The weights carry no stated license. This repository does not contain or redistribute them: the build fetches them from the fork. An operator who hosts `weights.bin` redistributes them.
