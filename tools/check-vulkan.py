#!/usr/bin/env python3
"""Check that the Vulkan loader, ICD and validation layer the examples use at
runtime are actually usable.

CI runs this before the examples so a broken driver or a layer that cannot be
loaded fails once with a readable message, instead of surfacing as dozens of
`vkCreateInstance` failures. Examples that hardcode `VK_LAYER_KHRONOS_validation`
return VK_ERROR_LAYER_NOT_PRESENT (-6) when the layer is unusable, and the RHI
examples return VK_ERROR_INCOMPATIBLE_DRIVER (-9) when no ICD is found, so both
are probed here.

Environment:
  TYCHO_VULKAN_LIB   loader library to open (default: the platform's loader)
  VK_DRIVER_FILES / VK_ICD_FILENAMES  passed straight to the loader

Exit status is 0 only when an instance is created and at least one physical
device is enumerated.
"""

from __future__ import annotations

import ctypes
import os
import subprocess
import sys

VK_SUCCESS = 0

VK_ERROR_NAMES = {
    -1: "VK_ERROR_OUT_OF_HOST_MEMORY",
    -2: "VK_ERROR_OUT_OF_DEVICE_MEMORY",
    -3: "VK_ERROR_INITIALIZATION_FAILED",
    -4: "VK_ERROR_DEVICE_LOST",
    -5: "VK_ERROR_MEMORY_MAP_FAILED",
    -6: "VK_ERROR_LAYER_NOT_PRESENT",
    -7: "VK_ERROR_EXTENSION_NOT_PRESENT",
    -8: "VK_ERROR_FEATURE_NOT_PRESENT",
    -9: "VK_ERROR_INCOMPATIBLE_DRIVER",
    -10: "VK_ERROR_FORMAT_NOT_SUPPORTED",
    -11: "VK_ERROR_FRAGMENTED_POOL",
    -12: "VK_ERROR_UNKNOWN",
}

VK_STRUCTURE_TYPE_APPLICATION_INFO = 0
VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO = 1

DEVICE_TYPE_NAMES = {
    0: "other",
    1: "integrated-gpu",
    2: "discrete-gpu",
    3: "virtual-gpu",
    4: "cpu",
}

# VkPhysicalDeviceProperties: apiVersion, driverVersion, vendorID, deviceID,
# deviceType, deviceName[256], pipelineCacheUUID[16], then limits (large). The
# loader writes the whole struct, so the buffer is generously sized and the two
# leading fields are read at their fixed offsets.
PROPS_SIZE = 1024
OFF_API_VERSION = 0
OFF_DEVICE_TYPE = 16
OFF_DEVICE_NAME = 20
DEVICE_NAME_SIZE = 256


class VkApplicationInfo(ctypes.Structure):
    _fields_ = [
        ("sType", ctypes.c_uint32),
        ("pNext", ctypes.c_void_p),
        ("pApplicationName", ctypes.c_char_p),
        ("applicationVersion", ctypes.c_uint32),
        ("pEngineName", ctypes.c_char_p),
        ("engineVersion", ctypes.c_uint32),
        ("apiVersion", ctypes.c_uint32),
    ]


class VkInstanceCreateInfo(ctypes.Structure):
    _fields_ = [
        ("sType", ctypes.c_uint32),
        ("pNext", ctypes.c_void_p),
        ("flags", ctypes.c_uint32),
        ("pApplicationInfo", ctypes.POINTER(VkApplicationInfo)),
        ("enabledLayerCount", ctypes.c_uint32),
        ("ppEnabledLayerNames", ctypes.POINTER(ctypes.c_char_p)),
        ("enabledExtensionCount", ctypes.c_uint32),
        ("ppEnabledExtensionNames", ctypes.POINTER(ctypes.c_char_p)),
    ]


class VkLayerProperties(ctypes.Structure):
    _fields_ = [
        ("layerName", ctypes.c_char * 256),
        ("specVersion", ctypes.c_uint32),
        ("implementationVersion", ctypes.c_uint32),
        ("description", ctypes.c_char * 256),
    ]


