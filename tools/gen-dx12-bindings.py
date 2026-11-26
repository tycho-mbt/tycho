#!/usr/bin/env python3
"""Generate the Direct3D 12 COM dispatch layer from dx12/registry/d3d12-abi.txt.

Usage: python tools/gen-dx12-bindings.py [--check]

Emits dx12/dispatch_generated.c (one `MOONBIT_FFI_EXPORT` thunk per COM method,
plus no-op stubs on non-Windows hosts) and dx12/dispatch_generated.mbt (the
matching `extern "c"` declarations). Both are committed; --check fails on drift,
which is what the CI gate runs.
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "dx12" / "registry" / "d3d12-abi.txt"
OUT_C = ROOT / "dx12" / "dispatch_generated.c"
OUT_MBT = ROOT / "dx12" / "dispatch_generated.mbt"

# Typedefs that name a pointer even though the spelling has no `*`.
POINTER_TYPEDEFS = {
    "REFIID",
    "REFGUID",
    "REFCLSID",
    "LPCWSTR",
    "LPWSTR",
    "LPCSTR",
    "LPSTR",
    "LPVOID",
    "LPCVOID",
    "BSTR",
    "GUID",
    "PFN_DESTRUCTION_CALLBACK",
    # Win32 handles are pointers; classifying them as integers would trip C4047
    # when a method returns one.
    "HANDLE",
    "HWND",
    "HINSTANCE",
    "HMODULE",
}
# 32-bit scalar spellings (enums fall through to this bucket as well).
SCALAR32 = {
    "int",
    "INT",
    "UINT",
    "DWORD",
    "LONG",
    "ULONG",
    "BOOL",
    "HRESULT",
    "WORD",
    "BYTE",
    "UCHAR",
    "CHAR",
    "WCHAR",
    "UINT8",
    "UINT16",
    "UINT32",
    "INT8",
    "INT16",
    "INT32",
    # DXGI spells its bitmask as a UINT typedef.
    "DXGI_USAGE",
}
# 64-bit scalar spellings / pointer-sized handles.
SCALAR64 = {
    "UINT64",
    "INT64",
    "D3D12_GPU_VIRTUAL_ADDRESS",
    "SIZE_T",
    "UINT_PTR",
    "INT_PTR",
}
# MoonBit reserved words: a parameter with one of these names falls back to
# `a<index>` (e.g. DXGI's `module` argument).
KEYWORDS = {
    "self",
    "fn",
    "let",
    "match",
    "type",
    "test",
    "if",
    "else",
    "return",
    "while",
    "for",
    "module",
    "struct",
    "enum",
    "trait",
    "impl",
    "pub",
    "priv",
    "mut",
    "const",
    "import",
    "extern",
    "guard",
    "async",
    "break",
    "continue",
    "in",
    "is",
    "try",
    "catch",
    "throw",
    "raise",
}


def parse_manifest() -> tuple[list[dict], dict[str, str]]:
    interfaces: list[dict] = []
    kinds: dict[str, str] = {}
    current_iface = None
    current_method = None
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("interface "):
            match = re.match(r"interface (\w+)", line)
            current_iface = {"name": match.group(1), "methods": []}
            interfaces.append(current_iface)
            current_method = None
            continue
        if line.startswith("kind "):
            parts = line.split()
            kinds[parts[2]] = parts[1]
            continue
        match = re.match(r"(\w+) ret=(.+)$", line)
        if match and current_iface is not None and raw.startswith("  ") and not raw.startswith("    "):
            current_method = {"name": match.group(1), "ret": match.group(2).strip(), "params": []}
            current_iface["methods"].append(current_method)
            continue
        if current_method is not None and raw.startswith("    "):
            ctype, _, pname = line.rpartition(" ")
            current_method["params"].append((ctype.strip(), pname.strip()))
    return interfaces, kinds


class UnknownType(Exception):
    pass


def classify(ctype: str, kinds: dict[str, str]) -> str:
    if "*" in ctype or ctype.strip() in POINTER_TYPEDEFS:
        return "ptr"
    base = ctype.replace("const", "").strip()
    if base in ("float", "FLOAT"):
        return "float"
    if base == "double":
        return "double"
    if base in SCALAR64:
        return "u64"
    if base in SCALAR32:
        return "u32"
    if kinds.get(base) in ("struct", "union"):
        return "struct"
    # An enum needs no special case beyond its 32-bit width.
    if kinds.get(base) == "enum":
        return "u32"
    # Guessing here would silently truncate a pointer on 64-bit hosts, so the
    # generator refuses instead. Add the spelling to the sets above (or to the
    # manifest as a `kind` line) when a new header introduces it.
    raise UnknownType(ctype.strip())


def snake(name: str) -> str:
    text = re.sub(r"(?<!^)(?=[A-Z][a-z])|(?<=[a-z0-9])(?=[A-Z])", "_", name)
    return text.lower()


def iface_prefix(name: str) -> str:
    # Namespaced by API: ID3D12Object and IDXGIObject would otherwise both
    # become `object` and collide.
    if name.startswith("ID3D12"):
        return "d3d12_" + snake(name[len("ID3D12") :])
    if name.startswith("IDXGI"):
        return "dxgi_" + snake(name[len("IDXGI") :])
    return snake(name)


C_ARG_TYPE = {
    "ptr": "uint64_t",
    "struct": "uint64_t",
    "u64": "uint64_t",
    "u32": "int32_t",
    "float": "float",
    "double": "double",
}
MB_TYPE = {
    "ptr": "UInt64",
    "struct": "UInt64",
    "u64": "Int64",
    "u32": "Int",
    "float": "Float",
    "double": "Double",
}


def c_return(ret: str, kinds: dict[str, str]) -> tuple[str, str]:
    """(C return type, MoonBit return type) for a manifest return spelling."""
    if ret.strip() == "void":
        return "void", "Unit"
    kind = classify(ret, kinds)
    if kind == "ptr":
        return "void *", "UInt64"
    if kind == "struct":
        raise ValueError(f"struct-by-value return is not supported: {ret}")
    return {"u32": "int32_t", "u64": "int64_t", "float": "float", "double": "double"}[kind], MD_TYPE_MAP[kind]


MD_TYPE_MAP = {"u32": "Int", "u64": "Int64", "float": "Float", "double": "Double"}


def c_arg(ctype: str, kind: str, index: int) -> str:
    arg = f"a{index}"
    if kind == "ptr":
        return f"({ctype})(uintptr_t){arg}"
    if kind == "struct":
        return f"*(const {ctype} *)(uintptr_t){arg}"
    if kind == "u64":
        return f"({ctype})(int64_t){arg}"
    if kind == "u32":
        return f"({ctype})(int32_t){arg}"
    return arg


def lint_types(interfaces: list[dict], kinds: dict[str, str]) -> list[str]:
    """Every spelling must be known: no silent 32-bit truncation."""
    problems: list[str] = []
    for iface in interfaces:
        for method in iface["methods"]:
            rets = [] if method["ret"].strip() == "void" else [method["ret"]]
            for ctype in rets + [p[0] for p in method["params"]]:
                try:
                    classify(ctype, kinds)
                except UnknownType as exc:
                    problems.append(
                        f"{iface['name']}::{method['name']} unknown type {exc}"
                    )
    return problems


def emit_c(interfaces: list[dict], kinds: dict[str, str]) -> str:
    windows: list[str] = []
    stubs: list[str] = []
    for iface in interfaces:
        name = iface["name"]
        for method in iface["methods"]:
            symbol = f"tycho_dx12_{name}_{method['name']}"
            ret_c, _ = c_return(method["ret"], kinds)
            kinds_list = [classify(t, kinds) for t, _ in method["params"]]
            args = ", ".join(
                f"{C_ARG_TYPE[kind]} a{index}" for index, kind in enumerate(kinds_list)
            )
            header = f"MOONBIT_FFI_EXPORT {ret_c} {symbol}(uint64_t self" + (f", {args}" if args else "") + ")"
            forwarded = ", ".join(
                [f"({name} *)(uintptr_t)self"]
                + [c_arg(ctype, kind, index) for index, ((ctype, _), kind) in enumerate(zip(method["params"], kinds_list))]
            )
            call = f"(({name} *)(uintptr_t)self)->lpVtbl->{method['name']}({forwarded})"
            if ret_c == "void":
                body = f"  {call};"
            elif ret_c == "void *":
                # `const T *` returns would otherwise trip C4090 (dropped const).
                body = f"  return (void *)(uintptr_t){call};"
            else:
                body = f"  return {call};"
            windows.append(f"{header} {{\n{body}\n}}\n")
            stub_body = ["  (void)self;"] + [f"  (void)a{i};" for i in range(len(kinds_list))]
            if ret_c != "void":
                stub_body.append("  return 0;")
            stubs.append(f"{header} {{\n" + "\n".join(stub_body) + "\n}\n")

    lines = [
        "// Generated by tools/gen-dx12-bindings.py - DO NOT EDIT.",
        "//",
        "// One thunk per Direct3D 12 COM method, forwarding through the vtable.",
        "// Non-Windows hosts get no-op stubs so the package still builds there.",
        "",
        '#include "moonbit.h"',
        "",
        "#include <stdint.h>",
        "",
        "#if defined(_WIN32)",
        "",
        "#define WIN32_LEAN_AND_MEAN",
        "#define NOMINMAX",
        "#include <windows.h>",
        "#include <d3d12.h>",
        "#include <dxgi1_6.h>",
        "",
    ]
    lines.extend(windows)
    lines.append("#else  // !defined(_WIN32)")
    lines.append("")
    lines.extend(stubs)
    lines.append("#endif  // defined(_WIN32)")
    lines.append("")
    return "\n".join(lines)


def emit_mbt(interfaces: list[dict], kinds: dict[str, str]) -> str:
    lines = [
        "// Generated by tools/gen-dx12-bindings.py - DO NOT EDIT.",
        "//",
        "// Raw COM dispatch for Direct3D 12: one 1:1 function per method, with",
        "// handles, pointers and by-value structs lowered to 64-bit words (a",
        "// by-value struct arrives as a pointer to its bytes). The safe layer in",
        "// dx12.mbt sits on top of these.",
        "",
    ]
    for iface in interfaces:
        name = iface["name"]
        prefix = iface_prefix(name)
        for method in iface["methods"]:
            ret_mb = c_return(method["ret"], kinds)[1]
            # `self` would be parsed as a method receiver; `obj` keeps these
            # plain functions.
            params = ["obj : UInt64"]
            for index, (ctype, pname) in enumerate(method["params"]):
                ident = snake(pname) if pname else f"a{index}"
                if not ident or ident[0].isdigit() or ident in KEYWORDS:
                    ident = f"a{index}"
                params.append(f"{ident} : {MB_TYPE[classify(ctype, kinds)]}")
            lines.append("///|")
            lines.append(
                f'pub extern "c" fn dx_{prefix}_{snake(method["name"])}('
                + ", ".join(params)
                + f') -> {ret_mb} = "tycho_dx12_{name}_{method["name"]}"'
            )
            lines.append("")
    return "\n".join(lines)


def main() -> int:
    check_only = "--check" in sys.argv[1:]
    interfaces, kinds = parse_manifest()
    problems = lint_types(interfaces, kinds)
    if problems:
        for problem in problems[:40]:
            print("ERROR: " + problem, file=sys.stderr)
        print(
            f"ERROR: {len(problems)} unknown type spelling(s); extend the"
            " knowledge sets in tools/gen-dx12-bindings.py",
            file=sys.stderr,
        )
        return 1
    c_text = emit_c(interfaces, kinds)
    mbt_text = emit_mbt(interfaces, kinds)
    methods = sum(len(i["methods"]) for i in interfaces)
    drift = 0
    for path, text in ((OUT_C, c_text), (OUT_MBT, mbt_text)):
        if check_only:
            current = path.read_text(encoding="utf-8") if path.is_file() else ""
            if current != text:
                print(f"ERROR: {path} is out of date; run tools/gen-dx12-bindings.py", file=sys.stderr)
                drift = 1
        else:
            path.write_text(text, encoding="utf-8", newline="\n")
    if drift:
        return 1
    if check_only:
        print(f"dx12 bindings in sync ({len(interfaces)} interfaces, {methods} methods)")
    else:
        print(f"wrote {OUT_C.relative_to(ROOT)} and {OUT_MBT.relative_to(ROOT)}")
        print(f"  {len(interfaces)} interfaces, {methods} methods")
    return 0


if __name__ == "__main__":
    sys.exit(main())
