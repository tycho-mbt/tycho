#!/usr/bin/env bash
# Golden/perf gate for the tycho 2D examples.
#
# Builds and runs examples 54-57 headless. Each example already contains pixel
# assertions; this script additionally enforces the perf harness thresholds
# (draws < prims, bounded path passes, non-zero uploads).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/.toolchain:$PATH"
EXAMPLES=(
  54-tycho-2d-showcase
  55-tycho-ui-gallery
  56-tycho-2d-text-stress
  57-tycho-2d-perf
  58-tycho-2d-svg-icons
  59-tycho-2d-emoji
  60-tycho-2d-i18n-text
  61-tycho-2d-msdf
)

cd "$ROOT/examples"
moon build --target native "${EXAMPLES[@]}"

BIN_DIR="$ROOT/_build/native/debug/build/laplaceliu/tycho_vulkan_examples"
for exe in "${EXAMPLES[@]}"; do
  out="$(timeout 300 "$BIN_DIR/$exe/$exe.exe" 2>&1)"
  echo "$out"
  if ! grep -q "] OK" <<<"$out"; then
    echo "2D GATE FAILED: $exe" >&2
    exit 1
  fi
done

json="$(timeout 300 "$BIN_DIR/57-tycho-2d-perf/57-tycho-2d-perf.exe" 2>&1 | grep '^{' | head -1)"
num() { sed -n "s/.*\"$1\":\([0-9]*\).*/\1/p" <<<"$json"; }
draws="$(num draws)"
passes="$(num path_passes)"
prims="$(num prims)"
uploads="$(num uploads)"
if [ -z "$draws" ] || [ -z "$passes" ] || [ -z "$prims" ] || [ -z "$uploads" ]; then
  echo "2D GATE FAILED: could not parse perf JSON: $json" >&2
  exit 1
fi
if [ "$draws" -ge "$prims" ]; then
  echo "2D GATE FAILED: draws=$draws prims=$prims" >&2
  exit 1
fi
if [ "$passes" -gt 80 ]; then
  echo "2D GATE FAILED: path_passes=$passes" >&2
  exit 1
fi
if [ "$uploads" -le 0 ]; then
  echo "2D GATE FAILED: uploads=$uploads" >&2
  exit 1
fi
# Shaping corpus vs HarfBuzz (default gate: the three baseline strings;
# --extended covers the wider Devanagari set).
moon build --target native shape-dump
python3 "$ROOT/tools/shape_corpus.py" \
  "$BIN_DIR/shape-dump/shape-dump.exe" --extended

# Window/IME smoke: run a couple of examples under Xvfb with --window and
# require zero validation errors (no pixel/golden assertion here).
if command -v xvfb-run >/dev/null 2>&1; then
  for exe in 54-tycho-2d-showcase 60-tycho-2d-i18n-text; do
    log="$(mktemp)"
    timeout 12 xvfb-run -a -s "-screen 0 1280x800x24" \
      "$BIN_DIR/$exe/$exe.exe" --window >"$log" 2>&1 || true
    if grep -q "VALIDATION ERROR" "$log"; then
      echo "2D GATE FAILED: $exe validation error under Xvfb" >&2
      cat "$log" >&2
      rm -f "$log"
      exit 1
    fi
    rm -f "$log"
  done
fi

echo "2D GATE OK: prims=$prims draws=$draws passes=$passes uploads=$uploads"
