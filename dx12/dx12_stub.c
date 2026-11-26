// Native shim for laplaceliu/tycho_dx12 (M1a: hand-written minimal surface).
//
// Zero link flags: d3d12.dll / dxgi.dll are loaded at runtime, every entry point
// is resolved with GetProcAddress, and the COM vtable calls live here because
// MoonBit cannot dereference function pointers.
//
// Windows-only by construction; every exported symbol still exists on other
// hosts (returning 0) so the package keeps building on Linux/macOS CI.

#include "moonbit.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)

#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <d3d12.h>
#include <d3d12sdklayers.h>
#include <dxgi1_6.h>

// ---------------------------------------------------------------------------
// Entry points resolved at runtime
// ---------------------------------------------------------------------------

typedef HRESULT(WINAPI *PFN_D3D12CreateDevice)(IUnknown *, D3D_FEATURE_LEVEL, REFIID, void **);
typedef HRESULT(WINAPI *PFN_D3D12GetDebugInterface)(REFIID, void **);
typedef HRESULT(WINAPI *PFN_D3D12SerializeVersionedRootSignature)(
    const D3D12_VERSIONED_ROOT_SIGNATURE_DESC *, ID3DBlob **, ID3DBlob **);
typedef HRESULT(WINAPI *PFN_CreateDXGIFactory2)(UINT, REFIID, void **);

static PFN_D3D12CreateDevice g_create_device = NULL;
static PFN_D3D12GetDebugInterface g_get_debug = NULL;
static PFN_D3D12SerializeVersionedRootSignature g_serialize_rs = NULL;
static PFN_CreateDXGIFactory2 g_create_factory2 = NULL;
static HRESULT g_last_hr = S_OK;

// Hand-written IIDs. Verified byte-for-byte against the Windows SDK (INITGUID)
// in the M0 spike; every one of them is exercised by the triangle test below, so
// a typo surfaces as a failed HRESULT instead of silent misbehaviour.
static const GUID kIID_IDXGIFactory4 = {0x1bc6ea02, 0xef36, 0x464f,
                                        {0xbf, 0x0c, 0x21, 0xca, 0x39, 0xe5, 0x16, 0x8a}};
static const GUID kIID_IDXGIAdapter1 = {0x29038f61, 0x3839, 0x4626,
                                        {0x91, 0xfd, 0x08, 0x68, 0x79, 0x01, 0x1a, 0x05}};
static const GUID kIID_ID3D12Device = {0x189819f1, 0x1db6, 0x4b57,
                                       {0xbe, 0x54, 0x18, 0x21, 0x33, 0x9b, 0x85, 0xf7}};
static const GUID kIID_ID3D12Debug = {0x344488b7, 0x6846, 0x474b,
                                      {0xb9, 0x89, 0xf0, 0x27, 0x44, 0x82, 0x45, 0xe0}};
static const GUID kIID_ID3D12InfoQueue = {0x0742a90b, 0xc387, 0x483f,
                                          {0xb9, 0x46, 0x30, 0xa7, 0xe4, 0xe6, 0x14, 0x58}};
static const GUID kIID_ID3D12RootSignature = {0xc54a6b66, 0x72df, 0x4ee8,
                                              {0x8b, 0xe5, 0xa9, 0x46, 0xa1, 0x42, 0x92, 0x14}};
static const GUID kIID_ID3D12PipelineState = {0x765a30f3, 0xf624, 0x4c6f,
                                              {0xa8, 0x28, 0xac, 0xe9, 0x48, 0x62, 0x24, 0x45}};
static const GUID kIID_ID3D12Resource = {0x696442be, 0xa72e, 0x4059,
                                         {0xbc, 0x79, 0x5b, 0x5c, 0x98, 0x04, 0x0f, 0xad}};
static const GUID kIID_ID3D12Fence = {0x0a753dcf, 0xc4d8, 0x4b91,
                                      {0xad, 0xf6, 0xbe, 0x5a, 0x60, 0xd9, 0x5a, 0x76}};
static const GUID kIID_ID3D12CommandQueue = {0x0ec870a6, 0x5d7e, 0x4c22,
                                             {0x8c, 0xfc, 0x5b, 0xaa, 0xe0, 0x76, 0x16, 0xed}};
static const GUID kIID_ID3D12CommandAllocator = {0x6102dee4, 0xaf59, 0x4b09,
                                                 {0xb9, 0x99, 0xb4, 0x4d, 0x73, 0xf0, 0x9b, 0x24}};
static const GUID kIID_ID3D12GraphicsCommandList = {0x5b160d0f, 0xac1b, 0x4185,
                                                    {0x8b, 0xa8, 0xb3, 0xae, 0x42, 0xa5, 0xa4, 0x55}};
static const GUID kIID_ID3D12DescriptorHeap = {0x8efb471d, 0x616c, 0x4f49,
                                               {0x90, 0xf7, 0x12, 0x7b, 0xb7, 0x63, 0xfa, 0x51}};
static const GUID kIID_IDXGISwapChain3 = {0x94d99bdb, 0xf1f8, 0x4ab0,
                                          {0xb2, 0x36, 0x7d, 0xa0, 0x17, 0x0e, 0xda, 0xb1}};

#define TYCHO_DX12_RT_FORMAT DXGI_FORMAT_R8G8B8A8_UNORM
#define TYCHO_DX12_RT_FORMAT_PIXEL_BYTES 4
#define TYCHO_DX12_PITCH_ALIGNMENT 256
#define TYCHO_DX12_FRAME_COUNT 3

// Typed resource states crossing the FFI. D3D12_RESOURCE_STATE_COMMON and
// D3D12_RESOURCE_STATE_PRESENT are both numerically 0, so the shim keeps its own
// enum (so "present" stays expressible) while tracking the native value.
enum {
  TYCHO_DX12_STATE_COMMON = 0,
  TYCHO_DX12_STATE_RENDER_TARGET = 1,
  TYCHO_DX12_STATE_COPY_SOURCE = 2,
  TYCHO_DX12_STATE_COPY_DEST = 3,
  TYCHO_DX12_STATE_PRESENT = 4,
  TYCHO_DX12_STATE_SHADER_RESOURCE = 5,
  TYCHO_DX12_STATE_UNORDERED_ACCESS = 6,
};

static D3D12_RESOURCE_STATES dx12_native_state(int32_t state) {
  switch (state) {
    case TYCHO_DX12_STATE_RENDER_TARGET:
      return D3D12_RESOURCE_STATE_RENDER_TARGET;
    case TYCHO_DX12_STATE_COPY_SOURCE:
      return D3D12_RESOURCE_STATE_COPY_SOURCE;
    case TYCHO_DX12_STATE_COPY_DEST:
      return D3D12_RESOURCE_STATE_COPY_DEST;
    case TYCHO_DX12_STATE_PRESENT:
      return D3D12_RESOURCE_STATE_PRESENT;
    case TYCHO_DX12_STATE_SHADER_RESOURCE:
      return D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
    case TYCHO_DX12_STATE_UNORDERED_ACCESS:
      return D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
    default:
      return D3D12_RESOURCE_STATE_COMMON;
  }
}

// ---------------------------------------------------------------------------
// Object wrappers (opaque handles crossing the FFI as uint64_t)
// ---------------------------------------------------------------------------

