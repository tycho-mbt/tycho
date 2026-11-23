#!/usr/bin/env bash
# Regenerate MoonBit Vulkan bindings from vendored codegen/registry/vk.xml.
set -euo pipefail
cd "$(dirname "$0")"
if [ -d "$PWD/.toolchain" ]; then
  export PATH="$PWD/.toolchain:$PATH"
fi
export PATH="$HOME/.moon/bin:$PATH"
# Build codegen first so broken generated output cannot block regeneration.
moon build --target native codegen >/dev/null
./_build/native/debug/build/laplaceliu/tycho_codegen/tycho_codegen.exe "$@"
moon build --target native vulkan >/dev/null
echo "regenerated and rebuilt laplaceliu/tycho_vulkan OK"
