#!/usr/bin/env python3
"""Compare shape-dump output against HarfBuzz.

Usage:
  shape_compare.py <shape-dump.exe> <font.ttf> <text> [size_px]
"""
import json
import subprocess
import sys


def run_json(cmd):
    out = subprocess.check_output(cmd, text=True)
    return json.loads(out)


def utf8_to_cp_clusters(text):
    """HarfBuzz reports UTF-8 byte offsets; Paragraph uses codepoint indices."""
    mapping = {}
    byte_off = 0
    for i, ch in enumerate(text):
        mapping[byte_off] = i
        byte_off += len(ch.encode("utf-8"))
    mapping[byte_off] = len(text)
    return mapping


def main():
    if len(sys.argv) < 4:
        print(
            "usage: shape_compare.py <shape-dump.exe> <font.ttf> <text> [size_px]",
            file=sys.stderr,
        )
        sys.exit(2)
    dump, font, text = sys.argv[1], sys.argv[2], sys.argv[3]
    size = sys.argv[4] if len(sys.argv) >= 5 else "48"
    wght = sys.argv[5] if len(sys.argv) >= 6 else None
    ours_cmd = [dump, font, text, size]
    ref_cmd = ["python3", "tools/hb_reference.py", font, text, size]
    if wght is not None:
        ours_cmd.append(wght)
        ref_cmd.append(wght)
    ours = run_json(ours_cmd)
    ref = run_json(ref_cmd)
    a = ours["glyphs"]
    b = ref["glyphs"]
    clusters = utf8_to_cp_clusters(text)
    ok = len(a) == len(b)
    diffs = []
    if ok:
        for i, (x, y) in enumerate(zip(a, b)):
            ref_cluster = clusters.get(y["cluster"], y["cluster"])
            if (
                x["gid"] != y["gid"]
                or x["cluster"] != ref_cluster
                or abs(x["advance"] - y["advance"]) > 0.05
            ):
                ok = False
                diffs.append(
                    {
                        "i": i,
                        "our": [x["gid"], x["cluster"], round(x["advance"], 3)],
                        "ref": [y["gid"], ref_cluster, round(y["advance"], 3)],
                    }
                )
    print(
        json.dumps(
            {
                "ok": ok,
                "backend": ref.get("backend"),
                "our_count": len(a),
                "ref_count": len(b),
                "diffs": diffs[:20],
            },
            ensure_ascii=False,
            separators=(",", ":"),
        )
    )
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
