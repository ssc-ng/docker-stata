#!/bin/bash
# Smoke tests for the sscng/stata* Docker images.
#
# The library-loading checks run with no license and catch regressions like
# issue #32 (missing libtinfo.so.5). The checks that actually execute Stata
# code -- do-file, graph export, PyStata -- REQUIRE a valid Stata license
# file: pass one with -l, otherwise those checks are skipped.
#
# Usage:
#   tests/run-tests.sh -i <image> [-l <stata.lic>]
#
#   -i   image reference to test, e.g. sscng/stata18-mp:2026-06-02
#   -l   path to a Stata license file (stata.lic). Optional.
#   -h   this help
#
# Exit status is non-zero if any check fails.

set -u

usage() { sed -n '2,/^$/ s/^# \{0,1\}//p' "$0"; exit "${1:-0}"; }

IMAGE=""
LICENSE=""
while getopts "i:l:h" flag; do
    case "$flag" in
        i) IMAGE=$OPTARG ;;
        l) LICENSE=$OPTARG ;;
        h) usage 0 ;;
        *) usage 2 ;;
    esac
done
[[ -z $IMAGE ]] && { echo "ERROR: -i <image> is required" >&2; usage 2; }

TESTDIR=$(cd "$(dirname "$0")" && pwd)
fail=0
pass() { printf 'PASS  %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fail=1; }
skip() { printf 'SKIP  %s (%s)\n' "$1" "$2"; }

# Which Stata binary does this image ship?
STATABIN=$(docker run --rm --entrypoint /bin/bash "$IMAGE" -c \
    'for b in stata-mp stata-se stata; do [ -x /usr/local/stata/$b ] && { echo "$b"; break; }; done')
[[ -z $STATABIN ]] && { echo "ERROR: no stata binary found in $IMAGE" >&2; exit 1; }

echo "image:  $IMAGE"
echo "binary: $STATABIN"
echo

# --- 1. shared libraries resolve (no license) -- catches issue #32
missing=$(docker run --rm --entrypoint /bin/bash "$IMAGE" -c \
    "ldd /usr/local/stata/$STATABIN 2>/dev/null | grep 'not found' || true")
if [[ -z $missing ]]; then
    pass "shared libraries resolve for $STATABIN"
else
    bad "shared libraries missing for $STATABIN:"
    echo "$missing" | sed 's/^/      /'
fi

# --- 2. binary starts without a dynamic-loader error (no license)
out=$(docker run --rm --entrypoint /bin/bash "$IMAGE" -c \
    "$STATABIN -q -b 'display 1' 2>&1; true")
if grep -q 'error while loading shared libraries' <<<"$out"; then
    bad "binary fails to load: $(grep 'error while loading' <<<"$out")"
else
    pass "binary starts (no dynamic-loader error)"
fi

# --- license-dependent checks
if [[ -z $LICENSE ]]; then
    skip "run test.do"  "no license; pass -l <stata.lic>"
    skip "graph export" "no license; pass -l <stata.lic>"
    skip "PyStata"      "no license; pass -l <stata.lic>"
    echo
    [[ $fail -eq 0 ]] && echo "OK (library checks only)" || echo "FAILURES"
    exit $fail
fi
[[ -f $LICENSE ]] || { echo "ERROR: license file not found: $LICENSE" >&2; exit 1; }
LICENSE=$(cd "$(dirname "$LICENSE")" && pwd)/$(basename "$LICENSE")

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp "$TESTDIR/test.do" "$TESTDIR/pystata.do" "$WORK/"
chmod -R 777 "$WORK"

run_do() {  # <dofile>
    docker run --rm \
        -v "$LICENSE":/usr/local/stata/stata.lic:ro \
        -v "$WORK":/project -w /project \
        --entrypoint "$STATABIN" "$IMAGE" -b do "$1" >/dev/null 2>&1
}

# --- 3. run test.do
run_do test.do
if grep -q '^DOFILE_OK' "$WORK/test.log" 2>/dev/null \
   && ! grep -qE '^r\([0-9]+\);' "$WORK/test.log"; then
    pass "run test.do (regress, assert, putexcel)"
else
    bad "run test.do -- tail of log:"
    tail -20 "$WORK/test.log" 2>/dev/null | sed 's/^/      /'
fi

# --- 4. graph export artifacts
if [[ -s $WORK/test-graph.png && -s $WORK/test-graph.pdf ]] \
   && file "$WORK/test-graph.png" | grep -q 'PNG image'; then
    pass "graph export (png + pdf)"
else
    bad "graph export produced no valid artifacts"
fi

# --- 5. PyStata (only if the image ships python3)
if docker run --rm --entrypoint /bin/bash "$IMAGE" -c 'command -v python3 >/dev/null'; then
    run_do pystata.do
    if grep -q '^PYSTATA_DOFILE_OK' "$WORK/pystata.log" 2>/dev/null \
       && grep -q '^PYSTATA_OK' "$WORK/pystata.log"; then
        pass "PyStata (sfi bridge)"
    else
        bad "PyStata -- tail of log:"
        tail -20 "$WORK/pystata.log" 2>/dev/null | sed 's/^/      /'
    fi
else
    skip "PyStata" "image has no python3"
fi

echo
[[ $fail -eq 0 ]] && echo "OK" || echo "FAILURES"
exit $fail
