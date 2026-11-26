# 60 — i18n text

M8 integration example mixing:

- Latin with the `fi` -> `ﬁ` presentation-form ligature
- CJK fallback (DroidSansFallbackFull)
- color Emoji (NotoColorEmoji via CBDT)
- Hebrew RTL visual order
- Arabic joining forms (Presentation Forms-B)
- Justified paragraph, selection boxes and caret
- Synthetic bold + italic (3x3 dilation + vertical shear)
- SDF glyphs for text >= 48px (`kind=8`, fixed 64px base + scaling)
- Devanagari pre-base matra reorder + half/cjct features
- Inline images and text on a curved path (rotated coverage bitmaps)

The fallback chain is DejaVuSans -> DroidSansFallbackFull -> NotoColorEmoji.
Latin ligatures use GSUB `liga` with glyph-id rendering; Arabic uses GSUB
`init/medi/fina/isol` joining plus `rlig` (lam-alef), with Presentation Forms-B
as fallback; GPOS `kern` is applied by glyph id. Indic clusters and full
UAX #9 remain future work.

## Run

```sh
cd tycho/examples
moon build --target native 60-tycho-2d-i18n-text
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/60-tycho-2d-i18n-text/60-tycho-2d-i18n-text.exe
```

## Screenshot

![60-tycho-2d-i18n-text screenshot](./screenshot.png)

> Runs headless by default. Pass `--window` for interactive display or
> `--screenshot <path>` to capture PNG.

Sample output:

```json
{"ligature":true,"arabic_forms":7,"rtl_first":1501,"selection_boxes":1,"bold_italic":true,"sdf_glyphs":6,"devanagari":true,"inline_image":true,"text_on_path":true,"yellow_pixels":3000}
[60-tycho-2d-i18n-text] OK — Latin ligature + CJK + emoji + Hebrew RTL + Arabic joining + Devanagari + inline image + text-on-path + synthetic bold/italic + SDF, 7 Arabic forms, 6 SDF glyphs, 0 validation errors
```
