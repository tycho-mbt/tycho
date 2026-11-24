#!/usr/bin/env bash
# Run all pure-MoonBit verification examples on lavapipe and/or NVIDIA drivers.
# Gate fails if exit code != 0, output contains "FAIL", or an example reports OK
# while verifying zero commands ("OK — 0 …" / "commands=0") — a vacuous pass.
# "SKIP" (driver lacks the required extensions) is counted separately and passes.
#
# Overrides:
#   TYCHO_EXAMPLES_DIR   directory holding the built example binaries
#   TYCHO_LAVAPIPE_ICD   lavapipe ICD json (default: probe /usr/share/vulkan/icd.d)
#   VK_LAYER_PATH / VK_ADD_LAYER_PATH  respected if already set
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR="${TYCHO_EXAMPLES_DIR:-_build/native/debug/build/laplaceliu/tycho_vulkan_examples}"
if [ ! -d "$BUILD_DIR" ]; then
  echo "ERROR: $BUILD_DIR not found — run ./build.sh first (or set TYCHO_EXAMPLES_DIR)." >&2
  exit 1
fi

LVP_ICD="${TYCHO_LAVAPIPE_ICD:-}"
if [ -z "$LVP_ICD" ]; then
  for cand in /usr/share/vulkan/icd.d/lvp_icd.x86_64.json /usr/share/vulkan/icd.d/lvp_icd.json; do
    if [ -f "$cand" ]; then
      LVP_ICD="$cand"
      break
    fi
  done
fi

# Validation layers: follow the SDK the shell is configured for, then probe the
# conventional per-user install, instead of hardcoding one machine's path.
if [ -z "${VK_LAYER_PATH:-}" ] && [ -z "${VK_ADD_LAYER_PATH:-}" ]; then
  for cand in "${VULKAN_SDK:-}/share/vulkan/explicit_layer.d" \
              ${HOME:+"$HOME"/VulkanSDK/*/x86_64/share/vulkan/explicit_layer.d}; do
    if [ -d "$cand" ]; then
      export VK_LAYER_PATH="$cand"
      break
    fi
  done
fi

DRIVER="${1:-both}"
SKIP_LIST=" ${TYCHO_SKIP:-} "

run_suite() {
  local drv="$1"
  local fail=0
  local pass=0
  local skip=0
  echo "================ DRIVER: $drv ================"
  if [ "$drv" = "lavapipe" ] && [ -z "$LVP_ICD" ]; then
    echo "ERROR: lavapipe ICD not found (install mesa-vulkan-drivers or set TYCHO_LAVAPIPE_ICD)." >&2
    return 1
  fi
  for d in examples/*/; do
    [ -f "${d}moon.pkg" ] || continue
    name=$(basename "$d")
    case "$SKIP_LIST" in
      *" $name "*)
        echo "  SKIP     $name (TYCHO_SKIP)"
        skip=$((skip + 1))
        continue
        ;;
    esac
    exe="$BUILD_DIR/$name/$name.exe"
    if [ ! -x "$exe" ]; then
      echo "  MISSING  $name ($exe)"
      fail=$((fail + 1))
      continue
    fi
    out=""
    rc=0
    if [ "$drv" = "lavapipe" ]; then
      out=$(VK_DRIVER_FILES="$LVP_ICD" timeout 60 "$exe" 2>&1) || rc=$?
    else
      out=$(env -u VK_DRIVER_FILES timeout 60 "$exe" 2>&1) || rc=$?
    fi
    if [ "$rc" -ne 0 ] || echo "$out" | grep -qE '\bFAIL\b'; then
      echo "  FAIL     $name (rc=$rc)"
      echo "$out" | tail -n 10 | sed 's/^/           /'
      fail=$((fail + 1))
    elif echo "$out" | grep -qE '\bSKIP\b'; then
      # Example explicitly reports that this driver lacks the extensions it needs:
      # honest "not verified here", not a pass and not a failure.
      summary=$(echo "$out" | grep -E '\bSKIP\b' | tail -n 1)
      echo "  SKIP     $name  |  $summary"
      skip=$((skip + 1))
    elif echo "$out" | grep -qE 'OK — 0 |commands=0 '; then
      # Vacuous-pass guard: an example must never claim OK while verifying zero
      # commands (that is what made 32/33/35 look green on lavapipe).
      echo "  FAIL     $name (empty coverage: OK with 0 commands)"
      echo "$out" | tail -n 10 | sed 's/^/           /'
      fail=$((fail + 1))
    else
      summary=$(echo "$out" | tail -n 1)
      echo "  OK       $name  |  $summary"
      pass=$((pass + 1))
    fi
  done
  echo "[$drv] passed=$pass failed=$fail skipped=$skip"
  return $fail
}

rc=0
case "$DRIVER" in
  both | lavapipe | nvidia) ;;
  *)
    echo "Usage: $0 [both|lavapipe|nvidia]" >&2
    exit 2
    ;;
esac
if [ "$DRIVER" = "both" ] || [ "$DRIVER" = "lavapipe" ]; then
  run_suite lavapipe || rc=1
fi
if [ "$DRIVER" = "both" ] || [ "$DRIVER" = "nvidia" ]; then
  run_suite nvidia || rc=1
fi
exit $rc
