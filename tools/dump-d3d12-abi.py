#!/usr/bin/env python3
"""Distil the COM ABI of a Direct3D 12 header into dx12/registry/d3d12-abi.txt.

The manifest is committed, so `tools/gen-dx12-bindings.py` can regenerate the
MoonBit/C dispatch layer on any host without the Windows SDK. Refresh it when
bumping the header:

    python tools/dump-d3d12-abi.py [path/to/d3d12.h] [--all]

Only the interfaces the binding needs are dumped unless --all is passed.
"""

from __future__ import annotations

import pathlib
import re
import sys

SDK = pathlib.Path("C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0")
DEFAULT_HEADERS = (
    [SDK / "um" / "d3d12.h", SDK / "um" / "d3dcommon.h"]
    + sorted((SDK / "shared").glob("dxgi*.h"))
)

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "dx12" / "registry" / "d3d12-abi.txt"

# Retained for reference: the curated M1a/M1b set this binding started from. The
# generator now emits every interface found in the headers (see --all, which is
# the default), so this list is only documentation of the original scope.
ALLOW = [
    "ID3D12Object",
    "ID3D12Device",
    "ID3D12Device1",
    "ID3D12Device2",
    "ID3D12Device3",
    "ID3D12Device4",
    "ID3D12CommandQueue",
    "ID3D12CommandAllocator",
    "ID3D12GraphicsCommandList",
    "ID3D12GraphicsCommandList1",
    "ID3D12GraphicsCommandList2",
    "ID3D12PipelineState",
    "ID3D12RootSignature",
    "ID3D12Resource",
    "ID3D12DescriptorHeap",
    "ID3D12Fence",
    "ID3D12Fence1",
]

# IUnknown slots every COM interface starts with; not part of the generated API.
SKIP_METHODS = {"QueryInterface", "AddRef", "Release"}

METHOD_HEAD = re.compile(
    r"^\s*(?P<ret>.+?)\s*\(\s*STDMETHODCALLTYPE\s*\*\s*(?P<name>\w+)\s*\)\s*\(\s*$"
)
XFGVIRT = re.compile(r"^\s*DECLSPEC_XFGVIRT\((?P<owner>[^,]+),\s*(?P<name>\w+)\)")
SAL = re.compile(r"^_[A-Za-z0-9_]+_")
# Midl-generated headers annotate parameters as `/* [annotation] */ _In_ T name`;
# the `*` inside that comment would otherwise classify the parameter as a pointer.
BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.S)
LINE_COMMENT = re.compile(r"//[^\n]*")


def strip_sal(text: str) -> str:
    """Drop comments and leading SAL annotations, including nested ones like
    `_Outptr_opt_result_bytebuffer_(_Inexpressible_("Dependent on resource"))`."""
    text = LINE_COMMENT.sub(" ", BLOCK_COMMENT.sub(" ", text)).strip()
    while True:
        m = SAL.match(text)
        if not m:
            return text.strip()
        text = text[m.end() :].lstrip()
        if text.startswith("("):
            depth = 0
            for index, ch in enumerate(text):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        text = text[index + 1 :].lstrip()
                        break
            else:
                return text.strip()


def split_params(text: str) -> list[str]:
    parts, depth, current = [], 0, ""
    for ch in text:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append(current)
            current = ""
        else:
            current += ch
    if current.strip():
        parts.append(current)
    return parts


def normalise_array(text: str) -> str:
    # Arrays decay to pointers at the ABI, in both spellings the headers use:
    # `const D3D12_RECT [4]pRects` and `const FLOAT BlendFactor[4]`.
    text = re.sub(r"\s*\[\s*\d*\s*\]\s*(?=[A-Za-z_])", " *", text)
    return re.sub(r"([A-Za-z_]\w*)\s*\[\s*\d*\s*\]", r"* \1", text)


def parse_param(text: str) -> tuple[str, str] | None:
    text = normalise_array(strip_sal(text.strip()))
    if not text or text == "void":
        return None
    text = text.replace("  ", " ")
    m = re.match(r"^(?P<type>.*?)(?P<name>[A-Za-z_]\w*)$", text)
    if not m:
        return None
    ctype = m.group("type").strip()
    name = m.group("name")
    if not ctype:
        # A bare identifier is a scalar typedef without a parameter name.
        return (name, "")
    # Keep `*` glued to the type, matching how the manifest is read back.
    return (ctype, name)


