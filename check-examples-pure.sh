#!/usr/bin/env bash
# Gate: examples must stay pure MoonBit (no C stubs, no native-stub).
set -euo pipefail
cd "$(dirname "$0")"
fail=0
for f in examples/*/*/*.c; do
  [ -e "$f" ] || continue
  echo "ERROR: C stub in examples: $f" >&2
  fail=1
done
if grep -rl "native-stub" examples/*/*/moon.pkg >/dev/null 2>&1; then
  echo "ERROR: native-stub declared in an example moon.pkg" >&2
  grep -rl "native-stub" examples/*/*/moon.pkg >&2
  fail=1
fi
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "examples pure MoonBit (no .c / native-stub)"
