#!/usr/bin/env bash
# Gate: examples must stay pure MoonBit (no C stubs, no native-stub).
set -euo pipefail
cd "$(dirname "$0")"
fail=0
while IFS= read -r f; do
  echo "ERROR: C stub in examples: $f" >&2
  fail=1
done < <(find examples -name '*.c' -o -name '*.cc' -o -name '*.cpp')
while IFS= read -r pkg; do
  echo "ERROR: native-stub declared in an example moon.pkg: $pkg" >&2
  fail=1
done < <(grep -rl "native-stub" examples --include='moon.pkg')
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "examples pure MoonBit (no .c / native-stub)"
