#!/usr/bin/env python3
"""HarfBuzz reference shaper.

Uses python uharfbuzz when available; otherwise calls libharfbuzz.so.0 through
ctypes. This is a development/CI reference only, never a runtime dependency.

Usage: hb_reference.py <font.ttf> <text> [size_px]
"""
import ctypes
import ctypes.util
import json
import sys


class HbGlyphInfo(ctypes.Structure):
    _fields_ = [
        ("codepoint", ctypes.c_uint32),
        ("mask", ctypes.c_uint32),
        ("cluster", ctypes.c_uint32),
        ("var1", ctypes.c_uint32),
        ("var2", ctypes.c_uint32),
    ]


class HbGlyphPosition(ctypes.Structure):
    _fields_ = [
        ("x_advance", ctypes.c_int32),
        ("y_advance", ctypes.c_int32),
        ("x_offset", ctypes.c_int32),
        ("y_offset", ctypes.c_int32),
        ("var", ctypes.c_int32),
    ]


def shape_ctypes(font_path, text, size):
    lib_name = ctypes.util.find_library("harfbuzz") or "libharfbuzz.so.0"
    hb = ctypes.CDLL(lib_name)
    hb.hb_blob_create_from_file.argtypes = [ctypes.c_char_p]
    hb.hb_blob_create_from_file.restype = ctypes.c_void_p
    hb.hb_face_create.argtypes = [ctypes.c_void_p, ctypes.c_uint]
    hb.hb_face_create.restype = ctypes.c_void_p
    hb.hb_font_create.argtypes = [ctypes.c_void_p]
    hb.hb_font_create.restype = ctypes.c_void_p
    hb.hb_font_set_scale.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
    hb.hb_buffer_create.restype = ctypes.c_void_p
    hb.hb_buffer_add_utf8.argtypes = [
        ctypes.c_void_p,
        ctypes.c_char_p,
        ctypes.c_int,
        ctypes.c_uint,
        ctypes.c_int,
    ]
    hb.hb_buffer_guess_segment_properties.argtypes = [ctypes.c_void_p]
    hb.hb_shape.argtypes = [
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_uint,
    ]
    hb.hb_buffer_get_glyph_infos.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_uint),
    ]
    hb.hb_buffer_get_glyph_infos.restype = ctypes.POINTER(HbGlyphInfo)
    hb.hb_buffer_get_glyph_positions.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_uint),
    ]
    hb.hb_buffer_get_glyph_positions.restype = ctypes.POINTER(HbGlyphPosition)
    hb.hb_buffer_destroy.argtypes = [ctypes.c_void_p]
    hb.hb_font_destroy.argtypes = [ctypes.c_void_p]
    hb.hb_face_destroy.argtypes = [ctypes.c_void_p]
    hb.hb_blob_destroy.argtypes = [ctypes.c_void_p]

    blob = hb.hb_blob_create_from_file(font_path.encode())
    face = hb.hb_face_create(blob, 0)
    font = hb.hb_font_create(face)
    scale = int(size * 64)
    hb.hb_font_set_scale(font, scale, scale)
    buf = hb.hb_buffer_create()
    data = text.encode("utf-8")
    hb.hb_buffer_add_utf8(buf, data, -1, 0, -1)
    hb.hb_buffer_guess_segment_properties(buf)
    hb.hb_shape(font, buf, None, 0)
    n = ctypes.c_uint(0)
    infos = hb.hb_buffer_get_glyph_infos(buf, ctypes.byref(n))
    positions = hb.hb_buffer_get_glyph_positions(buf, ctypes.byref(n))
    total = n.value
    glyphs = []
    x = 0.0
    for i in range(total):
        info = infos[i]
        pos = positions[i]
        adv = pos.x_advance / 64.0
        glyphs.append(
            {
                "gid": int(info.codepoint),
                "cluster": int(info.cluster),
                "advance": adv,
                "x": x,
                "x_offset": pos.x_offset / 64.0,
                "y_offset": pos.y_offset / 64.0,
            }
        )
        x += adv
    hb.hb_buffer_destroy(buf)
    hb.hb_font_destroy(font)
    hb.hb_face_destroy(face)
    hb.hb_blob_destroy(blob)
    return glyphs


def shape_uharfbuzz(font_path, text, size):
    import uharfbuzz as hb

    blob = hb.Blob.from_file_path(font_path)
    face = hb.Face(blob)
    font = hb.Font(face)
    font.scale = (size * 64, size * 64)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(font, buf)
    glyphs = []
    x = 0.0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        adv = pos.x_advance / 64.0
        glyphs.append(
            {
                "gid": info.codepoint,
                "cluster": info.cluster,
                "advance": adv,
                "x": x,
                "x_offset": pos.x_offset / 64.0,
                "y_offset": pos.y_offset / 64.0,
            }
        )
        x += adv
    return glyphs


def main():
    if len(sys.argv) < 3:
        print("usage: hb_reference.py <font.ttf> <text> [size_px]", file=sys.stderr)
        sys.exit(2)
    font_path = sys.argv[1]
    text = sys.argv[2]
    size = float(sys.argv[3]) if len(sys.argv) >= 4 else 48.0
    try:
        glyphs = shape_uharfbuzz(font_path, text, size)
        backend = "uharfbuzz"
    except Exception:
        glyphs = shape_ctypes(font_path, text, size)
        backend = "ctypes"
    print(
        json.dumps(
            {
                "backend": backend,
                "font": font_path,
                "text": text,
                "size": size,
                "glyphs": glyphs,
            },
            ensure_ascii=False,
            separators=(",", ":"),
        )
    )


if __name__ == "__main__":
    main()
