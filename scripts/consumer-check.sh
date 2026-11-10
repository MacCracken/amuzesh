#!/usr/bin/env bash
#
# consumer-check.sh — prove dist/amuzesh.cyr is the library a downstream repo can use.
#
# amuzesh's consumable product is dist/amuzesh.cyr (`cyrius distlib`). `cyrius distlib
# --check` proves the committed bundle is current with src/; this proves the rest:
#
#   1. Raw include. tests/amuzesh_raw_include.tcyr includes only lib/ganita.cyr and
#      lib/tyche.cyr (the named deps a consumer declares), the bundle, and the test
#      framework. Built with --no-deps, those includes are the only source in scope, which
#      is a consumer's real situation, so a bundle that needs a leaf it does not declare
#      fails here. It must build without warnings and pass.
#   2. The whole unit suite and the fuzz harness, regenerated with their src/ include block
#      replaced by the bundle. Every assertion, the bit-exact known answers included, and
#      every fuzz round must hold against what consumers actually get, not just against src/.
#
# Usage: scripts/consumer-check.sh [workdir]   (default: build/.consumer-check)
set -euo pipefail

cd "$(dirname "$0")/.."
OUT="${1:-build/.consumer-check}"
mkdir -p "$OUT"
[ -f dist/amuzesh.cyr ] || { echo "FAIL: no dist/amuzesh.cyr; run 'cyrius distlib'" >&2; exit 1; }

echo "== raw include, --no-deps: tests/amuzesh_raw_include.tcyr"
if ! out=$(cyrius build --no-deps tests/amuzesh_raw_include.tcyr "$OUT/raw_include" 2>&1); then
    printf '%s\n' "$out" >&2
    echo "FAIL: the bundle does not compile from a raw include" >&2; exit 1
fi
if printf '%s\n' "$out" | grep -q '^warning:'; then
    printf '%s\n' "$out" | grep '^warning:' >&2
    echo "FAIL: the raw-include build emitted compiler warnings" >&2; exit 1
fi
"$OUT/raw_include"

# Swap a harness's src/ include block for the one bundle include, keeping everything else
# (the lib/ganita.cyr + lib/tyche.cyr lines above it stay: they are the consumer's deps).
swap() {
    awk 'BEGIN { done = 0 }
         /^include "src\// { if (!done) { print "include \"dist/amuzesh.cyr\""; done = 1 } next }
         { print }' "$1" > "$2"
    grep -qx 'include "dist/amuzesh.cyr"' "$2" || { echo "FAIL: $1 has no src/ include block" >&2; exit 1; }
    if grep -q '^include "src/' "$2"; then echo "FAIL: $2 still includes src/" >&2; exit 1; fi
}

# Compile quietly ($3 = 1 eliminates dead code, as CI's fuzz build does); show the
# compiler's output only when it fails.
build() {
    local out
    out=$(CYRIUS_DCE="${3:-0}" cyrius build "$1" "$2" 2>&1) \
        || { printf '%s\n' "$out" >&2; echo "FAIL: $1 does not compile" >&2; exit 1; }
}

swap tests/amuzesh.tcyr "$OUT/bundle_suite.tcyr"
echo "== unit suite against the bundle"
build "$OUT/bundle_suite.tcyr" "$OUT/bundle_suite"
"$OUT/bundle_suite" | tail -1

swap tests/amuzesh.fcyr "$OUT/bundle_fuzz.fcyr"
echo "== fuzz harness against the bundle"
build "$OUT/bundle_fuzz.fcyr" "$OUT/bundle_fuzz" 1
timeout 120 "$OUT/bundle_fuzz" | tail -1

echo "consumer-check: ok"
