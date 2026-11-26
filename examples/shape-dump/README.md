# shape-dump

Development tool: prints `PlacedGlyph` gid/cluster/advance as JSON for comparison
with HarfBuzz. Not part of the 2D gate.

```sh
moon build --target native shape-dump
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/shape-dump/shape-dump.exe \
  /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf fi

# Reference + comparison (from the repository root)
python3 tools/hb_reference.py /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf fi
python3 tools/shape_compare.py <path-to-shape-dump.exe> \
  /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf fi
```