def format_version(version: int) -> str:
    return f"{version >> 22}.{(version >> 12) & 0x3FF}.{version & 0xFFF}"


def api_version(major: int, minor: int) -> int:
    return (major << 22) | (minor << 12)


def result_name(code: int) -> str:
    return VK_ERROR_NAMES.get(code, f"{code}")


def load_loader():
    """Open the loader the examples resolve, and report which one that is."""
    name = os.environ.get("TYCHO_VULKAN_LIB")
    if not name:
        if os.name == "nt":
            name = "vulkan-1.dll"
        elif sys.platform == "darwin":
            name = "libvulkan.1.dylib"
        else:
            name = "libvulkan.so.1"
    opener = ctypes.WinDLL if os.name == "nt" else ctypes.CDLL
    vk = opener(name)
    # Without argtypes ctypes assumes C int arguments, which truncates the
    # 64-bit handles/pointers these entry points take.
    vk.vkEnumerateInstanceVersion.argtypes = [ctypes.POINTER(ctypes.c_uint32)]
    vk.vkEnumerateInstanceVersion.restype = ctypes.c_int
    vk.vkEnumerateInstanceLayerProperties.argtypes = [
        ctypes.POINTER(ctypes.c_uint32),
        ctypes.POINTER(VkLayerProperties),
    ]
    vk.vkEnumerateInstanceLayerProperties.restype = ctypes.c_int
    vk.vkCreateInstance.argtypes = [
        ctypes.POINTER(VkInstanceCreateInfo),
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_void_p),
    ]
    vk.vkCreateInstance.restype = ctypes.c_int
    vk.vkEnumeratePhysicalDevices.argtypes = [
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_uint32),
        ctypes.POINTER(ctypes.c_void_p),
    ]
    vk.vkEnumeratePhysicalDevices.restype = ctypes.c_int
    vk.vkGetPhysicalDeviceProperties.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    vk.vkGetPhysicalDeviceProperties.restype = None
    vk.vkDestroyInstance.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
    vk.vkDestroyInstance.restype = None
    return vk, name


def describe_environment() -> None:
    for var in ("TYCHO_VULKAN_LIB", "VK_DRIVER_FILES", "VK_ICD_FILENAMES", "VK_LAYER_PATH"):
        value = os.environ.get(var)
        if value:
            print(f"{var}={value}")


def instance_layers(vk) -> list[str]:
    count = ctypes.c_uint32()
    if vk.vkEnumerateInstanceLayerProperties(ctypes.byref(count), None) != VK_SUCCESS:
        return []
    if count.value == 0:
        return []
    props = (VkLayerProperties * count.value)()
    if vk.vkEnumerateInstanceLayerProperties(ctypes.byref(count), props) != VK_SUCCESS:
        return []
    return [p.layerName.decode("utf-8", "replace") for p in props[: count.value]]


def create_instance(vk, version: int):
    app = VkApplicationInfo(
        sType=VK_STRUCTURE_TYPE_APPLICATION_INFO,
        pNext=None,
        pApplicationName=b"tycho-check-vulkan",
        applicationVersion=1,
        pEngineName=b"tycho",
        engineVersion=1,
        apiVersion=version,
    )
    info = VkInstanceCreateInfo(
        sType=VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pNext=None,
        flags=0,
        pApplicationInfo=ctypes.pointer(app),
        enabledLayerCount=0,
        ppEnabledLayerNames=None,
        enabledExtensionCount=0,
        ppEnabledExtensionNames=None,
    )
    handle = ctypes.c_void_p()
    code = vk.vkCreateInstance(ctypes.byref(info), None, ctypes.byref(handle))
    return code, handle


