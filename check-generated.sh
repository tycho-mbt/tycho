#!/usr/bin/env bash
# CI zero-diff check: regenerate bindings and fail if they differ from committed.
set -euo pipefail
cd "$(dirname "$0")"
./generate.sh >/dev/null
if git diff --quiet -- vulkan/enums.mbt vulkan/types.mbt vulkan/dispatch.mbt vulkan/dispatch_stub.c vulkan/structs.mbt vulkan/structs_stub.c; then
  echo "generated code in sync (zero diff)"
else
  echo "ERROR: generated code differs from committed — run ./generate.sh and commit" >&2
  git diff --stat -- vulkan/ >&2
  exit 1
fi
