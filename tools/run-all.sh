#!/usr/bin/env bash
# Run all pure-Vulkan verification examples on both lavapipe and default (NVIDIA) drivers.
# Gate fails if exit code != 0 OR output contains "FAIL".
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_DIR="_build/native/debug/build/laplaceliu/tycho_vulkan_examples"
LVP_ICD="/usr/share/vulkan/icd.d/lvp_icd.x86_64.json"
[ -f "$LVP_ICD" ] || LVP_ICD="/usr/share/vulkan/icd.d/lvp_icd.json"
DRIVER="${1:-both}"

run_suite() {
  local drv="$1"
  local fail=0
  local pass=0
  echo "================ DRIVER: $drv ================"
  for d in examples/*/; do
    name=$(basename "$d")
    exe="$BUILD_DIR/$name/$name.exe"
    if [ ! -x "$exe" ]; then
      echo "  MISSING  $name ($exe)"
      fail=$((fail + 1))
      continue
    fi
    local out=""
    local rc=0
    if [ "$drv" = "lavapipe" ]; then
      out=$(VK_DRIVER_FILES="$LVP_ICD" timeout 60 "$exe" 2>&1) || rc=$?
    else
      out=$(env -u VK_DRIVER_FILES timeout 60 "$exe" 2>&1) || rc=$?
    fi
    if [ "$rc" -ne 0 ] || echo "$out" | grep -qE '\bFAIL\b'; then
      echo "  FAIL     $name (rc=$rc)"
      echo "$out" | tail -n 10 | sed 's/^/           /'
      fail=$((fail + 1))
    else
      local summary
      summary=$(echo "$out" | tail -n 1)
      echo "  OK       $name  |  $summary"
      pass=$((pass + 1))
    fi
  done
  echo "[$drv] passed=$pass failed=$fail"
  return $fail
}

rc=0
if [ "$DRIVER" = "both" ] || [ "$DRIVER" = "lavapipe" ]; then
  run_suite lavapipe || rc=1
fi
if [ "$DRIVER" = "both" ] || [ "$DRIVER" = "nvidia" ]; then
  run_suite nvidia || rc=1
fi
exit $rc