def physical_devices(vk, instance) -> list[tuple[int, int, str]]:
    count = ctypes.c_uint32()
    code = vk.vkEnumeratePhysicalDevices(instance, ctypes.byref(count), None)
    if code != VK_SUCCESS or count.value == 0:
        return []
    handles = (ctypes.c_void_p * count.value)()
    code = vk.vkEnumeratePhysicalDevices(instance, ctypes.byref(count), handles)
    if code != VK_SUCCESS:
        return []
    devices = []
    for handle in handles[: count.value]:
        buf = ctypes.create_string_buffer(PROPS_SIZE)
        vk.vkGetPhysicalDeviceProperties(handle, buf)
        raw = buf.raw
        version = int.from_bytes(raw[OFF_API_VERSION : OFF_API_VERSION + 4], "little")
        kind = int.from_bytes(raw[OFF_DEVICE_TYPE : OFF_DEVICE_TYPE + 4], "little")
        name = raw[OFF_DEVICE_NAME : OFF_DEVICE_NAME + DEVICE_NAME_SIZE]
        devices.append((version, kind, name.split(b"\0")[0].decode("utf-8", "replace")))
    return devices


def main() -> int:
    describe_environment()

    try:
        vk, loader_name = load_loader()
    except OSError as exc:
        print(f"ERROR: cannot open the Vulkan loader ({exc})", file=sys.stderr)
        print("hint: set TYCHO_VULKAN_LIB to a vulkan-1.dll / libvulkan.so.1", file=sys.stderr)
        return 1

    loader_version = ctypes.c_uint32()
    code = vk.vkEnumerateInstanceVersion(ctypes.byref(loader_version))
    if code == VK_SUCCESS:
        print(f"loader: {loader_name} ({format_version(loader_version.value)})")
    else:
        # Loader 1.0 has no vkEnumerateInstanceVersion; anything that old cannot
        # run the RHI, which asks for 1.3.
        print(f"loader: {loader_name} (version query failed: {result_name(code)})")
        loader_version.value = api_version(1, 0)

    layers = instance_layers(vk)
    validation = "VK_LAYER_KHRONOS_validation"
    if validation in layers:
        print(f"layer: {validation} available")
    else:
        print(
            f"WARNING: {validation} is not available; examples that enable it "
            "fail with VK_ERROR_LAYER_NOT_PRESENT (-6)",
            file=sys.stderr,
        )

    wanted = api_version(1, 3)
    if loader_version.value < wanted:
        print(
            f"ERROR: loader {format_version(loader_version.value)} is older than the "
            f"{format_version(wanted)} the RHI requires",
            file=sys.stderr,
        )
        return 1

    code, instance = create_instance(vk, wanted)
    if code != VK_SUCCESS:
        print(
            f"ERROR: vkCreateInstance({format_version(wanted)}) -> {result_name(code)}",
            file=sys.stderr,
        )
        if code == -9:
            print(
                "hint: the loader found no ICD; check VK_DRIVER_FILES and re-run with "
                "VK_LOADER_DEBUG=error,warn",
                file=sys.stderr,
            )
        elif code == -6:
            print(
                "hint: a layer that enumerated is missing at instance creation",
                file=sys.stderr,
            )
        return 1

    devices = physical_devices(vk, instance)
    vk.vkDestroyInstance(instance, None)
    if not devices:
        print("ERROR: vkEnumeratePhysicalDevices returned no devices", file=sys.stderr)
        print("hint: re-run with VK_LOADER_DEBUG=error,warn", file=sys.stderr)
        return 1

    for version, kind, name in devices:
        print(f"device: {name} ({format_version(version)}, {DEVICE_TYPE_NAMES.get(kind, kind)})")
    return 0


if __name__ == "__main__":
    status = main()
    # The loader reads VK_LOADER_DEBUG once, when it is initialised, so the failed
    # run cannot explain itself: repeat it in a child process with the loader's
    # own diagnostics enabled.
    if status != 0 and "--with-loader-debug" not in sys.argv and "VK_LOADER_DEBUG" not in os.environ:
        print("\n--- retrying with VK_LOADER_DEBUG=error,warn ---", file=sys.stderr)
        env = dict(os.environ, VK_LOADER_DEBUG="error,warn")
        status = subprocess.call(
            [sys.executable, os.path.abspath(__file__), "--with-loader-debug"], env=env
        )
    sys.exit(status)
