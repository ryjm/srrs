#!/usr/bin/env bash
# Runs the fork's own RWKV runtime at the pinned commit on the fixtures,
# writing its numbers to PARITY_DIR/reference-r.json, and runs this crate's
# tests against them. Then compares them with the committed golden,
# tests/fixtures/reference-r.json: identical passes; different fails, unless
# --replace is given, which copies them over the golden after the tests pass.
# Needs git, protoc, and the pinned weights from tools/build-rwkv-artifact.
# The fork pins its own toolchain; FORK_TOOLCHAIN overrides it for the fork
# build only.
set -euo pipefail

UPSTREAM=https://github.com/JSchoreels/anki
UPSTREAM_COMMIT=17c63ab7f985b11c013dc02b35d8606b5bb0a586 # tag 26.09.4+fsrs7.build.115

replace=
case ${1:-} in
  --replace) replace=1 ;;
  '') ;;
  *) echo "usage: parity/run.sh [--replace]" >&2; exit 2 ;;
esac

engine=$(cd "$(dirname "$0")/.." && pwd)
work=${PARITY_DIR:-$engine/dist/parity}
fork=$work/anki
weights=${RWKV_WEIGHTS:-$engine/dist/weights.bin}
fixtures=$engine/tests/fixtures
golden=$fixtures/reference-r.json

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1"; else shasum -a 256 "$1"; fi | cut -d' ' -f1
}
want=$(sed -n 's/^WEIGHTS_SHA256=//p' "$engine/../tools/build-rwkv-artifact")
got=$(sha256 "$weights")
if [ "$got" != "$want" ]; then
  echo "$weights has SHA-256 $got, not the pinned weights $want" >&2
  exit 1
fi

mkdir -p "$work"
if [ ! -d "$fork/.git" ]; then
  git clone --quiet --filter=blob:none --no-checkout "$UPSTREAM" "$fork"
fi
git -C "$fork" checkout --quiet "$UPSTREAM_COMMIT"
git -C "$fork" submodule update --quiet --init --depth 1 ftl/core-repo ftl/qt-repo

(cd "$engine" && cargo run --quiet --locked --release --example plan -- "$fixtures/revlog.json") \
  >"$work/plan.json"

# A bin, not an example: examples pull in the fork's dev-dependencies.
cp -f "$engine/parity/reference.rs" "$fork/rslib/src/bin/seer_rwkv_reference.rs"
rm -f "$work/reference-r.json"
(
  cd "$fork"
  if [ -n "${FORK_TOOLCHAIN:-}" ]; then export RUSTUP_TOOLCHAIN=$FORK_TOOLCHAIN; fi
  PROTOC=${PROTOC:-$(command -v protoc)} CARGO_TARGET_DIR=$work/target \
    cargo run --quiet --locked --release -p anki --bin seer_rwkv_reference -- \
    "$weights" "$work/plan.json" "$fixtures/cases.json"
) >"$work/reference-r.json.part"
mv -f "$work/reference-r.json.part" "$work/reference-r.json"

(cd "$engine" && RWKV_WEIGHTS=$weights RWKV_REFERENCE=$work/reference-r.json \
  cargo test --locked --release -- --nocapture)

if cmp -s "$work/reference-r.json" "$golden"; then
  echo "the fork's numbers equal the committed golden"
elif [ -n "$replace" ]; then
  cp -f "$work/reference-r.json" "$golden"
  echo "replaced $golden"
else
  echo "the fork's numbers differ from $golden; rerun with --replace to keep them" >&2
  exit 1
fi