def parse_interface(header: list[str], start: int) -> tuple[str, list[dict], int]:
    match = re.match(r"\s*typedef struct (\w+)Vtbl\s*$", header[start])
    assert match, header[start]
    iface = match.group(1)
    i = start + 1
    while "{" not in header[i]:
        i += 1
    i += 1
    methods: list[dict] = []
    keep = True
    while i < len(header):
        line = header[i]
        stripped = line.strip()
        if stripped.startswith("} " + iface + "Vtbl"):
            return iface, methods, i + 1
        if stripped.startswith("#if"):
            # Inside a vtbl body the only conditional builds are the _WIN32 ones;
            # keep the shipping branch and drop the portable-by-value one.
            keep = not stripped.startswith("#if !defined(_WIN32)")
            i += 1
            continue
        if stripped.startswith("#else"):
            keep = not keep
            i += 1
            continue
        if stripped.startswith("#endif"):
            keep = True
            i += 1
            continue
        xfx = XFGVIRT.match(line)
        if xfx and keep:
            i += 1
            # Some methods wrap a portable by-value signature in
            # `#if !defined(_WIN32)`; the shipping (`_WIN32`) form is the `#else`
            # branch, so skip straight to it.
            if header[i].strip().startswith("#if !defined(_WIN32)"):
                while i < len(header) and not header[i].strip().startswith("#else"):
                    i += 1
                i += 1
            head = METHOD_HEAD.match(header[i])
            if not head:
                i += 1
                continue
            name = xfx.group("name")
            ret = BLOCK_COMMENT.sub(" ", head.group("ret")).strip()
            i += 1
            blob = ""
            while i < len(header):
                blob += header[i].strip() + " "
                if header[i].strip().rstrip().endswith(");"):
                    i += 1
                    break
                i += 1
            blob = blob.strip()
            blob = blob[: blob.rfind(")")]  # drop the closing `);`
            params = [p for p in (parse_param(x) for x in split_params(blob)) if p]
            if name not in SKIP_METHODS:
                # The first parameter is always `<Iface> * This`.
                params = [(t, n) for t, n in params if n != "This"]
                methods.append({"name": name, "ret": ret, "params": params})
            continue
        i += 1
    raise RuntimeError(f"unterminated vtbl for {iface}")


def collect_kinds(text: str) -> dict[str, str]:
    """Map typedef'd aggregate names to 'struct' | 'union' | 'enum'."""
    kinds: dict[str, str] = {}
    for match in re.finditer(r"typedef\s+(struct|union|enum)\b", text):
        kind = match.group(1)
        i = match.end()
        depth = 0
        start = i
        while i < len(text):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    # Read the alias that follows the closing brace.
                    tail = re.match(r"\s*(\w+)\s*;", text[i + 1 :])
                    if tail:
                        kinds[tail.group(1)] = kind
                    break
            elif ch == ";" and depth == 0:
                # `typedef enum Tag Name;` style without a body.
                break
            i += 1
        del start
    # Bare tags: `enum D3D_PRIMITIVE_TOPOLOGY { ... };` (d3dcommon.h style).
    for match in re.finditer(r"(?:^|\n)\s*(enum|struct|union)\s+(\w+)\s*\n?\s*\{", text):
        kinds.setdefault(match.group(2), match.group(1))
    return kinds


def resolve_aliases(kinds: dict[str, str], text: str) -> None:
    """`typedef Existing New;` inherits the original kind (chains included)."""
    aliases = re.findall(r"typedef\s+(\w+)\s+(\w+)\s*;", text)
    for _ in range(6):
        changed = False
        for src, dst in aliases:
            if dst not in kinds and src in kinds:
                kinds[dst] = kinds[src]
                changed = True
        if not changed:
            break


def referenced_types(interfaces: list[tuple[str, list[dict]]]) -> set[str]:
    names: set[str] = set()
    for _, methods in interfaces:
        for method in methods:
            for text in [method["ret"]] + [t for t, _ in method["params"]]:
                base = text.replace("*", " ").replace("const", " ")
                base = re.sub(r"\[\s*\d*\s*\]", " ", base)
                for token in base.split():
                    names.add(token)
    return names


