#!/usr/bin/env bash
# CI zero-diff check: regenerate bindings and fail if they differ from committed.
set -euo pipefail
cd "$(dirname "$0")"
./generate.sh >/dev/null

# Every file codegen/main.mbt writes. Keep this in sync when it grows a new
# output; the untracked-file check below catches the case where we forget.
generated="vulkan/enums.mbt vulkan/types.mbt vulkan/dispatch.mbt \
vulkan/dispatch_stub.c vulkan/structs.mbt vulkan/structs_stub.c"

dirty=0
if ! git diff --quiet -- $generated; then
  dirty=1
fi
# A brand-new generated file would be untracked rather than modified, so the
# diff above stays quiet and drift would slip through unnoticed.
new_files=$(git ls-files --others --exclude-standard -- 'vulkan/*.mbt' 'vulkan/*.c' || true)
if [ -n "$new_files" ]; then
  dirty=1
fi

if [ "$dirty" -eq 0 ]; then
  echo "generated code in sync (zero diff)"
else
  echo "ERROR: generated code differs from committed — run ./generate.sh and commit" >&2
  git diff --stat -- $generated >&2
  if [ -n "$new_files" ]; then
    echo "unexpected untracked generated files:" >&2
    echo "$new_files" | sed 's/^/  /' >&2
  fi
  exit 1
fi
