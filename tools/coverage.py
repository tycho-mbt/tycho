#!/usr/bin/env python3
"""Measure how much of the Linux desktop Vulkan command surface is verified.

Usage: tools/coverage.py [--json] [--list]
"""
import glob
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
XML = os.path.join(ROOT, "codegen/registry/vk.xml")
HDR = os.path.join(ROOT, "vulkan/include/vulkan")
LAVAPIPE_ICD = (
    "/usr/share/vulkan/icd.d/lvp_icd.x86_64.json"
    if os.path.exists("/usr/share/vulkan/icd.d/lvp_icd.x86_64.json")
    else "/usr/share/vulkan/icd.d/lvp_icd.json"
)


def driver_extensions(drv):
    exe = os.path.join(
        ROOT,
        "_build/native/debug/build/laplaceliu/tycho_vulkan_examples/15-capabilities/15-capabilities.exe",
    )
    if not os.path.exists(exe):
        return set()
    env = dict(os.environ)
    if drv == "lavapipe":
        if not os.path.exists(LAVAPIPE_ICD):
            return set()
        env["VK_DRIVER_FILES"] = LAVAPIPE_ICD
    else:
        env.pop("VK_DRIVER_FILES", None)
    try:
        out = subprocess.run([exe], env=env, capture_output=True, text=True, timeout=120).stdout
    except subprocess.TimeoutExpired:
        return set()
    exts = set()
    for line in out.splitlines():
        if "device_extensions(" in line or "instance_extensions(" in line:
            exts.update(re.findall(r"VK_[A-Za-z0-9_]+", line))
    return exts


def command_table():
    root = ET.parse(XML).getroot()
    names = set()
    for c in root.findall(".//command"):
        if c.get("api") == "vulkansc":
            continue
        p = c.find("proto")
        if p is not None and p.find("name") is not None:
            names.add(p.find("name").text)
        elif c.get("alias") is not None and c.get("name") is not None:
            names.add(c.get("name"))
    header = ""
    for h in sorted(os.listdir(HDR)):
        if h.startswith("vulkan") and h.endswith(".h"):
            header += open(os.path.join(HDR, h)).read()
    desktop = {c for c in names if ("PFN_" + c) in header}
    exts = {}
    for ext in root.findall("./extensions/extension"):
        if ext.get("supported") == "vulkansc":
            continue
        for req in ext.findall("require"):
            if req.get("api") == "vulkansc":
                continue
            for cm in req.findall("command"):
                exts.setdefault(cm.get("name"), set()).add(ext.get("name"))
    for feat in root.findall("feature"):
        if feat.get("api") == "vulkansc":
            continue
        for req in feat.findall("require"):
            if req.get("api") == "vulkansc":
                continue
            for cm in req.findall("command"):
                exts.setdefault(cm.get("name"), set()).add("CORE")
    return desktop, exts


def executed_commands():
    done = set()
    patterns = [
        "examples/*/main.mbt",
        "window/**/*.mbt",
        "vulkan/structs.mbt",
    ]
    for pat in patterns:
        for f in glob.glob(os.path.join(ROOT, pat), recursive=True):
            for m in re.finditer(r"\bvk[A-Z]\w+", open(f).read()):
                done.add(m.group(0))
    return done


def main():
    desktop, exts = command_table()
    done = executed_commands()
    nv = driver_extensions("default")
    lvp = driver_extensions("lavapipe")

    def drivers(name):
        out = set()
        for e in exts.get(name, ()):
            if e == "CORE":
                out.add("both")
            else:
                if e in nv:
                    out.add("nv")
                if e in lvp:
                    out.add("lvp")
        return out

    reachable = {c for c in desktop if drivers(c)}
    remaining = sorted(reachable - done)
    both = [c for c in remaining if "both" in drivers(c) or drivers(c) == {"nv", "lvp"}]
    nv_only = [c for c in remaining if drivers(c) == {"nv"}]
    lvp_only = [c for c in remaining if drivers(c) == {"lvp"}]
    blocked = sorted(desktop - reachable)
    report = {
        "desktop_commands": len(desktop),
        "executed": len(done & desktop),
        "reachable": len(reachable),
        "reachable_executed": len(done & reachable),
        "remaining_both": both,
        "remaining_nv_only": nv_only,
        "remaining_lvp_only": lvp_only,
        "blocked_count": len(blocked),
    }
    if "--json" in sys.argv:
        print(json.dumps(report, indent=2))
        return
    print(f"desktop commands      : {len(desktop)}")
    print(f"executed by examples  : {len(done & desktop)}")
    print(f"reachable on this host: {len(reachable)} (verified: {len(done & reachable)}/{len(reachable)} = {100.0*len(done & reachable)/max(1,len(reachable)):.1f}%)")
    print(f"  both drivers, left  : {len(both)} {both}")
    print(f"  nvidia only, left   : {len(nv_only)}")
    print(f"  lavapipe only, left : {len(lvp_only)} {lvp_only}")
    print(f"physically blocked    : {len(blocked)}")
    if "--list" in sys.argv:
        print("\n--- remaining_nv_only ---")
        by_ext = {}
        for c in nv_only:
            es = sorted(e for e in exts.get(c, ()) if e in nv)
            k = es[0] if es else "UNKNOWN"
            by_ext.setdefault(k, []).append(c)
        for k in sorted(by_ext):
            print(f"  {k} ({len(by_ext[k])}): {by_ext[k]}")


if __name__ == "__main__":
    main()
