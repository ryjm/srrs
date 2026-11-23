#!/usr/bin/env bash
# Regenerates tests/fixtures/reference-r.json with the fork's own RWKV
# runtime at the pinned commit, then runs this crate's tests against it.
# Needs git, protoc, and the weights from tools/build-rwkv-artifact. The fork
# pins its own toolchain; FORK_TOOLCHAIN overrides it for the fork build only.
set -euo pipefail

UPSTREAM=https://github.com/JSchoreels/anki
UPSTREAM_COMMIT=17c63ab7f985b11c013dc02b35d8606b5bb0a586 # tag 26.09.4+fsrs7.build.115

engine=$(cd "$(dirname "$0")/.." && pwd)
work=${PARITY_DIR:-$engine/dist/parity}
fork=$work/anki
weights=${RWKV_WEIGHTS:-$engine/dist/weights.bin}
fixture=$engine/tests/fixtures/revlog.json

mkdir -p "$work"
if [ ! -d "$fork/.git" ]; then
  git clone --quiet --filter=blob:none --no-checkout "$UPSTREAM" "$fork"
fi
git -C "$fork" checkout --quiet "$UPSTREAM_COMMIT"
git -C "$fork" submodule update --quiet --init --depth 1 ftl/core-repo ftl/qt-repo

(cd "$engine" && cargo run --quiet --locked --release --example plan -- "$fixture") >"$work/plan.json"
# tools/rwkv-artifact.test.mjs compares the wasm engine against this.
(cd "$engine" && cargo run --quiet --locked --release --example predict -- "$weights" "$fixture") \
  >"$(dirname "$weights")/native-r.json"

# A bin, not an example: examples pull in the fork's dev-dependencies.
cp -f "$engine/parity/reference.rs" "$fork/rslib/src/bin/seer_rwkv_reference.rs"
(
  cd "$fork"
  if [ -n "${FORK_TOOLCHAIN:-}" ]; then export RUSTUP_TOOLCHAIN=$FORK_TOOLCHAIN; fi
  PROTOC=${PROTOC:-$(command -v protoc)} CARGO_TARGET_DIR=$work/target \
    cargo run --quiet --locked --release -p anki --bin seer_rwkv_reference -- \
    "$weights" "$work/plan.json"
) >"$engine/tests/fixtures/reference-r.json"

cd "$engine"
RWKV_WEIGHTS=$weights cargo test --locked --release -- --nocapture
