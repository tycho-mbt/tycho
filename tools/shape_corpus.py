#!/usr/bin/env python3
"""Run shape-dump vs HarfBuzz over a small script corpus.

Usage: shape_corpus.py <shape-dump.exe>
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CASES = [
    ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", ["fi", "ffi", "AV", "با", "שלום"]),
    (
        "/usr/share/fonts/truetype/lohit-devanagari/Lohit-Devanagari.ttf",
        ["नमस्ते", "कि", "स्ते"],
    ),
]

# M8.5.3 reordering/reph gaps are visible here; not part of the default gate.
EXTRA_DEVA = [
    "कर्म",
    "श्रद्धा",
    "प्रेम",
    "हिन्दी",
    "संस्कृत",
    "राष्ट्र",
    "क्षेत्र",
    "ज्ञान",
    "द्वार",
    "स्त्री",
]


def main():
    if len(sys.argv) < 2:
        print("usage: shape_corpus.py <shape-dump.exe>", file=sys.stderr)
        sys.exit(2)
    dump = sys.argv[1]
    cases = list(CASES)
    if "--extended" in sys.argv:
        cases[-1] = (cases[-1][0], cases[-1][1] + EXTRA_DEVA)
    failed = []
    passed = 0
    for font, texts in cases:
        if not os.path.exists(font):
            print(f"skip missing font {font}")
            continue
        for text in texts:
            cmd = [
                sys.executable,
                os.path.join(ROOT, "tools", "shape_compare.py"),
                dump,
                font,
                text,
            ]
            try:
                out = subprocess.check_output(cmd, text=True, cwd=ROOT)
                res = json.loads(out)
                if res.get("ok"):
                    passed += 1
                else:
                    failed.append((font, text, res))
                    print(f"FAIL {os.path.basename(font)} {text!r}: {out.strip()}")
            except subprocess.CalledProcessError as exc:
                failed.append((font, text, exc.output))
                print(f"FAIL {os.path.basename(font)} {text!r}: {exc.output}")
    print(json.dumps({"passed": passed, "failed": len(failed)}, separators=(",", ":")))
    sys.exit(0 if not failed else 1)


if __name__ == "__main__":
    main()
