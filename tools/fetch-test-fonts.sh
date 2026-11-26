#!/usr/bin/env bash
# Download optional M8.5 test fonts into testdata/fonts (git-ignored).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/testdata/fonts"
mkdir -p "$out"

fetch() {
  local url="$1" name="$2"
  if [ -f "$out/$name" ]; then
    echo "have $name"
    return
  fi
  echo "fetch $name"
  curl -L --fail --retry 3 -o "$out/$name" "$url"
}

# Noto fonts (SIL Open Font License 1.1).
fetch \
  "https://github.com/notofonts/arabic/raw/main/fonts/NotoNaskhArabic/hinted/ttf/NotoNaskhArabic-Regular.ttf" \
  "NotoNaskhArabic-Regular.ttf"
fetch \
  "https://github.com/notofonts/devanagari/raw/main/fonts/NotoSansDevanagari/hinted/ttf/NotoSansDevanagari-Regular.ttf" \
  "NotoSansDevanagari-Regular.ttf"

# Inter variable font (SIL Open Font License 1.1).
fetch \
  "https://github.com/rsms/inter/raw/master/docs/font-files/InterVariable.ttf" \
  "InterVariable.ttf"

echo "fonts in $out"
ls -lh "$out"
