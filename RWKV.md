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

Predictions are fresh while RWKV is enabled, their `head` equals the current `head` (see [Live revlog](#live-revlog)), their `artifact` equals the configured `artifact-hash`, and the ship received them less than 15 minutes ago (`rwkv-max-age`). The queue and the `fresh` field of the scry use the same rule. With fresh predictions the queue is:

1. cards with a prediction below `target`, ascending R;
2. then SM-2 due cards that have no prediction, in SM-2 order;
3. then, while the queue is shorter than `min-daily`, the lowest-R cards not yet in it.

The result is cut to its first `max-daily` cards. Neither field counts cards answered earlier in the day; both bound the queue as it stands.

Any new answer, and any change to which answers are live, changes `head`, so the stored predictions go stale until the browser sends new ones. They also go stale with age, because the engine predicts recall at the time it ran; without that bound, a card held back by a high score would stay out of the queue until the next answer. A `%rwkv-predictions` poke whose `head` is not the current one is rejected and stores nothing, so a batch computed before a card was deleted or recreated cannot be stored after it.

### Live revlog

The ship keeps every answer in its revlog. The replay uses only the answers of live card incarnations, as the fork's history query uses only answers of cards that still exist and drops a card's answers from before a reset:

- A card is live while it is an item in one of the ship's own stacks, the cards the queue schedules.
- An incarnation starts with its card's last `learn` answer, the first answer of a new or reset item.
- The incarnation's answers are live while the item's last review is that incarnation's newest answer. A deleted card has no live answers. A card recreated under a used name is a new card: none of the old card's answers are live, and it has none of its own until its first answer.

`head` is the low 52 bits of a hash of the live answers' ids, or `null` when there are none. Deleting a card that has answers, or answering any card, changes it. Adding a card, or deleting one never answered, leaves it alone: neither changes the replay.

## Loader

1. `GET /~/scry/seer/rwkv.json`. Fields: `enabled`, `target_ppm`, `max_daily`, `min_daily`, `artifact_url`, `artifact_hash` (64 hex chars), `head` (names the live revlog, or `null` when it is empty), `fresh`, `idempotency_epoch`, `now_ms` (the ship's time), and `revlog`, the [live revlog](#live-revlog): a list of `{id, owner, stack, item, grade, kind, shown_at, answered_at}` in id order, with times in Unix milliseconds. A non-2xx response stops the run.
2. Stop if disabled, unconfigured, `head` is `null`, or `fresh` is true.
3. Fetch the manifest and check its SHA-256 against `artifact_hash`.
4. Fetch the engine and weights named in the manifest and check each against its listed SHA-256.
5. Run the engine in a Web Worker: the loader starts `/apps/seer/rwkv-loader.js` itself as a worker, hands it the bytes checked in steps 3 and 4 and the revlog, and ends the worker when it answers. The replay never runs on the page thread. If any output row lacks a string `owner` starting with `~`, a non-empty `stack` or `item`, or an `r` in `[0, 1]`, or repeats an earlier row's card, drop the whole output.
6. POST the result to `/apps/seer/actions/rwkv-predictions`, with the `head` and `artifact_hash` of step 1. The ship rejects the batch if either is no longer current.

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

Input: `{"now_ms": <now_ms from the scry>, "events": <revlog from the scry>}`. `now_ms` is the ship's time, the clock the revlog uses, not the browser's. `predict` fails when `now_ms` is earlier than the newest `answered_at`: a query day before the last replayed day is outside the model's input domain and can give every card the same score.

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
| query | at `now_ms`, as the fork queries a card when it is shown: seconds since the card's last answer, and scheduler days since it, except for a card in the learning state, whose days the fork leaves unset so the model counts whole days of seconds. A card is learning after an `again` before its first `review`: `again` resets %seer's box to 0, so its next answer is a learning `relearn` (state 1). |

Each card's answers must be one incarnation, as the live revlog sends them: a `learn` answer only as the card's first. `predict` fails on an input with a later `learn` for a card. Replayed as the same card, a second learning start would put the card's cumulative elapsed time outside the model's input domain, and the shared deck, preset and global state would carry it to every card, which can collapse all scores to one plausible value.

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

`tools/build-rwkv-artifact [OUT]` writes to `OUT` (default `rwkv-engine/dist/`, not committed):

| file | what |
| --- | --- |
| `engine.wasm` | the engine |
| `weights.bin` | the weights; see [Weights: evaluation only](#weights-evaluation-only) |
| `manifest.json` | the two URLs and SHA-256s the loader checks |
| `LICENSE` | GNU AGPL v3, the engine's license |
| `NOTICE` | the engine's origin, upstream copyright and license statement, dated modification notice, and where its source is |
| `THIRD-PARTY-LICENSES` | the license files of every crate compiled into `engine.wasm`, from `Cargo.lock` |
| `rwkv-engine-source.tar` | the engine's Corresponding Source: `rwkv-engine/` (manifest, lock file, toolchain pin, `src/`, license and notices) and this build script |
| `WEIGHTS-NOTICE.md` | the upstream notice for the weights |

It prints the manifest SHA-256, the value for `artifact-hash`. It builds the engine with the toolchain pinned in `rwkv-engine/rust-toolchain.toml` and `Cargo.lock`, and downloads the weights, `sm98/weights.int8.bin` from the fork at commit `17c63ab7f985b11c013dc02b35d8606b5bb0a586` (tag `26.09.4+fsrs7.build.115`), refusing any file whose SHA-256 is not the one pinned in the script. Needs `rustup`, `curl`, GNU `tar`, and `sha256sum` or `shasum`.

The engine is reproducible in a clean environment: no `CARGO_PROFILE_*`, `CARGO_BUILD_*` (other than `CARGO_BUILD_JOBS`), `CARGO_TARGET_<triple>_*`, `CARGO_UNSTABLE_*`, `CARGO_INCREMENTAL`, `RUSTC`, `RUSTC_*` or `RUSTUP_TOOLCHAIN` in the environment, and no Cargo config that changes the release profile. There, every build of the same source writes the same `engine.wasm`, whose SHA-256 is pinned in `rwkv-engine/engine.wasm.sha256`, from any checkout path, spaces included. The script refuses those variables. It sets the rustflags itself, one path remap per encoded argument, so ambient `RUSTFLAGS` or an empty `CARGO_ENCODED_RUSTFLAGS` change nothing and no local path reaches the binary. When `engine.wasm` does not match the pin it stops before writing `manifest.json`. A change to the engine source needs a new pin, recorded from a clean build. The pin was recorded on Linux x86-64; another host that compiles different bytes fails the build instead of pinning them. Unpacking `rwkv-engine-source.tar` and running its `tools/build-rwkv-artifact` rebuilds the same `engine.wasm`. `tools/check-rwkv-build` checks these claims with full builds.

`rwkv-engine/parity/run.sh` refuses any weights file but the pinned one, builds the fork's own runtime at the pinned commit, writes its numbers to `PARITY_DIR/reference-r.json` (default `rwkv-engine/dist/parity/`), and runs this crate's tests against them. It then compares them with the committed golden, `rwkv-engine/tests/fixtures/reference-r.json`, and fails if they differ; `run.sh --replace` copies them over the golden, only after the tests pass. A failed fork build leaves the golden as it was. The tests check this engine against the fork in three ways, each failing above `1e-4` in R:

- Kernel parity: both runtimes on the same model rows, which this crate's adapter (`seer::plan`) builds from the synthetic revlog in `rwkv-engine/tests/fixtures/`. It compares each card's final R and the R the fork's historical warm-up predicts before each answer (the answer-time row with grade and duration cleared). It shows the model matches; it cannot catch a wrong translation, because both sides read the adapter's rows.
- Show time: kernel parity on the live query the loader would have sent for each answered card when it was shown, at `shown_at`, separate from the answer-time update. On the fixture the two differ by up to 2.4e-3 in R, so they are not interchangeable.
- Translation: `rwkv-engine/tests/fixtures/cases.json` holds %seer inputs with model rows written by hand from the fork's rules: learning and review queries across the 04:00 UTC rollover, the 15-minute box-one step, timestamp ties, the four answer states, and a rollover inside committed history. `cargo test --test translation`, which needs no weights, checks the adapter emits exactly those rows; the parity test checks this engine's R on each input against the fork's R on the hand-written rows.

`tools/verify-rwkv` is the required check. It builds the artifact into `rwkv-engine/dist/`, writes the native engine's output on the fixture beside it, runs the engine's tests against the committed fork numbers, and runs every Node test, which put the built artifact through the loader with a stubbed ship. It fails on any failure, missing input, or skipped test. Run alone, `node --test tools/*.test.mjs` fails when the artifact is missing; `RWKV_ARTIFACT_OPTIONAL=1` skips the artifact tests instead, for a local run that has not built it.

### Weights: evaluation only

`weights.bin` is byte for byte `rwkv-small-instant-only/weights.int8.bin` from the SM98 release [`rwkv-family-2026-11-13`](https://github.com/JSchoreels/anki-rwkv/releases/tag/rwkv-family-2026-11-13) of anki-rwkv (SHA-256 `b2f335bd712b9d602150201de41ab5a0f0a4c291644705e2aa1ed2a1bf1592c3`). That release ships [`WEIGHTS-NOTICE.md`](rwkv-engine/WEIGHTS-NOTICE.md), copied unchanged into `rwkv-engine/` and by the build into `OUT`. It says:

- the weights are not covered by the MIT License of the anki-rwkv code;
- whether models trained on the anki-revlogs-10k dataset may be redistributed and shipped in applications is an [open question upstream](https://github.com/open-spaced-repetition/srs-benchmark/issues/353);
- until that is settled, the weights are for personal and research use only, and the dataset's owners should be asked before the weights are shipped in an application.

Local evaluation means building the artifact and running it on your own machine: `rwkv-engine/parity/run.sh`, the Node tests, and the native examples. Serving `weights.bin` to browsers from any host is redistribution. Uploading your own copy to your own ship is redistribution too: the ship serves the file over HTTP like any other host.

This repository documents no way to publish the artifact. Do not publish `weights.bin` for others, or upload it to a ship, until permission is documented or weights under a license that allows it replace these. A matching SHA-256 proves which file a browser received; it grants no right to send it.

### Licenses

The engine is the fork's code and stays under AGPL-3.0-or-later. The fork's own `LICENSE` names the AGPL without its text, so `rwkv-engine/LICENSE` is the GNU AGPL v3 text and `NOTICE` quotes the fork's statement, names the upstream files, and dates the changes. Whoever serves `engine.wasm` to browsers conveys AGPL object code (sections 4 to 6). They must serve, from the same place, `LICENSE`, `NOTICE`, `THIRD-PARTY-LICENSES`, and `rwkv-engine-source.tar`, the Corresponding Source of that exact `engine.wasm`, and keep them there as long as they serve it. Hashes in the manifest do not replace any of these.

The weights carry no license from the fork, and the release that ships the same bytes limits them as above. This repository does not contain them: the build fetches them from the fork.