typedef struct TychoDxDevice {
  ID3D12Device *device;
  ID3D12CommandQueue *queue;
  ID3D12Fence *fence;
  IDXGIFactory4 *factory;
  HANDLE fence_event;
  UINT64 fence_value;
  ID3D12InfoQueue *info_queue;
  int is_warp;
  int shader_model;
  int mesh_tier;
  int raytracing_tier;
} TychoDxDevice;

typedef struct TychoDxPipeline {
  ID3D12RootSignature *root_signature;
  ID3D12PipelineState *pso;
} TychoDxPipeline;

typedef struct TychoDxTexture {
  ID3D12Resource *resource;
  ID3D12DescriptorHeap *rtv_heap;  // owned by the wrapper unless `owned` is 0
  D3D12_CPU_DESCRIPTOR_HANDLE rtv;
  D3D12_RESOURCE_STATES state;  // native state, what the barriers need
  int state_tag;                // typed enum reported across the FFI
  int width;
  int height;
  int owned;  // 0 for swapchain back buffers, whose lifetime is the swapchain's
} TychoDxTexture;

// CPU-visible (UPLOAD heap) buffer, persistently mapped. Uniform data is the
// only consumer today; it is bound as a root CBV so no descriptor heap is
// needed.
typedef struct TychoDxBuffer {
  ID3D12Resource *resource;
  void *mapped;
  int size;
} TychoDxBuffer;

typedef struct TychoDxSwapchain {
  IDXGISwapChain3 *swapchain;
  ID3D12DescriptorHeap *rtv_heap;
  D3D12_CPU_DESCRIPTOR_HANDLE rtv[TYCHO_DX12_FRAME_COUNT];
  UINT width;
  UINT height;
  int has_views;
} TychoDxSwapchain;

typedef struct TychoDxReadback {
  ID3D12Resource *resource;
  UINT row_pitch;
  int width;
  int height;
} TychoDxReadback;

typedef struct TychoDxCommands {
  ID3D12CommandAllocator *allocator;
  ID3D12GraphicsCommandList *list;
} TychoDxCommands;

static TychoDxDevice *as_device(uint64_t p) { return (TychoDxDevice *)(uintptr_t)p; }
static TychoDxPipeline *as_pipeline(uint64_t p) { return (TychoDxPipeline *)(uintptr_t)p; }
static TychoDxTexture *as_texture(uint64_t p) { return (TychoDxTexture *)(uintptr_t)p; }
static TychoDxReadback *as_readback(uint64_t p) { return (TychoDxReadback *)(uintptr_t)p; }
static TychoDxCommands *as_commands(uint64_t p) { return (TychoDxCommands *)(uintptr_t)p; }
static TychoDxSwapchain *as_swapchain(uint64_t p) { return (TychoDxSwapchain *)(uintptr_t)p; }
static TychoDxBuffer *as_buffer(uint64_t p) { return (TychoDxBuffer *)(uintptr_t)p; }

static void set_hr(HRESULT hr) {
  if (FAILED(hr)) {
    g_last_hr = hr;
  }
}

// ---------------------------------------------------------------------------
// Loader
// ---------------------------------------------------------------------------

static int g_init_state = -1;  // -1 = not tried, 0 = failed, 1 = loaded

