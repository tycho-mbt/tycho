#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ -d "$PWD/.toolchain" ]; then
  export PATH="$PWD/.toolchain:$PATH"
fi
export PATH="$HOME/.moon/bin:$PATH"
exec moon build --target native "$@"