def collect_guids(text: str) -> tuple[dict[str, str], dict[str, str]]:
    """Extract MIDL_INTERFACE UUIDs and DEFINE_GUID CLSIDs."""
    iids: dict[str, str] = {}
    clsids: dict[str, str] = {}
    for m in re.finditer(r'MIDL_INTERFACE\(\s*"([0-9a-fA-F-]+)"\s*\)\s*(\w+)', text):
        iids[m.group(2)] = m.group(1).lower()
    for m in re.finditer(r"DEFINE_GUID\(\s*(CLSID_\w+)\s*,\s*([^)]+)\)", text):
        parts = [int(p.strip(), 0) for p in m.group(2).split(",")]
        if len(parts) == 11:
            d1, d2, d3 = parts[0], parts[1], parts[2]
            b = parts[3:]
            raw = (
                d1.to_bytes(4, "little")
                + d2.to_bytes(2, "little")
                + d3.to_bytes(2, "little")
                + bytes(b)
            )
            clsids[m.group(1)] = raw.hex()
    return iids, clsids


def render(
    interfaces: list[tuple[str, list[dict]]],
    kinds: dict[str, str],
    iids: dict[str, str],
    clsids: dict[str, str],
) -> str:
    lines = [
        "# Direct3D 12 COM ABI distilled from d3d12.h - DO NOT EDIT.",
        "# Regenerate with: python tools/dump-d3d12-abi.py",
        "#",
        "# interface <name> parent=<parent> methods=<count>",
        "#   <name> ret=<type>",
        "#     <type> <param-name>",
        "",
    ]
    for iface, methods in interfaces:
        parent = ""
        match = re.search(rf"DECLARE_INTERFACE_?\(?{iface},\s*(\w+)", "")
        lines.append(f"interface {iface} methods={len(methods)}")
        for method in methods:
            lines.append(f"  {method['name']} ret={method['ret']}")
            for ctype, pname in method["params"]:
                lines.append(f"    {ctype} {pname}")
    referenced = referenced_types(interfaces)
    aggregates = sorted((name, kind) for name, kind in kinds.items() if name in referenced)
    if aggregates:
        lines.append("")
        lines.append("# ABI classification for aggregate types used by value or pointer")
        for name, kind in aggregates:
            lines.append(f"kind {kind} {name}")
    iface_names = [iface for iface, _ in interfaces]
    lines.append("")
    lines.append("# Interface IIDs (from MIDL_INTERFACE declarations)")
    lines.append("iid IUnknown 00000000-0000-0000-c000-000000000046")
    for iface in iface_names:
        if iface in iids:
            lines.append(f"iid {iface} {iids[iface]}")
    if clsids:
        lines.append("")
        lines.append("# D3D12 factory/singleton CLSIDs (little-endian 16-byte GUID hex)")
        for name in sorted(clsids):
            lines.append(f"clsid {name} {clsids[name]}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    headers = [pathlib.Path(a) for a in args] if args else DEFAULT_HEADERS
    interfaces = []
    kinds: dict[str, str] = {}
    iids: dict[str, str] = {}
    clsids: dict[str, str] = {}
    seen: set[str] = set()
    all_text: list[str] = []
    for header_path in headers:
        if not header_path.is_file():
            print(f"WARNING: missing header {header_path}", file=sys.stderr)
            continue
        raw = header_path.read_text(encoding="utf-8", errors="replace")
        all_text.append(raw)
        header = raw.splitlines()
        kinds.update(collect_kinds(raw))
        h_iids, h_clsids = collect_guids(raw)
        iids.update(h_iids)
        clsids.update(h_clsids)
        i = 0
        while i < len(header):
            match = re.match(r"\s*typedef struct (\w+)Vtbl\s*$", header[i])
            if not match:
                i += 1
                continue
            iface, methods, i = parse_interface(header, i)
            if iface in seen:
                continue
            seen.add(iface)
            interfaces.append((iface, methods))
    resolve_aliases(kinds, "\n".join(all_text))
    if not interfaces:
        print("ERROR: no interfaces matched", file=sys.stderr)
        return 1
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(render(interfaces, kinds, iids, clsids), encoding="utf-8", newline="\n")
    total = sum(len(m) for _, m in interfaces)
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(interfaces)} interfaces, {total} methods)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