MOONBIT_FFI_EXPORT int32_t tycho_dx12_init(void) {
  if (g_init_state >= 0) return g_init_state;
  g_init_state = 0;
  const char *d3d12_path = getenv("TYCHO_D3D12_LIB");
  const char *dxgi_path = getenv("TYCHO_DXGI_LIB");
  HMODULE d3d12 = (d3d12_path && d3d12_path[0]) ? LoadLibraryA(d3d12_path) : NULL;
  if (!d3d12) d3d12 = LoadLibraryA("d3d12.dll");
  HMODULE dxgi = (dxgi_path && dxgi_path[0]) ? LoadLibraryA(dxgi_path) : NULL;
  if (!dxgi) dxgi = LoadLibraryA("dxgi.dll");
  if (!d3d12 || !dxgi) return 0;
  g_create_device = (PFN_D3D12CreateDevice)GetProcAddress(d3d12, "D3D12CreateDevice");
  g_get_debug = (PFN_D3D12GetDebugInterface)GetProcAddress(d3d12, "D3D12GetDebugInterface");
  g_serialize_rs = (PFN_D3D12SerializeVersionedRootSignature)GetProcAddress(
      d3d12, "D3D12SerializeVersionedRootSignature");
  g_create_factory2 = (PFN_CreateDXGIFactory2)GetProcAddress(dxgi, "CreateDXGIFactory2");
  if (!g_create_device || !g_serialize_rs || !g_create_factory2) return 0;
  g_init_state = 1;
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_last_error(void) { return (int32_t)g_last_hr; }

// Data pointer of a MoonBit array, for the raw ABI-style calls the generated
// dispatch layer exposes (distinct name from the Vulkan package's helper so both
// modules can be linked into one executable).
MOONBIT_FFI_EXPORT uint64_t tycho_dx12_as_ptr(const void *p) {
  return (uint64_t)(uintptr_t)p;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_env_requests_warp(void) {
  const char *e = getenv("TYCHO_DX12_WARP");
  return (e && (strcmp(e, "1") == 0 || strcmp(e, "true") == 0 || strcmp(e, "yes") == 0)) ? 1 : 0;
}

// ---------------------------------------------------------------------------
// Device
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_device_create(int32_t use_warp, int32_t debug) {
  if (!tycho_dx12_init()) return 0;

  if (debug && g_get_debug) {
    ID3D12Debug *dbg = NULL;
    if (SUCCEEDED(g_get_debug(&kIID_ID3D12Debug, (void **)&dbg)) && dbg) {
      dbg->lpVtbl->EnableDebugLayer(dbg);
      dbg->lpVtbl->Release(dbg);
    }
  }

  IDXGIFactory4 *factory = NULL;
  IDXGIAdapter1 *adapter = NULL;
  TychoDxDevice *dev = NULL;
  HRESULT hr;

  hr = g_create_factory2(0, &kIID_IDXGIFactory4, (void **)&factory);
  set_hr(hr);
  if (FAILED(hr)) return 0;

  if (use_warp) {
    hr = factory->lpVtbl->EnumWarpAdapter(factory, &kIID_IDXGIAdapter1, (void **)&adapter);
  } else {
    hr = factory->lpVtbl->EnumAdapters1(factory, 0, &adapter);
  }
  set_hr(hr);
  if (FAILED(hr) || !adapter) {
    factory->lpVtbl->Release(factory);
    return 0;
  }

  dev = (TychoDxDevice *)calloc(1, sizeof(TychoDxDevice));
  if (!dev) {
    adapter->lpVtbl->Release(adapter);
    return 0;
  }
  dev->is_warp = use_warp ? 1 : 0;
  dev->factory = factory;  // kept for swapchain creation, released in destroy

  hr = g_create_device((IUnknown *)adapter, D3D_FEATURE_LEVEL_12_0, &kIID_ID3D12Device,
                       (void **)&dev->device);
  set_hr(hr);
  adapter->lpVtbl->Release(adapter);
  if (FAILED(hr) || !dev->device) {
    factory->lpVtbl->Release(factory);
    free(dev);
    return 0;
  }

  D3D12_COMMAND_QUEUE_DESC qd;
  memset(&qd, 0, sizeof qd);
  qd.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
  qd.Priority = D3D12_COMMAND_QUEUE_PRIORITY_NORMAL;
  hr = dev->device->lpVtbl->CreateCommandQueue(dev->device, &qd, &kIID_ID3D12CommandQueue,
                                               (void **)&dev->queue);
  set_hr(hr);
  if (FAILED(hr)) goto fail;

  hr = dev->device->lpVtbl->CreateFence(dev->device, 0, D3D12_FENCE_FLAG_NONE, &kIID_ID3D12Fence,
                                        (void **)&dev->fence);
  set_hr(hr);
  if (FAILED(hr)) goto fail;
  dev->fence_event = CreateEventExA(NULL, NULL, 0, EVENT_MODIFY_STATE | SYNCHRONIZE);
  if (!dev->fence_event) goto fail;

  if (debug) {
    if (SUCCEEDED(dev->device->lpVtbl->QueryInterface(dev->device, &kIID_ID3D12InfoQueue,
                                                      (void **)&dev->info_queue))) {
      dev->info_queue->lpVtbl->SetMuteDebugOutput(dev->info_queue, FALSE);
    } else {
      dev->info_queue = NULL;
    }
  }

  {
    D3D12_FEATURE_DATA_SHADER_MODEL sm;
    memset(&sm, 0, sizeof sm);
    sm.HighestShaderModel = D3D_SHADER_MODEL_6_7;
    if (SUCCEEDED(dev->device->lpVtbl->CheckFeatureSupport(dev->device,
                                                           D3D12_FEATURE_SHADER_MODEL, &sm,
                                                           sizeof sm))) {
      dev->shader_model = (int)sm.HighestShaderModel;
    }
  }
  {
    D3D12_FEATURE_DATA_D3D12_OPTIONS7 opt7;
    memset(&opt7, 0, sizeof opt7);
    if (SUCCEEDED(dev->device->lpVtbl->CheckFeatureSupport(dev->device,
                                                           D3D12_FEATURE_D3D12_OPTIONS7, &opt7,
                                                           sizeof opt7))) {
      dev->mesh_tier = (int)opt7.MeshShaderTier;
    }
  }
  {
    D3D12_FEATURE_DATA_D3D12_OPTIONS5 opt5;
    memset(&opt5, 0, sizeof opt5);
    if (SUCCEEDED(dev->device->lpVtbl->CheckFeatureSupport(dev->device,
                                                           D3D12_FEATURE_D3D12_OPTIONS5, &opt5,
                                                           sizeof opt5))) {
      dev->raytracing_tier = (int)opt5.RaytracingTier;
    }
  }
  return (uint64_t)(uintptr_t)dev;

fail:
  if (dev->info_queue) dev->info_queue->lpVtbl->Release(dev->info_queue);
  if (dev->fence_event) CloseHandle(dev->fence_event);
  if (dev->fence) dev->fence->lpVtbl->Release(dev->fence);
  if (dev->queue) dev->queue->lpVtbl->Release(dev->queue);
  if (dev->factory) dev->factory->lpVtbl->Release(dev->factory);
  if (dev->device) dev->device->lpVtbl->Release(dev->device);
  free(dev);
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_device_destroy(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  if (!dev) return;
  if (dev->queue && dev->fence) {
    dev->fence_value += 1;
    if (SUCCEEDED(dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value))) {
      if (dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value,
                                                   dev->fence_event) == S_OK) {
        WaitForSingleObject(dev->fence_event, 5000);
      }
    }
  }
  if (dev->info_queue) dev->info_queue->lpVtbl->Release(dev->info_queue);
  if (dev->fence_event) CloseHandle(dev->fence_event);
  if (dev->fence) dev->fence->lpVtbl->Release(dev->fence);
  if (dev->queue) dev->queue->lpVtbl->Release(dev->queue);
  if (dev->factory) dev->factory->lpVtbl->Release(dev->factory);
  if (dev->device) dev->device->lpVtbl->Release(dev->device);
  free(dev);
}

// Signals the fence and waits for the queue to drain. Required before releasing
// anything the GPU may still reference: the debug layer turns such a release
// into a CORRUPTION message (and an exception when a debugger is attached).
MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_wait_idle(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  HRESULT hr;
  if (!dev || !dev->queue || !dev->fence) return 0;
  dev->fence_value += 1;
  hr = dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  if (dev->fence->lpVtbl->GetCompletedValue(dev->fence) < dev->fence_value) {
    hr = dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value, dev->fence_event);
    set_hr(hr);
    if (FAILED(hr)) return 0;
    if (WaitForSingleObject(dev->fence_event, 30000) != WAIT_OBJECT_0) {
      g_last_hr = (HRESULT)0x80004004;
      return 0;
    }
  }
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_validation_errors(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  UINT64 i, n;
  int errors = 0;
  if (!dev || !dev->info_queue) return 0;
  n = dev->info_queue->lpVtbl->GetNumStoredMessages(dev->info_queue);
  for (i = 0; i < n; i++) {
    SIZE_T len = 0;
    if (SUCCEEDED(dev->info_queue->lpVtbl->GetMessage(dev->info_queue, i, NULL, &len)) && len) {
      D3D12_MESSAGE *m = (D3D12_MESSAGE *)malloc(len);
      if (m && SUCCEEDED(dev->info_queue->lpVtbl->GetMessage(dev->info_queue, i, m, &len))) {
        if (m->Severity == D3D12_MESSAGE_SEVERITY_ERROR ||
            m->Severity == D3D12_MESSAGE_SEVERITY_CORRUPTION) {
          errors++;
          if (errors <= 5) {
            fprintf(stderr, "[dx12] VALIDATION id=%d: %s\n", (int)m->ID, m->pDescription);
          }
        }
      }
      free(m);
    }
  }
  return errors;
}

// The raw ID3D12Device pointer, for the generated COM dispatch layer and any
// other interop that needs the real COM object.
MOONBIT_FFI_EXPORT uint64_t tycho_dx12_device_raw(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  return dev ? (uint64_t)(uintptr_t)dev->device : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_is_warp(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  return dev ? dev->is_warp : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_shader_model(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  return dev ? dev->shader_model : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_mesh_tier(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  return dev ? dev->mesh_tier : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_raytracing_tier(uint64_t p) {
  TychoDxDevice *dev = as_device(p);
  return dev ? dev->raytracing_tier : 0;
}

// ---------------------------------------------------------------------------
// Command list
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_commands_create(uint64_t dev_p) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxCommands *cmds;
  HRESULT hr;
  if (!dev) return 0;
  cmds = (TychoDxCommands *)calloc(1, sizeof(TychoDxCommands));
  if (!cmds) return 0;
  hr = dev->device->lpVtbl->CreateCommandAllocator(dev->device, D3D12_COMMAND_LIST_TYPE_DIRECT,
                                                   &kIID_ID3D12CommandAllocator,
                                                   (void **)&cmds->allocator);
  set_hr(hr);
  if (FAILED(hr)) {
    free(cmds);
    return 0;
  }
  hr = dev->device->lpVtbl->CreateCommandList(dev->device, 0, D3D12_COMMAND_LIST_TYPE_DIRECT,
                                              cmds->allocator, NULL,
                                              &kIID_ID3D12GraphicsCommandList,
                                              (void **)&cmds->list);
  set_hr(hr);
  if (FAILED(hr)) {
    cmds->allocator->lpVtbl->Release(cmds->allocator);
    free(cmds);
    return 0;
  }
  // A freshly created list is already recording; close it so begin() can reset.
  cmds->list->lpVtbl->Close(cmds->list);
  return (uint64_t)(uintptr_t)cmds;
}

MOONBIT_FFI_EXPORT void tycho_dx12_commands_destroy(uint64_t p) {
  TychoDxCommands *cmds = as_commands(p);
  if (!cmds) return;
  if (cmds->list) cmds->list->lpVtbl->Release(cmds->list);
  if (cmds->allocator) cmds->allocator->lpVtbl->Release(cmds->allocator);
  free(cmds);
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_commands_begin(uint64_t p) {
  TychoDxCommands *cmds = as_commands(p);
  HRESULT hr;
  if (!cmds) return 0;
  hr = cmds->allocator->lpVtbl->Reset(cmds->allocator);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  hr = cmds->list->lpVtbl->Reset(cmds->list, cmds->allocator, NULL);
  set_hr(hr);
  return SUCCEEDED(hr) ? 1 : 0;
}

// Resource state tracking. Every texture keeps its native state, so a transition
// is only emitted when the requested state actually differs; drawing into or
// copying from a texture whose state is wrong is rejected instead of silently
// producing corrupt frames.
static int texture_transition(TychoDxTexture *tex, int32_t state,
                              ID3D12GraphicsCommandList *list) {
  D3D12_RESOURCE_BARRIER barrier;
  D3D12_RESOURCE_STATES after = dx12_native_state(state);
  if (!tex || !list) return 0;
  if (tex->state == after) {
    tex->state_tag = state;
    return 1;
  }
  memset(&barrier, 0, sizeof barrier);
  barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
  barrier.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
  barrier.Transition.pResource = tex->resource;
  barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
  barrier.Transition.StateBefore = tex->state;
  barrier.Transition.StateAfter = after;
  list->lpVtbl->ResourceBarrier(list, 1, &barrier);
  tex->state = after;
  tex->state_tag = state;
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_transition(uint64_t cmd_p, uint64_t tex_p,
                                                     int32_t state) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds) return 0;
  return texture_transition(as_texture(tex_p), state, cmds->list);
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_texture_state(uint64_t tex_p) {
  TychoDxTexture *tex = as_texture(tex_p);
  return tex ? tex->state_tag : -1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_clear(uint64_t cmd_p, uint64_t tex_p, float r, float g,
                                                float b, float a) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  const float color[4] = {r, g, b, a};
  if (!cmds || !tex) return 0;
  if (tex->state != D3D12_RESOURCE_STATE_RENDER_TARGET) {
    g_last_hr = (HRESULT)0x8000000E;  // E_ILLEGAL_METHOD_CALL: clear before transition
    return 0;
  }
  cmds->list->lpVtbl->ClearRenderTargetView(cmds->list, tex->rtv, color, 0, NULL);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_cbv(uint64_t cmd_p, int32_t index,
                                                  uint64_t gpu_address) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || index < 0) return 0;
  cmds->list->lpVtbl->SetGraphicsRootConstantBufferView(cmds->list, (UINT)index,
                                                        (D3D12_GPU_VIRTUAL_ADDRESS)gpu_address);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_pipeline(uint64_t cmd_p, uint64_t pipe_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxPipeline *pipe = as_pipeline(pipe_p);
  if (!cmds || !pipe) return 0;
  cmds->list->lpVtbl->SetGraphicsRootSignature(cmds->list, pipe->root_signature);
  cmds->list->lpVtbl->SetPipelineState(cmds->list, pipe->pso);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_draw(uint64_t cmd_p, uint64_t tex_p, int32_t vertices,
                                              int32_t instances, int32_t flip_y) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  D3D12_VIEWPORT vp;
  D3D12_RECT scissor;
  if (!cmds || !tex) return 0;
  if (tex->state != D3D12_RESOURCE_STATE_RENDER_TARGET) {
    g_last_hr = (HRESULT)0x8000000E;  // E_ILLEGAL_METHOD_CALL: draw before transition
    return 0;
  }
  cmds->list->lpVtbl->OMSetRenderTargets(cmds->list, 1, &tex->rtv, FALSE, NULL);
  memset(&vp, 0, sizeof vp);
  vp.TopLeftX = 0.0f;
  // A negative viewport height maps NDC y=-1 to the first framebuffer row, which
  // is Vulkan's convention; content authored once then renders identically on
  // both backends without a shader-side flip.
  vp.TopLeftY = flip_y ? (float)tex->height : 0.0f;
  vp.Width = (float)tex->width;
  vp.Height = flip_y ? -(float)tex->height : (float)tex->height;
  vp.MinDepth = 0.0f;
  vp.MaxDepth = 1.0f;
  cmds->list->lpVtbl->RSSetViewports(cmds->list, 1, &vp);
  memset(&scissor, 0, sizeof scissor);
  scissor.right = tex->width;
  scissor.bottom = tex->height;
  cmds->list->lpVtbl->RSSetScissorRects(cmds->list, 1, &scissor);
  cmds->list->lpVtbl->IASetPrimitiveTopology(cmds->list,
                                             D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
  cmds->list->lpVtbl->DrawInstanced(cmds->list, (UINT)vertices,
                                    instances > 0 ? (UINT)instances : 1U, 0, 0);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_copy_to_readback(uint64_t cmd_p, uint64_t tex_p,
                                                           uint64_t rb_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  TychoDxReadback *rb = as_readback(rb_p);
  D3D12_TEXTURE_COPY_LOCATION dst;
  D3D12_TEXTURE_COPY_LOCATION src;
  if (!cmds || !tex || !rb) return 0;
  if (tex->state != D3D12_RESOURCE_STATE_COPY_SOURCE) {
    g_last_hr = (HRESULT)0x8000000E;  // E_ILLEGAL_METHOD_CALL: copy before transition
    return 0;
  }
  memset(&dst, 0, sizeof dst);
  dst.pResource = rb->resource;
  dst.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
  dst.PlacedFootprint.Offset = 0;
  dst.PlacedFootprint.Footprint.Format = TYCHO_DX12_RT_FORMAT;
  dst.PlacedFootprint.Footprint.Width = (UINT)rb->width;
  dst.PlacedFootprint.Footprint.Height = (UINT)rb->height;
  dst.PlacedFootprint.Footprint.Depth = 1;
  dst.PlacedFootprint.Footprint.RowPitch = rb->row_pitch;
  memset(&src, 0, sizeof src);
  src.pResource = tex->resource;
  src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
  src.SubresourceIndex = 0;
  cmds->list->lpVtbl->CopyTextureRegion(cmds->list, &dst, 0, 0, 0, &src, NULL);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_commands_execute_wait(uint64_t dev_p, uint64_t cmd_p) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxCommands *cmds = as_commands(cmd_p);
  HRESULT hr;
  DWORD wait_result;
  if (!dev || !cmds) return 0;
  hr = cmds->list->lpVtbl->Close(cmds->list);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  dev->queue->lpVtbl->ExecuteCommandLists(dev->queue, 1,
                                          (ID3D12CommandList *const *)&cmds->list);
  dev->fence_value += 1;
  hr = dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  if (dev->fence->lpVtbl->GetCompletedValue(dev->fence) < dev->fence_value) {
    hr = dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value, dev->fence_event);
    set_hr(hr);
    if (FAILED(hr)) return 0;
    wait_result = WaitForSingleObject(dev->fence_event, 30000);
    if (wait_result != WAIT_OBJECT_0) {
      g_last_hr = (HRESULT)0x80004004;  // E_ABORT: GPU wait timed out
      return 0;
    }
  }
  return 1;
}

// ---------------------------------------------------------------------------
// Pipeline (root signature with `cbv_count` root CBVs + graphics PSO from DXIL)
// ---------------------------------------------------------------------------

#define TYCHO_DX12_MAX_ROOT_CBVS 8

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_pipeline_create(uint64_t dev_p, const uint8_t *vs,
                                                       int32_t vs_len, const uint8_t *ps,
                                                       int32_t ps_len, int32_t cbv_count,
                                                       int32_t flip_y) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxPipeline *pipe;
  ID3DBlob *rs_blob = NULL;
  ID3DBlob *rs_err = NULL;
  D3D12_VERSIONED_ROOT_SIGNATURE_DESC rs_desc;
  D3D12_ROOT_PARAMETER root_params[TYCHO_DX12_MAX_ROOT_CBVS];
  D3D12_GRAPHICS_PIPELINE_STATE_DESC pso_desc;
  HRESULT hr;
  int i;
  if (!dev || !vs || !ps || vs_len <= 0 || ps_len <= 0) return 0;
  if (cbv_count < 0 || cbv_count > TYCHO_DX12_MAX_ROOT_CBVS) return 0;

  pipe = (TychoDxPipeline *)calloc(1, sizeof(TychoDxPipeline));
  if (!pipe) return 0;

  // Uniform slots map to root CBVs: slot i is register b<i> in space 0, which is
  // what `[[vk::binding(i, 0)]]` / `register(b<i>, space0)` compiles to on both
  // backends. Root CBVs need no descriptor heap, only a 256-byte aligned address.
  memset(root_params, 0, sizeof root_params);
  for (i = 0; i < cbv_count; i++) {
    root_params[i].ParameterType = D3D12_ROOT_PARAMETER_TYPE_CBV;
    root_params[i].Descriptor.ShaderRegister = (UINT)i;
    root_params[i].Descriptor.RegisterSpace = 0;
    root_params[i].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
  }
  memset(&rs_desc, 0, sizeof rs_desc);
  rs_desc.Version = D3D_ROOT_SIGNATURE_VERSION_1_0;
  rs_desc.Desc_1_0.NumParameters = (UINT)cbv_count;
  rs_desc.Desc_1_0.pParameters = cbv_count > 0 ? root_params : NULL;
  rs_desc.Desc_1_0.Flags = D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;
  hr = g_serialize_rs(&rs_desc, &rs_blob, &rs_err);
  set_hr(hr);
  if (FAILED(hr)) {
    if (rs_err) rs_err->lpVtbl->Release(rs_err);
    free(pipe);
    return 0;
  }
  hr = dev->device->lpVtbl->CreateRootSignature(
      dev->device, 0, rs_blob->lpVtbl->GetBufferPointer(rs_blob),
      rs_blob->lpVtbl->GetBufferSize(rs_blob), &kIID_ID3D12RootSignature,
      (void **)&pipe->root_signature);
  set_hr(hr);
  rs_blob->lpVtbl->Release(rs_blob);
  if (FAILED(hr)) {
    free(pipe);
    return 0;
  }

  memset(&pso_desc, 0, sizeof pso_desc);
  pso_desc.pRootSignature = pipe->root_signature;
  pso_desc.VS.pShaderBytecode = vs;
  pso_desc.VS.BytecodeLength = (SIZE_T)vs_len;
  pso_desc.PS.pShaderBytecode = ps;
  pso_desc.PS.BytecodeLength = (SIZE_T)ps_len;
  pso_desc.RasterizerState.FillMode = D3D12_FILL_MODE_SOLID;
  pso_desc.RasterizerState.CullMode = D3D12_CULL_MODE_NONE;
  // A flipped viewport mirrors the image, which reverses triangle winding, so the
  // front-face convention has to flip with it (see the negative viewport in
  // tycho_dx12_cmd_draw).
  pso_desc.RasterizerState.FrontCounterClockwise = flip_y ? TRUE : FALSE;
  pso_desc.RasterizerState.DepthBias = D3D12_DEFAULT_DEPTH_BIAS;
  pso_desc.RasterizerState.DepthBiasClamp = D3D12_DEFAULT_DEPTH_BIAS_CLAMP;
  pso_desc.RasterizerState.SlopeScaledDepthBias = D3D12_DEFAULT_SLOPE_SCALED_DEPTH_BIAS;
  pso_desc.RasterizerState.DepthClipEnable = TRUE;
  pso_desc.RasterizerState.MultisampleEnable = FALSE;
  pso_desc.RasterizerState.AntialiasedLineEnable = FALSE;
  pso_desc.RasterizerState.ForcedSampleCount = 0;
  pso_desc.RasterizerState.ConservativeRaster = D3D12_CONSERVATIVE_RASTERIZATION_MODE_OFF;
  pso_desc.BlendState.AlphaToCoverageEnable = FALSE;
  pso_desc.BlendState.IndependentBlendEnable = FALSE;
  {
    D3D12_RENDER_TARGET_BLEND_DESC *rt = &pso_desc.BlendState.RenderTarget[0];
    rt->BlendEnable = FALSE;
    rt->LogicOpEnable = FALSE;
    rt->SrcBlend = D3D12_BLEND_ONE;
    rt->DestBlend = D3D12_BLEND_ZERO;
    rt->BlendOp = D3D12_BLEND_OP_ADD;
    rt->SrcBlendAlpha = D3D12_BLEND_ONE;
    rt->DestBlendAlpha = D3D12_BLEND_ZERO;
    rt->BlendOpAlpha = D3D12_BLEND_OP_ADD;
    rt->LogicOp = D3D12_LOGIC_OP_NOOP;
    rt->RenderTargetWriteMask = D3D12_COLOR_WRITE_ENABLE_ALL;
  }
  pso_desc.DepthStencilState.DepthEnable = FALSE;
  pso_desc.DepthStencilState.StencilEnable = FALSE;
  pso_desc.SampleMask = UINT_MAX;
  pso_desc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
  pso_desc.NumRenderTargets = 1;
  pso_desc.RTVFormats[0] = TYCHO_DX12_RT_FORMAT;
  pso_desc.SampleDesc.Count = 1;
  pso_desc.SampleDesc.Quality = 0;
  hr = dev->device->lpVtbl->CreateGraphicsPipelineState(dev->device, &pso_desc,
                                                        &kIID_ID3D12PipelineState,
                                                        (void **)&pipe->pso);
  set_hr(hr);
  if (FAILED(hr)) {
    pipe->root_signature->lpVtbl->Release(pipe->root_signature);
    free(pipe);
    return 0;
  }
  (void)rs_err;
  return (uint64_t)(uintptr_t)pipe;
}

MOONBIT_FFI_EXPORT void tycho_dx12_pipeline_destroy(uint64_t p) {
  TychoDxPipeline *pipe = as_pipeline(p);
  if (!pipe) return;
  if (pipe->pso) pipe->pso->lpVtbl->Release(pipe->pso);
  if (pipe->root_signature) pipe->root_signature->lpVtbl->Release(pipe->root_signature);
  free(pipe);
}

// ---------------------------------------------------------------------------
// Render target texture / readback buffer
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_texture_create(uint64_t dev_p, int32_t width,
                                                      int32_t height) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxTexture *tex;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_DESCRIPTOR_HEAP_DESC heap_desc;
  D3D12_RENDER_TARGET_VIEW_DESC rtv_desc;
  HRESULT hr;
  if (!dev || width <= 0 || height <= 0) return 0;

  tex = (TychoDxTexture *)calloc(1, sizeof(TychoDxTexture));
  if (!tex) return 0;
  tex->width = width;
  tex->height = height;
  tex->state = D3D12_RESOURCE_STATE_COMMON;
  tex->state_tag = TYCHO_DX12_STATE_COMMON;
  tex->owned = 1;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
  heap.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
  heap.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
  desc.Alignment = 0;
  desc.Width = (UINT64)width;
  desc.Height = (UINT)height;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = TYCHO_DX12_RT_FORMAT;
  desc.SampleDesc.Count = 1;
  desc.SampleDesc.Quality = 0;
  desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
  desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;

  hr = dev->device->lpVtbl->CreateCommittedResource(dev->device, &heap,
                                                    D3D12_HEAP_FLAG_NONE, &desc,
                                                    D3D12_RESOURCE_STATE_COMMON, NULL,
                                                    &kIID_ID3D12Resource,
                                                    (void **)&tex->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(tex);
    return 0;
  }

  memset(&heap_desc, 0, sizeof heap_desc);
  heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
  heap_desc.NumDescriptors = 1;
  heap_desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
  hr = dev->device->lpVtbl->CreateDescriptorHeap(dev->device, &heap_desc,
                                                 &kIID_ID3D12DescriptorHeap,
                                                 (void **)&tex->rtv_heap);
  set_hr(hr);
  if (FAILED(hr)) {
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    return 0;
  }
  tex->rtv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(tex->rtv_heap, &tex->rtv);
  memset(&rtv_desc, 0, sizeof rtv_desc);
  rtv_desc.Format = TYCHO_DX12_RT_FORMAT;
  rtv_desc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
  dev->device->lpVtbl->CreateRenderTargetView(dev->device, tex->resource, &rtv_desc, tex->rtv);
  return (uint64_t)(uintptr_t)tex;
}

MOONBIT_FFI_EXPORT void tycho_dx12_texture_destroy(uint64_t p) {
  TychoDxTexture *tex = as_texture(p);
  if (!tex) return;
  if (tex->owned) {
    if (tex->rtv_heap) tex->rtv_heap->lpVtbl->Release(tex->rtv_heap);
    if (tex->resource) tex->resource->lpVtbl->Release(tex->resource);
  }
  free(tex);
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_readback_create(uint64_t dev_p, int32_t width,
                                                       int32_t height) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxReadback *rb;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  UINT64 bytes;
  UINT pitch;
  HRESULT hr;
  if (!dev || width <= 0 || height <= 0) return 0;

  rb = (TychoDxReadback *)calloc(1, sizeof(TychoDxReadback));
  if (!rb) return 0;
  rb->width = width;
  rb->height = height;
  pitch = (UINT)width * TYCHO_DX12_RT_FORMAT_PIXEL_BYTES;
  pitch = (pitch + (TYCHO_DX12_PITCH_ALIGNMENT - 1)) & ~(TYCHO_DX12_PITCH_ALIGNMENT - 1);
  rb->row_pitch = pitch;
  bytes = (UINT64)pitch * (UINT64)height;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_READBACK;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
  desc.Width = bytes;
  desc.Height = 1;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = DXGI_FORMAT_UNKNOWN;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
  desc.Flags = D3D12_RESOURCE_FLAG_NONE;

  hr = dev->device->lpVtbl->CreateCommittedResource(dev->device, &heap,
                                                    D3D12_HEAP_FLAG_NONE, &desc,
                                                    D3D12_RESOURCE_STATE_COPY_DEST, NULL,
                                                    &kIID_ID3D12Resource,
                                                    (void **)&rb->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(rb);
    return 0;
  }
  return (uint64_t)(uintptr_t)rb;
}

MOONBIT_FFI_EXPORT void tycho_dx12_readback_destroy(uint64_t p) {
  TychoDxReadback *rb = as_readback(p);
  if (!rb) return;
  if (rb->resource) rb->resource->lpVtbl->Release(rb->resource);
  free(rb);
}

// Copies the readback buffer into a tightly packed RGBA8 moonbit Bytes, dropping
// the 256-byte row pitch padding so the MoonBit side sees plain w*h*4 pixels.
MOONBIT_FFI_EXPORT moonbit_bytes_t tycho_dx12_readback_bytes(uint64_t p) {
  TychoDxReadback *rb = as_readback(p);
  uint32_t row_bytes;
  uint32_t total;
  moonbit_bytes_t out;
  void *mapped = NULL;
  D3D12_RANGE range;
  int y;
  if (!rb) return moonbit_make_bytes(0, 0);
  row_bytes = (uint32_t)rb->width * TYCHO_DX12_RT_FORMAT_PIXEL_BYTES;
  total = row_bytes * (uint32_t)rb->height;
  out = moonbit_make_bytes(total, 0);
  if (!out) return out;
  memset(&range, 0, sizeof range);
  range.Begin = 0;
  range.End = (SIZE_T)rb->row_pitch * (SIZE_T)rb->height;
  if (FAILED(rb->resource->lpVtbl->Map(rb->resource, 0, &range, &mapped)) || !mapped) {
    return moonbit_make_bytes(0, 0);
  }
  for (y = 0; y < rb->height; y++) {
    memcpy(out + (size_t)y * row_bytes,
           (const uint8_t *)mapped + (size_t)y * rb->row_pitch, row_bytes);
  }
  memset(&range, 0, sizeof range);
  range.Begin = 0;
  range.End = 0;
  rb->resource->lpVtbl->Unmap(rb->resource, 0, &range);
  return out;
}

// ---------------------------------------------------------------------------
// Upload (CPU-visible) buffers
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_create(uint64_t dev_p, int32_t size) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxBuffer *buf;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  void *mapped = NULL;
  HRESULT hr;
  if (!dev || size <= 0) return 0;

  buf = (TychoDxBuffer *)calloc(1, sizeof(TychoDxBuffer));
  if (!buf) return 0;
  buf->size = size;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_UPLOAD;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
  desc.Width = (UINT64)size;
  desc.Height = 1;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = DXGI_FORMAT_UNKNOWN;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
  desc.Flags = D3D12_RESOURCE_FLAG_NONE;

  hr = dev->device->lpVtbl->CreateCommittedResource(dev->device, &heap, D3D12_HEAP_FLAG_NONE,
                                                    &desc, D3D12_RESOURCE_STATE_GENERIC_READ, NULL,
                                                    &kIID_ID3D12Resource,
                                                    (void **)&buf->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(buf);
    return 0;
  }
  if (FAILED(buf->resource->lpVtbl->Map(buf->resource, 0, NULL, &mapped)) || !mapped) {
    buf->resource->lpVtbl->Release(buf->resource);
    free(buf);
    return 0;
  }
  buf->mapped = mapped;
  return (uint64_t)(uintptr_t)buf;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_write(uint64_t buf_p, int32_t offset,
                                                   const uint8_t *data, int32_t len) {
  TychoDxBuffer *buf = as_buffer(buf_p);
  if (!buf || !buf->mapped || !data || len < 0 || offset < 0) return 0;
  if ((int64_t)offset + (int64_t)len > (int64_t)buf->size) return 0;
  memcpy((uint8_t *)buf->mapped + offset, data, (size_t)len);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_write_floats(uint64_t buf_p, int32_t offset,
                                                          const float *data, int32_t count) {
  if (count < 0) return 0;
  return tycho_dx12_buffer_write(buf_p, offset, (const uint8_t *)data, count * 4);
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_gpu_address(uint64_t buf_p) {
  TychoDxBuffer *buf = as_buffer(buf_p);
  if (!buf || !buf->resource) return 0;
  return (uint64_t)buf->resource->lpVtbl->GetGPUVirtualAddress(buf->resource);
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_size(uint64_t buf_p) {
  TychoDxBuffer *buf = as_buffer(buf_p);
  return buf ? buf->size : 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_buffer_destroy(uint64_t buf_p) {
  TychoDxBuffer *buf = as_buffer(buf_p);
  if (!buf) return;
  if (buf->resource) {
    if (buf->mapped) {
      buf->resource->lpVtbl->Unmap(buf->resource, 0, NULL);
    }
    buf->resource->lpVtbl->Release(buf->resource);
  }
  free(buf);
}

// ---------------------------------------------------------------------------
// DXGI flip-model swapchain (window presentation)
// ---------------------------------------------------------------------------

static void swapchain_release_views(TychoDxSwapchain *sc) {
  if (!sc) return;
  if (sc->rtv_heap) {
    sc->rtv_heap->lpVtbl->Release(sc->rtv_heap);
    sc->rtv_heap = NULL;
  }
  sc->has_views = 0;
}

static int swapchain_create_views(TychoDxDevice *dev, TychoDxSwapchain *sc) {
  D3D12_DESCRIPTOR_HEAP_DESC heap_desc;
  HRESULT hr;
  UINT increment;
  UINT i;

  swapchain_release_views(sc);
  memset(&heap_desc, 0, sizeof heap_desc);
  heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
  heap_desc.NumDescriptors = TYCHO_DX12_FRAME_COUNT;
  heap_desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
  hr = dev->device->lpVtbl->CreateDescriptorHeap(dev->device, &heap_desc,
                                                 &kIID_ID3D12DescriptorHeap,
                                                 (void **)&sc->rtv_heap);
  set_hr(hr);
  if (FAILED(hr)) return 0;

  increment = dev->device->lpVtbl->GetDescriptorHandleIncrementSize(
      dev->device, D3D12_DESCRIPTOR_HEAP_TYPE_RTV);
  for (i = 0; i < TYCHO_DX12_FRAME_COUNT; i++) {
    ID3D12Resource *buffer = NULL;
    D3D12_RENDER_TARGET_VIEW_DESC rtv_desc;
    D3D12_CPU_DESCRIPTOR_HANDLE handle;
    hr = sc->swapchain->lpVtbl->GetBuffer(sc->swapchain, i, &kIID_ID3D12Resource,
                                          (void **)&buffer);
    set_hr(hr);
    if (FAILED(hr)) {
      swapchain_release_views(sc);
      return 0;
    }
    {
      D3D12_CPU_DESCRIPTOR_HANDLE base;
      sc->rtv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(sc->rtv_heap, &base);
      handle.ptr = base.ptr + (SIZE_T)i * increment;
    }
    sc->rtv[i] = handle;
    memset(&rtv_desc, 0, sizeof rtv_desc);
    rtv_desc.Format = TYCHO_DX12_RT_FORMAT;
    rtv_desc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
    dev->device->lpVtbl->CreateRenderTargetView(dev->device, buffer, &rtv_desc, handle);
    buffer->lpVtbl->Release(buffer);
  }
  sc->has_views = 1;
  return 1;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_swapchain_create(uint64_t dev_p, uint64_t hwnd,
                                                        int32_t width, int32_t height) {
  TychoDxDevice *dev = as_device(dev_p);
  DXGI_SWAP_CHAIN_DESC1 desc;
  IDXGISwapChain1 *swapchain1 = NULL;
  TychoDxSwapchain *sc;
  HRESULT hr;
  if (!dev || !dev->factory || !hwnd || width <= 0 || height <= 0) return 0;

  sc = (TychoDxSwapchain *)calloc(1, sizeof(TychoDxSwapchain));
  if (!sc) return 0;

  memset(&desc, 0, sizeof desc);
  desc.Width = (UINT)width;
  desc.Height = (UINT)height;
  desc.Format = TYCHO_DX12_RT_FORMAT;
  desc.Stereo = FALSE;
  desc.SampleDesc.Count = 1;
  desc.SampleDesc.Quality = 0;
  desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  desc.BufferCount = TYCHO_DX12_FRAME_COUNT;
  desc.Scaling = DXGI_SCALING_STRETCH;
  desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
  desc.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
  desc.Flags = 0;

  hr = dev->factory->lpVtbl->CreateSwapChainForHwnd(dev->factory, (IUnknown *)dev->queue,
                                                    (HWND)(uintptr_t)hwnd, &desc, NULL, NULL,
                                                    &swapchain1);
  set_hr(hr);
  if (FAILED(hr)) {
    free(sc);
    return 0;
  }
  // A test window must not be thrown into exclusive fullscreen by Alt+Enter.
  dev->factory->lpVtbl->MakeWindowAssociation(dev->factory, (HWND)(uintptr_t)hwnd,
                                              DXGI_MWA_NO_ALT_ENTER);
  hr = swapchain1->lpVtbl->QueryInterface(swapchain1, &kIID_IDXGISwapChain3,
                                          (void **)&sc->swapchain);
  swapchain1->lpVtbl->Release(swapchain1);
  set_hr(hr);
  if (FAILED(hr)) {
    free(sc);
    return 0;
  }
  sc->width = (UINT)width;
  sc->height = (UINT)height;
  if (!swapchain_create_views(dev, sc)) {
    sc->swapchain->lpVtbl->Release(sc->swapchain);
    free(sc);
    return 0;
  }
  return (uint64_t)(uintptr_t)sc;
}

MOONBIT_FFI_EXPORT void tycho_dx12_swapchain_destroy(uint64_t p) {
  TychoDxSwapchain *sc = as_swapchain(p);
  if (!sc) return;
  swapchain_release_views(sc);
  if (sc->swapchain) sc->swapchain->lpVtbl->Release(sc->swapchain);
  free(sc);
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_width(uint64_t p) {
  TychoDxSwapchain *sc = as_swapchain(p);
  return sc ? (int32_t)sc->width : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_height(uint64_t p) {
  TychoDxSwapchain *sc = as_swapchain(p);
  return sc ? (int32_t)sc->height : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_current_index(uint64_t p) {
  TychoDxSwapchain *sc = as_swapchain(p);
  return sc ? (int32_t)sc->swapchain->lpVtbl->GetCurrentBackBufferIndex(sc->swapchain) : -1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_present(uint64_t p) {
  TychoDxSwapchain *sc = as_swapchain(p);
  HRESULT hr;
  if (!sc) return 0;
  hr = sc->swapchain->lpVtbl->Present(sc->swapchain, 1, 0);
  if (hr == DXGI_STATUS_OCCLUDED) {
    return 2;  // presented, but the window is not visible: not an error
  }
  set_hr(hr);
  return SUCCEEDED(hr) ? 1 : 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_swapchain_target(uint64_t p, int32_t index) {
  TychoDxSwapchain *sc = as_swapchain(p);
  ID3D12Resource *buffer = NULL;
  TychoDxTexture *tex;
  HRESULT hr;
  if (!sc || !sc->has_views || index < 0 || index >= TYCHO_DX12_FRAME_COUNT) return 0;
  hr = sc->swapchain->lpVtbl->GetBuffer(sc->swapchain, (UINT)index, &kIID_ID3D12Resource,
                                        (void **)&buffer);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  tex = (TychoDxTexture *)calloc(1, sizeof(TychoDxTexture));
  if (!tex) {
    buffer->lpVtbl->Release(buffer);
    return 0;
  }
  // Borrowed view: the swapchain owns the resource and the descriptor heap, and
  // a freshly presented back buffer is already in the PRESENT state.
  tex->resource = buffer;
  tex->rtv = sc->rtv[index];
  tex->state = D3D12_RESOURCE_STATE_PRESENT;
  tex->state_tag = TYCHO_DX12_STATE_PRESENT;
  tex->width = (int)sc->width;
  tex->height = (int)sc->height;
  tex->owned = 0;
  // The wrapper no longer owns the reference GetBuffer just handed out.
  buffer->lpVtbl->Release(buffer);
  return (uint64_t)(uintptr_t)tex;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_resize(uint64_t dev_p, uint64_t p, int32_t width,
                                                       int32_t height) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxSwapchain *sc = as_swapchain(p);
  HRESULT hr;
  DWORD wait_result;
  if (!dev || !sc || width <= 0 || height <= 0) return 0;

  // All back buffers must be released before ResizeBuffers.
  swapchain_release_views(sc);
  dev->fence_value += 1;
  hr = dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  if (dev->fence->lpVtbl->GetCompletedValue(dev->fence) < dev->fence_value) {
    hr = dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value, dev->fence_event);
    set_hr(hr);
    if (FAILED(hr)) return 0;
    wait_result = WaitForSingleObject(dev->fence_event, 30000);
    if (wait_result != WAIT_OBJECT_0) {
      g_last_hr = (HRESULT)0x80004004;
      return 0;
    }
  }

  hr = sc->swapchain->lpVtbl->ResizeBuffers(sc->swapchain, 0, (UINT)width, (UINT)height,
                                            DXGI_FORMAT_UNKNOWN, 0);
  set_hr(hr);
  if (FAILED(hr)) return 0;
  sc->width = (UINT)width;
  sc->height = (UINT)height;
  return swapchain_create_views(dev, sc) ? 1 : 0;
}

#else  // !defined(_WIN32)

// Non-Windows hosts: keep the package buildable, every entry point reports
// "no Direct3D 12 here" so callers can SKIP instead of failing.

MOONBIT_FFI_EXPORT int32_t tycho_dx12_init(void) { return 0; }

MOONBIT_FFI_EXPORT int32_t tycho_dx12_last_error(void) { return 0; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_as_ptr(const void *p) {
  return (uint64_t)(uintptr_t)p;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_env_requests_warp(void) { return 0; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_device_create(int32_t use_warp, int32_t debug) {
  (void)use_warp;
  (void)debug;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_device_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_validation_errors(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_wait_idle(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_is_warp(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_device_raw(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_shader_model(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_mesh_tier(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_device_raytracing_tier(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_commands_create(uint64_t dev) {
  (void)dev;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_commands_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT int32_t tycho_dx12_commands_begin(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_transition(uint64_t cmd, uint64_t tex, int32_t state) {
  (void)cmd;
  (void)tex;
  (void)state;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_texture_state(uint64_t tex) {
  (void)tex;
  return -1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_clear(uint64_t cmd, uint64_t tex, float r, float g,
                                                float b, float a) {
  (void)cmd;
  (void)tex;
  (void)r;
  (void)g;
  (void)b;
  (void)a;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_pipeline(uint64_t cmd, uint64_t pipe) {
  (void)cmd;
  (void)pipe;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_draw(uint64_t cmd, uint64_t tex, int32_t vertices,
                                              int32_t instances, int32_t flip_y) {
  (void)cmd;
  (void)tex;
  (void)vertices;
  (void)instances;
  (void)flip_y;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_cbv(uint64_t cmd, int32_t index,
                                                  uint64_t gpu_address) {
  (void)cmd;
  (void)index;
  (void)gpu_address;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_create(uint64_t dev, int32_t size) {
  (void)dev;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_write(uint64_t buf, int32_t offset,
                                                   const uint8_t *data, int32_t len) {
  (void)buf;
  (void)offset;
  (void)data;
  (void)len;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_write_floats(uint64_t buf, int32_t offset,
                                                          const float *data, int32_t count) {
  (void)buf;
  (void)offset;
  (void)data;
  (void)count;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_gpu_address(uint64_t buf) {
  (void)buf;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_size(uint64_t buf) {
  (void)buf;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_buffer_destroy(uint64_t buf) { (void)buf; }

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_copy_to_readback(uint64_t cmd, uint64_t tex,
                                                           uint64_t rb) {
  (void)cmd;
  (void)tex;
  (void)rb;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_commands_execute_wait(uint64_t dev, uint64_t cmd) {
  (void)dev;
  (void)cmd;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_pipeline_create(uint64_t dev, const uint8_t *vs,
                                                       int32_t vs_len, const uint8_t *ps,
                                                       int32_t ps_len, int32_t cbv_count,
                                                       int32_t flip_y) {
  (void)dev;
  (void)vs;
  (void)vs_len;
  (void)ps;
  (void)ps_len;
  (void)cbv_count;
  (void)flip_y;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_pipeline_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_texture_create(uint64_t dev, int32_t width,
                                                      int32_t height) {
  (void)dev;
  (void)width;
  (void)height;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_texture_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_readback_create(uint64_t dev, int32_t width,
                                                       int32_t height) {
  (void)dev;
  (void)width;
  (void)height;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_readback_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT moonbit_bytes_t tycho_dx12_readback_bytes(uint64_t p) {
  (void)p;
  return moonbit_make_bytes(0, 0);
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_swapchain_create(uint64_t dev, uint64_t hwnd,
                                                        int32_t width, int32_t height) {
  (void)dev;
  (void)hwnd;
  (void)width;
  (void)height;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_swapchain_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_width(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_height(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_current_index(uint64_t p) {
  (void)p;
  return -1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_present(uint64_t p) {
  (void)p;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_swapchain_target(uint64_t p, int32_t index) {
  (void)p;
  (void)index;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_swapchain_resize(uint64_t dev, uint64_t p, int32_t width,
                                                       int32_t height) {
  (void)dev;
  (void)p;
  (void)width;
  (void)height;
  return 0;
}

#endif  // defined(_WIN32)
