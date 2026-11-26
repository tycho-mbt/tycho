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
static const GUID kIID_ID3D12CommandSignature = {
    0xc36a797c, 0xec80, 0x4f0a, {0x89, 0x85, 0xa7, 0xb2, 0x47, 0x50, 0x82, 0xd1}};
static const GUID kIID_ID3D12QueryHeap = {
    0x0d9658ae, 0xed45, 0x469e, {0xa6, 0x1d, 0x97, 0x0e, 0xc5, 0x83, 0xca, 0xb4}};
static const GUID kIID_ID3D12Heap = {0x6b3b2502, 0x6e51, 0x45b3,
                                    {0x90, 0xee, 0x98, 0x84, 0x26, 0x5e, 0x8d, 0xf3}};
static const GUID kIID_IDXGISwapChain3 = {0x94d99bdb, 0xf1f8, 0x4ab0,
                                          {0xb2, 0x36, 0x7d, 0xa0, 0x17, 0x0e, 0xda, 0xb1}};

#define TYCHO_DX12_RT_FORMAT DXGI_FORMAT_R8G8B8A8_UNORM
#define TYCHO_DX12_DEPTH_FORMAT DXGI_FORMAT_D32_FLOAT
#define TYCHO_DX12_RT_FORMAT_PIXEL_BYTES 4
#define TYCHO_DX12_PITCH_ALIGNMENT 256
#define TYCHO_DX12_FRAME_COUNT 3
#define TYCHO_DX12_SRV_HEAP_SIZE 128
#define TYCHO_DX12_SAMPLER_HEAP_SIZE 16

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
  TYCHO_DX12_STATE_DEPTH_WRITE = 7,
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
    case TYCHO_DX12_STATE_DEPTH_WRITE:
      return D3D12_RESOURCE_STATE_DEPTH_WRITE;
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
  // Shader-visible CBV/SRV/UAV heap: one slot per uploaded texture, allocated
  // lazily (see ensure_srv_heap). A per-frame ring is the next step once
  // transient descriptors appear.
  ID3D12DescriptorHeap *srv_heap;
  UINT srv_increment;
  UINT srv_capacity;
  UINT srv_used;
  UINT srv_free[TYCHO_DX12_SRV_HEAP_SIZE];
  UINT srv_free_count;
  // Samplers live in their own heap. The shader declares `SamplerState` at
  // s0, which D3D treats as a descriptor range (a static sampler in the root
  // signature is not accepted for it), so slot 0 holds one linear/clamp
  // sampler and the root signature exposes it as a table.
  ID3D12DescriptorHeap *sampler_heap;
  UINT sampler_increment;
  UINT sampler_capacity;
  UINT sampler_used;
  UINT sampler_free[TYCHO_DX12_SAMPLER_HEAP_SIZE];
  UINT sampler_free_count;
  // One command signature per argument layout, created on first use.
  // 0 = draw, 1 = draw-indexed, 2 = dispatch.
  ID3D12CommandSignature *indirect_sig[3];
  UINT64 timestamp_freq;
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
  DXGI_FORMAT format;
  ID3D12DescriptorHeap *rtv_heap;  // owned by the wrapper unless `owned` is 0
  D3D12_CPU_DESCRIPTOR_HANDLE rtv;
  ID3D12DescriptorHeap *dsv_heap;
  D3D12_CPU_DESCRIPTOR_HANDLE dsv;
  int is_depth;
  D3D12_RESOURCE_STATES state;  // native state, what the barriers need
  int state_tag;                // typed enum reported across the FFI
  int width;
  int height;
  int owned;  // 0 for swapchain back buffers, whose lifetime is the swapchain's
  UINT srv_slot;  // slot in the device's shader-visible heap
  int has_srv;
  int srv_is_uav;  // the slot holds an UAV instead of an SRV
  struct TychoDxDevice *srv_device;  // heap owner, for slot recycling
} TychoDxTexture;

// CPU-visible (UPLOAD heap) buffer, persistently mapped. Uniform data is the
// only consumer today; it is bound as a root CBV so no descriptor heap is
// needed.
// A sampler slot in the device's shader-visible sampler heap.
typedef struct TychoDxSampler {
  UINT slot;
  struct TychoDxDevice *dev;  // heap owner, for slot recycling
} TychoDxSampler;

typedef struct TychoDxBuffer {
  ID3D12Resource *resource;
  void *mapped;
  int size;
  int placed;  // 1 when the resource lives inside a TychoDxBufferHeap
  UINT uav_slot;
  int has_uav;
  struct TychoDxDevice *uav_device;  // heap owner, for slot recycling
} TychoDxBuffer;

// A UPLOAD heap that placed buffers are carved out of: the free-list lives on
// the MoonBit side (RegionPool), this only owns the native objects.
typedef struct TychoDxBufferHeap {
  ID3D12Heap *heap;
  ID3D12Device *device;  // held for CreatePlacedResource
  int size;
} TychoDxBufferHeap;

// A TIMESTAMP query heap plus its READBACK-side staging buffer, so resolving
// is a single ResolveQueryData and reading is a plain memcpy afterwards.
typedef struct TychoDxTimestampPool {
  ID3D12QueryHeap *heap;
  ID3D12Resource *readback;
  UINT64 *mapped;
  UINT count;
  UINT64 frequency;
} TychoDxTimestampPool;

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
  struct TychoDxDevice *dev;     // owns the shader-visible SRV heap
  struct TychoDxTexture *depth;  // optional DSV bound by cmd_set_target
  // Colour targets, in MRT order. `cmd_draw`'s texture argument is slot 0; the
  // extra slots come from `cmd_set_extra_targets`.
  struct TychoDxTexture *targets[4];
  int target_count;
} TychoDxCommands;

static TychoDxDevice *as_device(uint64_t p) { return (TychoDxDevice *)(uintptr_t)p; }
static TychoDxPipeline *as_pipeline(uint64_t p) { return (TychoDxPipeline *)(uintptr_t)p; }
static TychoDxTexture *as_texture(uint64_t p) { return (TychoDxTexture *)(uintptr_t)p; }
static TychoDxReadback *as_readback(uint64_t p) { return (TychoDxReadback *)(uintptr_t)p; }
static void dump_info_queue(TychoDxDevice *dev, const char *what);

static TychoDxCommands *as_commands(uint64_t p) { return (TychoDxCommands *)(uintptr_t)p; }
static TychoDxSwapchain *as_swapchain(uint64_t p) { return (TychoDxSwapchain *)(uintptr_t)p; }
static TychoDxBuffer *as_buffer(uint64_t p) { return (TychoDxBuffer *)(uintptr_t)p; }
static TychoDxSampler *as_sampler(uint64_t p) { return (TychoDxSampler *)(uintptr_t)p; }
static TychoDxBufferHeap *as_buffer_heap(uint64_t p) {
  return (TychoDxBufferHeap *)(uintptr_t)p;
}
static TychoDxTimestampPool *as_timestamp_pool(uint64_t p) {
  return (TychoDxTimestampPool *)(uintptr_t)p;
}

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
  {
    int sig;
    for (sig = 0; sig < 3; sig++) {
      if (dev->indirect_sig[sig]) dev->indirect_sig[sig]->lpVtbl->Release(dev->indirect_sig[sig]);
    }
  }
  if (dev->sampler_heap) dev->sampler_heap->lpVtbl->Release(dev->sampler_heap);
  if (dev->srv_heap) dev->srv_heap->lpVtbl->Release(dev->srv_heap);
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
  if (dev->sampler_heap) dev->sampler_heap->lpVtbl->Release(dev->sampler_heap);
  if (dev->srv_heap) dev->srv_heap->lpVtbl->Release(dev->srv_heap);
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
    fprintf(stderr, "[tycho-dx12] CreateCommandAllocator failed: 0x%08lX\n", (unsigned long)hr);
    dump_info_queue(dev, "CreateCommandAllocator");
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
  cmds->dev = dev;
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

// State every draw needs: render target (plus depth), viewport, scissor and
// topology. Indexed and procedural draws share it so they cannot drift apart.
static int dx12_prepare_draw(TychoDxCommands *cmds, TychoDxTexture *tex, int32_t flip_y) {
  D3D12_VIEWPORT vp;
  D3D12_RECT scissor;
  if (!cmds || !tex) return 0;
  if (tex->state != D3D12_RESOURCE_STATE_RENDER_TARGET) {
    g_last_hr = (HRESULT)0x8000000E;  // E_ILLEGAL_METHOD_CALL: draw before transition
    return 0;
  }
  {
    // Slot 0 is the texture the draw names; slots 1..3 come from
    // `cmd_set_extra_targets` (multi-render-target passes).
    D3D12_CPU_DESCRIPTOR_HANDLE rtvs[4];
    UINT bound = 0;
    int slot;
    rtvs[bound++] = tex->rtv;
    for (slot = 1; slot < 4; slot++) {
      if (cmds->targets[slot]) {
        rtvs[bound++] = cmds->targets[slot]->rtv;
      }
    }
    cmds->list->lpVtbl->OMSetRenderTargets(cmds->list, bound, rtvs, FALSE,
                                          cmds->depth ? &cmds->depth->dsv : NULL);
  }
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
  return 1;
}

// Extra colour targets for MRT: slot 0 always comes from the draw call, these fill
// slots 1..3. Passing 0 clears a slot.
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_extra_targets(uint64_t cmd_p, uint64_t t1,
                                                            uint64_t t2, uint64_t t3) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds) return 0;
  cmds->targets[1] = as_texture(t1);
  cmds->targets[2] = as_texture(t2);
  cmds->targets[3] = as_texture(t3);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_draw(uint64_t cmd_p, uint64_t tex_p, int32_t vertices,
                                              int32_t instances, int32_t flip_y) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!dx12_prepare_draw(cmds, as_texture(tex_p), flip_y)) return 0;
  cmds->list->lpVtbl->DrawInstanced(cmds->list, (UINT)vertices,
                                    instances > 0 ? (UINT)instances : 1U, 0, 0);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_draw_indexed(uint64_t cmd_p, uint64_t tex_p,
                                                       int32_t index_count, int32_t instances,
                                                       int32_t first_index,
                                                       int32_t vertex_offset, int32_t flip_y) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!dx12_prepare_draw(cmds, as_texture(tex_p), flip_y)) return 0;
  cmds->list->lpVtbl->DrawIndexedInstanced(cmds->list, (UINT)index_count,
                                           instances > 0 ? (UINT)instances : 1U,
                                           (UINT)first_index, vertex_offset, 0);
  return 1;
}

// Vertex/index buffers are plain GPU addresses; the stride is a pipeline
// property (D3D12 needs it per binding, Vulkan takes it from the pipeline too).
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_bind_vertex(uint64_t cmd_p, int32_t slot,
                                                      uint64_t gpu_address, int32_t size,
                                                      int32_t stride) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  D3D12_VERTEX_BUFFER_VIEW view;
  if (!cmds || slot < 0 || size <= 0 || stride <= 0) return 0;
  memset(&view, 0, sizeof view);
  view.BufferLocation = (D3D12_GPU_VIRTUAL_ADDRESS)gpu_address;
  view.SizeInBytes = (UINT)size;
  view.StrideInBytes = (UINT)stride;
  cmds->list->lpVtbl->IASetVertexBuffers(cmds->list, (UINT)slot, 1, &view);
  return 1;
}

// `index32` selects R32_UINT over R16_UINT.
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_bind_index(uint64_t cmd_p, uint64_t gpu_address,
                                                     int32_t size, int32_t index32) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  D3D12_INDEX_BUFFER_VIEW view;
  if (!cmds || size <= 0) return 0;
  memset(&view, 0, sizeof view);
  view.BufferLocation = (D3D12_GPU_VIRTUAL_ADDRESS)gpu_address;
  view.SizeInBytes = (UINT)size;
  view.Format = index32 ? DXGI_FORMAT_R32_UINT : DXGI_FORMAT_R16_UINT;
  cmds->list->lpVtbl->IASetIndexBuffer(cmds->list, &view);
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
  dst.PlacedFootprint.Footprint.Format = tex->format;
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

// Prints the stored debug-layer messages. Kept in the shim because the layer's
// diagnostics are the difference between "E_INVALIDARG" and a fixable message.
static void dump_info_queue(TychoDxDevice *dev, const char *what) {
  UINT64 count;
  UINT64 i;
  if (!dev || !dev->info_queue) return;
  count = dev->info_queue->lpVtbl->GetNumStoredMessages(dev->info_queue);
  fprintf(stderr, "[tycho-dx12] %s failed; debug layer stored %llu message(s)\n", what,
          (unsigned long long)count);
  for (i = 0; i < count && i < 8; i++) {
    SIZE_T len = 0;
    if (SUCCEEDED(dev->info_queue->lpVtbl->GetMessage(dev->info_queue, i, NULL, &len)) && len) {
      D3D12_MESSAGE *msg = (D3D12_MESSAGE *)malloc(len);
      if (msg && SUCCEEDED(dev->info_queue->lpVtbl->GetMessage(dev->info_queue, i, msg, &len))) {
        fprintf(stderr, "[tycho-dx12]   [sev=%d id=%d] %s\n", (int)msg->Severity,
                (int)msg->ID, msg->pDescription);
      }
      if (msg) free(msg);
    }
  }
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_pipeline_create(uint64_t dev_p, const uint8_t *vs,
                                                       int32_t vs_len, const uint8_t *ps,
                                                       int32_t ps_len, int32_t cbv_count,
                                                       int32_t flip_y, int32_t depth_enable,
                                                       int32_t depth_write,
                                                       int32_t srv_tables,
                                                       int32_t push_bytes,
                                                       int32_t color_count,
                                                       const int32_t *color_formats,
                                                       int32_t input_count,
                                                       const int32_t *inputs) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxPipeline *pipe;
  ID3DBlob *rs_blob = NULL;
  ID3DBlob *rs_err = NULL;
  D3D12_VERSIONED_ROOT_SIGNATURE_DESC rs_desc;
  D3D12_ROOT_PARAMETER root_params[TYCHO_DX12_MAX_ROOT_CBVS + 3];
  D3D12_DESCRIPTOR_RANGE srv_ranges[8];
  D3D12_DESCRIPTOR_RANGE sampler_range;
  D3D12_INPUT_ELEMENT_DESC *input_elements = NULL;
  int input_index;
  D3D12_GRAPHICS_PIPELINE_STATE_DESC pso_desc;
  HRESULT hr;
  int i;
  if (!dev || !vs || !ps || vs_len <= 0 || ps_len <= 0) return 0;
  if (cbv_count < 0 || cbv_count > TYCHO_DX12_MAX_ROOT_CBVS) return 0;
  if (srv_tables < 0 || srv_tables > 8) return 0;
  if (push_bytes < 0 || push_bytes > 256 || (push_bytes % 4) != 0) return 0;
  if (input_count < 0 || (input_count > 0 && !inputs)) return 0;

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
  rs_desc.Desc_1_0.Flags = D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;
  if (srv_tables > 0) {
    // One single-descriptor table per texture slot: each slot is bound to its own
    // heap entry, so textures do not have to be contiguous in the heap. The
    // sampler table follows the slots.
    int slot;
    if (srv_tables > 8) return 0;
    for (slot = 0; slot < srv_tables; slot++) {
      memset(&srv_ranges[slot], 0, sizeof srv_ranges[slot]);
      srv_ranges[slot].RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
      srv_ranges[slot].NumDescriptors = 1;
      srv_ranges[slot].BaseShaderRegister = (UINT)slot;
      srv_ranges[slot].RegisterSpace = 0;
      srv_ranges[slot].OffsetInDescriptorsFromTableStart = 0;
      root_params[cbv_count + slot].ParameterType =
          D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
      root_params[cbv_count + slot].DescriptorTable.NumDescriptorRanges = 1;
      root_params[cbv_count + slot].DescriptorTable.pDescriptorRanges = &srv_ranges[slot];
      root_params[cbv_count + slot].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
    }
    memset(&sampler_range, 0, sizeof sampler_range);
    sampler_range.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
    sampler_range.NumDescriptors = 1;
    sampler_range.BaseShaderRegister = 0;
    sampler_range.RegisterSpace = 0;
    sampler_range.OffsetInDescriptorsFromTableStart = 0;
    root_params[cbv_count + srv_tables].ParameterType =
        D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
    root_params[cbv_count + srv_tables].DescriptorTable.NumDescriptorRanges = 1;
    root_params[cbv_count + srv_tables].DescriptorTable.pDescriptorRanges = &sampler_range;
    root_params[cbv_count + srv_tables].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
  }
  {
    // Push constants have no D3D12 equivalent, so they map to root constants at
    // `b15, space0`; a Slang shader pins them there with
    // `[[vk::push_constant]] ConstantBuffer<T> pc : register(b15, space0);`
    // (verified: the DXIL resource binds at cb15).
    int push_index = cbv_count + srv_tables + (srv_tables > 0 ? 1 : 0);
    if (push_bytes > 0) {
      root_params[push_index].ParameterType = D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
      root_params[push_index].Constants.ShaderRegister = 15;
      root_params[push_index].Constants.RegisterSpace = 0;
      root_params[push_index].Constants.Num32BitValues = (UINT)(push_bytes / 4);
      root_params[push_index].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
    }
    rs_desc.Desc_1_0.NumParameters = (UINT)(cbv_count + srv_tables +
                                            (srv_tables > 0 ? 1 : 0) +
                                            (push_bytes > 0 ? 1 : 0));
  }
  rs_desc.Desc_1_0.pParameters = rs_desc.Desc_1_0.NumParameters > 0 ? root_params : NULL;
  hr = g_serialize_rs(&rs_desc, &rs_blob, &rs_err);
  set_hr(hr);
  if (FAILED(hr)) {
    fprintf(stderr, "[tycho-dx12] SerializeVersionedRootSignature failed: 0x%08lX\n",
            (unsigned long)hr);
    if (rs_err) {
      fprintf(stderr, "[tycho-dx12] %s\n",
              (const char *)rs_err->lpVtbl->GetBufferPointer(rs_err));
      rs_err->lpVtbl->Release(rs_err);
    }
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
    fprintf(stderr, "[tycho-dx12] CreateRootSignature failed: 0x%08lX\n",
            (unsigned long)hr);
    dump_info_queue(dev, "CreateRootSignature");
    free(pipe);
    return 0;
  }

  memset(&pso_desc, 0, sizeof pso_desc);
  if (input_count > 0) {
    // Five int32 per element: location, format, slot, offset, per-instance flag.
    static const DXGI_FORMAT kFormats[3] = {DXGI_FORMAT_R32G32_FLOAT,
                                            DXGI_FORMAT_R32G32B32_FLOAT,
                                            DXGI_FORMAT_R32G32B32A32_FLOAT};
    input_elements = (D3D12_INPUT_ELEMENT_DESC *)calloc((size_t)input_count,
                                                        sizeof(D3D12_INPUT_ELEMENT_DESC));
    if (!input_elements) {
      free(pipe);
      return 0;
    }
    for (input_index = 0; input_index < input_count; input_index++) {
      const int32_t *e = inputs + input_index * 5;
      D3D12_INPUT_ELEMENT_DESC *dst = &input_elements[input_index];
      // Slang's DXIL backend encodes a source `TEXCOORD<n>` as semantic index
      // `n * 10` (verified: TEXCOORD0 -> 0, TEXCOORD1 -> 10, TEXCOORD5 -> 50),
      // so a SPIR-V location n maps to TEXCOORD(n * 10) here.
      dst->SemanticName = "TEXCOORD";
      dst->SemanticIndex = (UINT)(e[0] * 10);
      dst->Format = kFormats[e[1] < 0 || e[1] > 2 ? 0 : e[1]];
      dst->InputSlot = (UINT)e[2];
      dst->AlignedByteOffset = (UINT)e[3];
      dst->InputSlotClass =
          e[4] ? D3D12_INPUT_CLASSIFICATION_PER_INSTANCE_DATA
               : D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA;
      dst->InstanceDataStepRate = e[4] ? 1U : 0U;
    }
    pso_desc.InputLayout.pInputElementDescs = input_elements;
    pso_desc.InputLayout.NumElements = (UINT)input_count;
  }
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
  pso_desc.DepthStencilState.DepthEnable = depth_enable ? TRUE : FALSE;
  pso_desc.DepthStencilState.DepthWriteMask =
      depth_write ? D3D12_DEPTH_WRITE_MASK_ALL : D3D12_DEPTH_WRITE_MASK_ZERO;
  pso_desc.DepthStencilState.DepthFunc = D3D12_COMPARISON_FUNC_LESS_EQUAL;
  pso_desc.DepthStencilState.StencilEnable = FALSE;
  if (depth_enable) {
    pso_desc.DSVFormat = TYCHO_DX12_DEPTH_FORMAT;
  }
  pso_desc.SampleMask = UINT_MAX;
  pso_desc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
  if (color_count <= 0 || color_count > 4) {
    free(pipe);
    return 0;
  }
  pso_desc.NumRenderTargets = (UINT)color_count;
  {
    int target;
    for (target = 0; target < color_count; target++) {
      DXGI_FORMAT format = dx12_format_from_code(color_formats[target]);
      if (format == DXGI_FORMAT_UNKNOWN) {
        free(pipe);
        return 0;
      }
      pso_desc.RTVFormats[target] = format;
      // D3D12 disables a target's writes when its mask is zero.
      pso_desc.BlendState.RenderTarget[target].RenderTargetWriteMask =
          D3D12_COLOR_WRITE_ENABLE_ALL;
    }
  }
  pso_desc.SampleDesc.Count = 1;
  pso_desc.SampleDesc.Quality = 0;
  hr = dev->device->lpVtbl->CreateGraphicsPipelineState(dev->device, &pso_desc,
                                                        &kIID_ID3D12PipelineState,
                                                        (void **)&pipe->pso);
  set_hr(hr);
  free(input_elements);
  if (FAILED(hr)) {
    fprintf(stderr, "[tycho-dx12] CreateGraphicsPipelineState failed: 0x%08lX\n",
            (unsigned long)hr);
    dump_info_queue(dev, "CreateGraphicsPipelineState");
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
                                                      int32_t height, int32_t format_code) {
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
  tex->format = dx12_format_from_code(format_code);
  if (tex->format == DXGI_FORMAT_UNKNOWN) {
    free(tex);
    return 0;
  }
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
  desc.Format = tex->format;
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
  rtv_desc.Format = tex->format;
  rtv_desc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
  dev->device->lpVtbl->CreateRenderTargetView(dev->device, tex->resource, &rtv_desc, tex->rtv);
  return (uint64_t)(uintptr_t)tex;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_depth_create(uint64_t dev_p, int32_t width,
                                                    int32_t height, int32_t format_code) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxTexture *tex;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_DESCRIPTOR_HEAP_DESC heap_desc;
  D3D12_DEPTH_STENCIL_VIEW_DESC dsv_desc;
  D3D12_CLEAR_VALUE clear_value;
  HRESULT hr;
  if (!dev || width <= 0 || height <= 0) return 0;

  tex = (TychoDxTexture *)calloc(1, sizeof(TychoDxTexture));
  if (!tex) return 0;
  tex->width = width;
  tex->height = height;
  tex->is_depth = 1;
  tex->format = dx12_format_from_code(format_code);
  if (!dx12_format_is_depth(tex->format)) {
    free(tex);
    return 0;
  }
  tex->owned = 1;
  tex->state = D3D12_RESOURCE_STATE_DEPTH_WRITE;
  tex->state_tag = TYCHO_DX12_STATE_DEPTH_WRITE;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;

  memset(&clear_value, 0, sizeof clear_value);
  clear_value.Format = TYCHO_DX12_DEPTH_FORMAT;
  clear_value.DepthStencil.Depth = 1.0f;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
  desc.Width = (UINT64)width;
  desc.Height = (UINT)height;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = TYCHO_DX12_DEPTH_FORMAT;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
  desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;

  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc,
      D3D12_RESOURCE_STATE_DEPTH_WRITE, &clear_value, &kIID_ID3D12Resource,
      (void **)&tex->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(tex);
    return 0;
  }

  memset(&heap_desc, 0, sizeof heap_desc);
  heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_DSV;
  heap_desc.NumDescriptors = 1;
  heap_desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_NONE;
  hr = dev->device->lpVtbl->CreateDescriptorHeap(dev->device, &heap_desc,
                                                &kIID_ID3D12DescriptorHeap,
                                                (void **)&tex->dsv_heap);
  set_hr(hr);
  if (FAILED(hr)) {
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    return 0;
  }
  tex->dsv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(tex->dsv_heap, &tex->dsv);
  memset(&dsv_desc, 0, sizeof dsv_desc);
  dsv_desc.Format = TYCHO_DX12_DEPTH_FORMAT;
  dsv_desc.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2D;
  dev->device->lpVtbl->CreateDepthStencilView(dev->device, tex->resource, &dsv_desc, tex->dsv);
  return (uint64_t)(uintptr_t)tex;
}

// Binds the depth attachment that cmd_draw passes to OMSetRenderTargets. Clearing
// and drawing then see the same DSV, so a pass cannot silently render without
// depth by forgetting a second call.
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_depth(uint64_t cmd_p, uint64_t tex_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  if (!cmds) return 0;
  if (tex && !tex->is_depth) return 0;
  cmds->depth = tex;
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_clear_depth(uint64_t cmd_p, uint64_t tex_p, float depth) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  if (!cmds || !tex || !tex->is_depth) return 0;
  if (tex->state != D3D12_RESOURCE_STATE_DEPTH_WRITE) {
    g_last_hr = (HRESULT)0x8000000E;  // E_ILLEGAL_METHOD_CALL: clear before transition
    return 0;
  }
  cmds->list->lpVtbl->ClearDepthStencilView(cmds->list, tex->dsv,
                                            D3D12_CLEAR_FLAG_DEPTH, depth, 0, 0, NULL);
  return 1;
}

// ---------------------------------------------------------------------------
// Shader-visible SRV heap (one slot per texture) + texture upload
// ---------------------------------------------------------------------------


static int ensure_srv_heap(TychoDxDevice *dev) {
  D3D12_DESCRIPTOR_HEAP_DESC desc;
  HRESULT hr;
  if (!dev || !dev->device) return 0;
  if (dev->srv_heap) return 1;
  memset(&desc, 0, sizeof desc);
  desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
  desc.NumDescriptors = TYCHO_DX12_SRV_HEAP_SIZE;
  desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;
  hr = dev->device->lpVtbl->CreateDescriptorHeap(dev->device, &desc,
                                                 &kIID_ID3D12DescriptorHeap,
                                                 (void **)&dev->srv_heap);
  set_hr(hr);
  if (FAILED(hr)) {
    dev->srv_heap = NULL;
    return 0;
  }
  dev->srv_increment = dev->device->lpVtbl->GetDescriptorHandleIncrementSize(
      dev->device, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
  dev->srv_capacity = TYCHO_DX12_SRV_HEAP_SIZE;
  dev->srv_used = 0;

  desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER;
  desc.NumDescriptors = TYCHO_DX12_SAMPLER_HEAP_SIZE;
  desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;
  hr = dev->device->lpVtbl->CreateDescriptorHeap(dev->device, &desc,
                                                 &kIID_ID3D12DescriptorHeap,
                                                 (void **)&dev->sampler_heap);
  set_hr(hr);
  if (FAILED(hr)) {
    dev->sampler_heap = NULL;
    return 0;
  }
  dev->sampler_increment = dev->device->lpVtbl->GetDescriptorHandleIncrementSize(
      dev->device, D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER);
  dev->sampler_capacity = TYCHO_DX12_SAMPLER_HEAP_SIZE;
  dev->sampler_used = 0;
  dev->sampler_free_count = 0;
  {
    D3D12_SAMPLER_DESC sd;
    D3D12_CPU_DESCRIPTOR_HANDLE handle;
    memset(&sd, 0, sizeof sd);
    sd.Filter = D3D12_FILTER_MIN_MAG_MIP_LINEAR;
    sd.AddressU = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    sd.AddressV = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    sd.AddressW = D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
    sd.MipLODBias = 0.0f;
    sd.MaxAnisotropy = 1;
    sd.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
    sd.MinLOD = 0.0f;
    sd.MaxLOD = D3D12_FLOAT32_MAX;
    dev->sampler_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(dev->sampler_heap, &handle);
    dev->device->lpVtbl->CreateSampler(dev->device, &sd, handle);
  }
  return 1;
}

static int texture_make_srv(TychoDxDevice *dev, TychoDxTexture *tex) {
  D3D12_SHADER_RESOURCE_VIEW_DESC desc;
  D3D12_CPU_DESCRIPTOR_HANDLE handle;
  UINT slot;
  if (!dev || !tex || !tex->resource) return 0;
  if (tex->has_srv) return 1;
  if (!ensure_srv_heap(dev)) return 0;
  if (dev->srv_free_count > 0) {
    // Reuse first: descriptors are per-resource and long lived, so a freed
    // slot can be handed out again immediately (a per-frame ring only becomes
    // necessary once transient descriptors appear).
    dev->srv_free_count -= 1;
    slot = dev->srv_free[dev->srv_free_count];
  } else if (dev->srv_used < dev->srv_capacity) {
    slot = dev->srv_used++;
  } else {
    g_last_hr = (HRESULT)0x8007000E;  // E_OUTOFMEMORY: SRV heap exhausted
    return 0;
  }
  dev->srv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(dev->srv_heap, &handle);
  handle.ptr += (SIZE_T)slot * dev->srv_increment;
  memset(&desc, 0, sizeof desc);
  desc.Format = TYCHO_DX12_RT_FORMAT;
  desc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
  desc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
  desc.Texture2D.MipLevels = 1;
  dev->device->lpVtbl->CreateShaderResourceView(dev->device, tex->resource, &desc, handle);
  tex->srv_slot = slot;
  tex->has_srv = 1;
  tex->srv_device = dev;
  return 1;
}

// Copies `pixels` (tightly packed RGBA8) into a DEFAULT-heap texture through a
// throwaway command list, then leaves it in PIXEL_SHADER_RESOURCE with an SRV.
MOONBIT_FFI_EXPORT uint64_t tycho_dx12_texture_create_uploaded(uint64_t dev_p, int32_t width,
                                                               int32_t height,
                                                               const uint8_t *pixels,
                                                               int32_t pixel_bytes,
                                                               int32_t format_code) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxTexture *tex;
  ID3D12Resource *staging = NULL;
  ID3D12CommandAllocator *allocator = NULL;
  ID3D12GraphicsCommandList *list = NULL;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint;
  D3D12_TEXTURE_COPY_LOCATION src;
  D3D12_TEXTURE_COPY_LOCATION dst;
  D3D12_RESOURCE_BARRIER barrier;
  D3D12_RANGE range;
  UINT pitch;
  UINT row;
  uint8_t *mapped = NULL;
  HRESULT hr;
  if (!dev || width <= 0 || height <= 0 || !pixels) return 0;
  if (pixel_bytes != width * height * 4) return 0;

  pitch = (UINT)width * TYCHO_DX12_RT_FORMAT_PIXEL_BYTES;
  pitch = (pitch + (TYCHO_DX12_PITCH_ALIGNMENT - 1)) & ~(TYCHO_DX12_PITCH_ALIGNMENT - 1);

  tex = (TychoDxTexture *)calloc(1, sizeof(TychoDxTexture));
  if (!tex) return 0;
  tex->width = width;
  tex->height = height;
  tex->owned = 1;
  tex->format = dx12_format_from_code(format_code);
  if (tex->format == DXGI_FORMAT_UNKNOWN) {
    free(tex);
    return 0;
  }
  tex->state = D3D12_RESOURCE_STATE_COPY_DEST;
  tex->state_tag = TYCHO_DX12_STATE_COPY_DEST;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;
  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
  desc.Width = (UINT64)width;
  desc.Height = (UINT)height;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = tex->format;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
  desc.Flags = D3D12_RESOURCE_FLAG_NONE;
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_COPY_DEST,
      NULL, &kIID_ID3D12Resource, (void **)&tex->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(tex);
    return 0;
  }

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_UPLOAD;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;
  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
  desc.Width = (UINT64)pitch * (UINT64)height;
  desc.Height = 1;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = DXGI_FORMAT_UNKNOWN;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_GENERIC_READ,
      NULL, &kIID_ID3D12Resource, (void **)&staging);
  set_hr(hr);
  if (FAILED(hr)) {
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    return 0;
  }
  memset(&range, 0, sizeof range);
  hr = staging->lpVtbl->Map(staging, 0, &range, (void **)&mapped);
  set_hr(hr);
  if (FAILED(hr) || !mapped) {
    staging->lpVtbl->Release(staging);
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    return 0;
  }
  for (row = 0; row < (UINT)height; row++) {
    memcpy(mapped + (size_t)row * pitch, pixels + (size_t)row * (size_t)width * 4,
           (size_t)width * 4);
  }
  staging->lpVtbl->Unmap(staging, 0, NULL);

  hr = dev->device->lpVtbl->CreateCommandAllocator(dev->device,
                                                   D3D12_COMMAND_LIST_TYPE_DIRECT,
                                                   &kIID_ID3D12CommandAllocator,
                                                   (void **)&allocator);
  set_hr(hr);
  if (SUCCEEDED(hr)) {
    hr = dev->device->lpVtbl->CreateCommandList(dev->device, 0,
                                                D3D12_COMMAND_LIST_TYPE_DIRECT, allocator,
                                                NULL, &kIID_ID3D12GraphicsCommandList,
                                                (void **)&list);
    set_hr(hr);
  }
  if (SUCCEEDED(hr)) {
    memset(&footprint, 0, sizeof footprint);
    footprint.Footprint.Format = tex->format;
    footprint.Footprint.Width = (UINT)width;
    footprint.Footprint.Height = (UINT)height;
    footprint.Footprint.Depth = 1;
    footprint.Footprint.RowPitch = pitch;
    memset(&src, 0, sizeof src);
    src.pResource = staging;
    src.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
    src.PlacedFootprint = footprint;
    memset(&dst, 0, sizeof dst);
    dst.pResource = tex->resource;
    dst.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
    dst.SubresourceIndex = 0;
    list->lpVtbl->CopyTextureRegion(list, &dst, 0, 0, 0, &src, NULL);
    memset(&barrier, 0, sizeof barrier);
    barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
    barrier.Transition.pResource = tex->resource;
    barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
    barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_COPY_DEST;
    barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
    list->lpVtbl->ResourceBarrier(list, 1, &barrier);
    hr = list->lpVtbl->Close(list);
    set_hr(hr);
    if (SUCCEEDED(hr)) {
      ID3D12CommandList *lists[1] = {(ID3D12CommandList *)list};
      dev->queue->lpVtbl->ExecuteCommandLists(dev->queue, 1, lists);
      dev->fence_value += 1;
      hr = dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value);
      set_hr(hr);
      if (SUCCEEDED(hr)) {
        if (dev->fence->lpVtbl->GetCompletedValue(dev->fence) < dev->fence_value) {
          hr = dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value,
                                                       dev->fence_event);
          if (FAILED(hr) || WaitForSingleObject(dev->fence_event, 30000) != WAIT_OBJECT_0) {
            hr = E_FAIL;
          }
        }
      }
      tex->state = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE;
      tex->state_tag = TYCHO_DX12_STATE_SHADER_RESOURCE;
    }
  }
  if (list) list->lpVtbl->Release(list);
  if (allocator) allocator->lpVtbl->Release(allocator);
  staging->lpVtbl->Release(staging);
  if (FAILED(hr) || !texture_make_srv(dev, tex)) {
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    return 0;
  }
  return (uint64_t)(uintptr_t)tex;
}

// Binds a texture's SRV through the descriptor table at `root_index` (the table
// follows the root CBVs in the signature the pipelines build).
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_texture(uint64_t cmd_p, int32_t root_index,
                                                      int32_t sampler_root, uint64_t tex_p,
                                                      uint64_t sampler_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  TychoDxSampler *sampler = as_sampler(sampler_p);
  UINT sampler_slot = sampler ? sampler->slot : 0;
  ID3D12DescriptorHeap *heaps[2];
  D3D12_GPU_DESCRIPTOR_HANDLE gpu;
  D3D12_GPU_DESCRIPTOR_HANDLE sampler_gpu;
  if (!cmds || !cmds->dev || !tex || !tex->has_srv || root_index < 0) return 0;
  if (!cmds->dev->sampler_heap) return 0;
  heaps[0] = cmds->dev->srv_heap;
  heaps[1] = cmds->dev->sampler_heap;
  cmds->list->lpVtbl->SetDescriptorHeaps(cmds->list, 2, heaps);
  cmds->dev->srv_heap->lpVtbl->GetGPUDescriptorHandleForHeapStart(cmds->dev->srv_heap, &gpu);
  gpu.ptr += (SIZE_T)tex->srv_slot * cmds->dev->srv_increment;
  cmds->list->lpVtbl->SetGraphicsRootDescriptorTable(cmds->list, (UINT)root_index, gpu);
  cmds->dev->sampler_heap->lpVtbl->GetGPUDescriptorHandleForHeapStart(cmds->dev->sampler_heap,
                                                                     &sampler_gpu);
  sampler_gpu.ptr += (SIZE_T)sampler_slot * cmds->dev->sampler_increment;
  cmds->list->lpVtbl->SetGraphicsRootDescriptorTable(cmds->list, (UINT)sampler_root,
                                                    sampler_gpu);
  return 1;
}

MOONBIT_FFI_EXPORT void tycho_dx12_texture_destroy(uint64_t p) {
  TychoDxTexture *tex = as_texture(p);
  if (!tex) return;
  if (tex->has_srv && tex->srv_device && tex->srv_device->srv_free_count < TYCHO_DX12_SRV_HEAP_SIZE) {
    // The descriptor itself is left stale; the slot is only reused after a new
    // CreateShaderResourceView overwrites it, and no command list can reference
    // it once the texture is gone.
    tex->srv_device->srv_free[tex->srv_device->srv_free_count] = tex->srv_slot;
    tex->srv_device->srv_free_count += 1;
  }
  if (tex->owned) {
    if (tex->rtv_heap) tex->rtv_heap->lpVtbl->Release(tex->rtv_heap);
    if (tex->dsv_heap) tex->dsv_heap->lpVtbl->Release(tex->dsv_heap);
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
// Samplers (slots in the device sampler heap)
// ---------------------------------------------------------------------------

// `filter`: 0 = point, 1 = linear, 2 = anisotropic.
// `address`: 0 = wrap, 1 = mirror, 2 = clamp, 3 = border, 4 = mirror-once.
static D3D12_FILTER dx12_filter(int32_t filter) {
  switch (filter) {
    case 0:
      return D3D12_FILTER_MIN_MAG_MIP_POINT;
    case 2:
      return D3D12_FILTER_ANISOTROPIC;
    default:
      return D3D12_FILTER_MIN_MAG_MIP_LINEAR;
  }
}

static D3D12_TEXTURE_ADDRESS_MODE dx12_address(int32_t address) {
  switch (address) {
    case 0:
      return D3D12_TEXTURE_ADDRESS_MODE_WRAP;
    case 1:
      return D3D12_TEXTURE_ADDRESS_MODE_MIRROR;
    case 3:
      return D3D12_TEXTURE_ADDRESS_MODE_BORDER;
    case 4:
      return D3D12_TEXTURE_ADDRESS_MODE_MIRROR_ONCE;
    default:
      return D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
  }
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_sampler_create(uint64_t dev_p, int32_t filter,
                                                      int32_t address, float anisotropy,
                                                      float min_lod, float max_lod,
                                                      float mip_lod_bias) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxSampler *sampler;
  D3D12_SAMPLER_DESC desc;
  D3D12_CPU_DESCRIPTOR_HANDLE handle;
  UINT slot;
  if (!dev) return 0;
  if (!ensure_srv_heap(dev)) return 0;
  if (dev->sampler_free_count > 0) {
    dev->sampler_free_count -= 1;
    slot = dev->sampler_free[dev->sampler_free_count];
  } else if (dev->sampler_used < dev->sampler_capacity) {
    slot = dev->sampler_used++;
  } else {
    g_last_hr = (HRESULT)0x8007000E;  // E_OUTOFMEMORY: sampler heap exhausted
    return 0;
  }

  sampler = (TychoDxSampler *)calloc(1, sizeof(TychoDxSampler));
  if (!sampler) {
    dev->sampler_free[dev->sampler_free_count] = slot;
    dev->sampler_free_count += 1;
    return 0;
  }
  sampler->slot = slot;
  sampler->dev = dev;

  memset(&desc, 0, sizeof desc);
  desc.Filter = dx12_filter(filter);
  desc.AddressU = dx12_address(address);
  desc.AddressV = dx12_address(address);
  desc.AddressW = dx12_address(address);
  desc.MipLODBias = mip_lod_bias;
  desc.MaxAnisotropy = anisotropy < 1.0f ? 1U : (UINT)anisotropy;
  // A non-comparison filter ignores this, but the debug layer warns about
  // ALWAYS, so use the documented "cannot be mistaken for intent" value.
  desc.ComparisonFunc = D3D12_COMPARISON_FUNC_NEVER;
  desc.MinLOD = min_lod;
  desc.MaxLOD = max_lod;
  dev->sampler_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(dev->sampler_heap, &handle);
  handle.ptr += (SIZE_T)slot * dev->sampler_increment;
  dev->device->lpVtbl->CreateSampler(dev->device, &desc, handle);
  return (uint64_t)(uintptr_t)sampler;
}

MOONBIT_FFI_EXPORT void tycho_dx12_sampler_destroy(uint64_t p) {
  TychoDxSampler *sampler = as_sampler(p);
  if (!sampler) return;
  // The descriptor stays stale in the heap; the slot is only reused after the
  // next CreateSampler overwrites it.
  if (sampler->dev && sampler->dev->sampler_free_count < TYCHO_DX12_SAMPLER_HEAP_SIZE) {
    sampler->dev->sampler_free[sampler->dev->sampler_free_count] = sampler->slot;
    sampler->dev->sampler_free_count += 1;
  }
  free(sampler);
}

static ID3D12CommandSignature *ensure_indirect_signature(TychoDxDevice *dev, int32_t kind);

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_root_constants_bytes(uint64_t cmd_p, int32_t index,
                                                                   const void *data,
                                                                   int32_t words) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || index < 0 || !data || words <= 0) return 0;
  cmds->list->lpVtbl->SetGraphicsRoot32BitConstants(cmds->list, (UINT)index, (UINT)words, data, 0);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_root_constants_bytes(
    uint64_t cmd_p, int32_t index, const void *data, int32_t words) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || index < 0 || !data || words <= 0) return 0;
  cmds->list->lpVtbl->SetComputeRoot32BitConstants(cmds->list, (UINT)index, (UINT)words, data, 0);
  return 1;
}

// Storage buffers live in the DEFAULT heap, so reading one needs a GPU copy into
// a READBACK staging buffer through a one-shot list (same shape as the texture
// upload path).
MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_download(uint64_t dev_p, uint64_t buf_p,
                                                      uint8_t *dst, int32_t size) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxBuffer *buf = as_buffer(buf_p);
  ID3D12Resource *staging = NULL;
  ID3D12CommandAllocator *allocator = NULL;
  ID3D12GraphicsCommandList *list = NULL;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_RESOURCE_BARRIER barrier;
  D3D12_RANGE range;
  void *mapped = NULL;
  HRESULT hr;
  if (!dev || !buf || !buf->resource || !dst || size <= 0 || size > buf->size) return 0;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_READBACK;
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
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_COPY_DEST, NULL,
      &kIID_ID3D12Resource, (void **)&staging);
  set_hr(hr);
  if (FAILED(hr)) return 0;

  hr = dev->device->lpVtbl->CreateCommandAllocator(dev->device, D3D12_COMMAND_LIST_TYPE_DIRECT,
                                                   &kIID_ID3D12CommandAllocator,
                                                   (void **)&allocator);
  set_hr(hr);
  if (SUCCEEDED(hr)) {
    hr = dev->device->lpVtbl->CreateCommandList(dev->device, 0, D3D12_COMMAND_LIST_TYPE_DIRECT,
                                                allocator, NULL,
                                                &kIID_ID3D12GraphicsCommandList, (void **)&list);
    set_hr(hr);
  }
  if (SUCCEEDED(hr)) {
    // Buffers live in one implicit state for UAV access, so the copy needs no
    // barrier (the staging resource stays COPY_DEST for its lifetime).
    list->lpVtbl->CopyBufferRegion(list, staging, 0, buf->resource, 0, (UINT64)size);
    hr = list->lpVtbl->Close(list);
    set_hr(hr);
  }
  if (SUCCEEDED(hr)) {
    ID3D12CommandList *lists[1] = {(ID3D12CommandList *)list};
    dev->queue->lpVtbl->ExecuteCommandLists(dev->queue, 1, lists);
    dev->fence_value += 1;
    hr = dev->queue->lpVtbl->Signal(dev->queue, dev->fence, dev->fence_value);
    set_hr(hr);
    if (SUCCEEDED(hr) && dev->fence->lpVtbl->GetCompletedValue(dev->fence) < dev->fence_value) {
      hr = dev->fence->lpVtbl->SetEventOnCompletion(dev->fence, dev->fence_value,
                                                   dev->fence_event);
      if (FAILED(hr) || WaitForSingleObject(dev->fence_event, 30000) != WAIT_OBJECT_0) {
        hr = E_FAIL;
      }
    }
  }
  if (SUCCEEDED(hr)) {
    hr = staging->lpVtbl->Map(staging, 0, NULL, &mapped);
    set_hr(hr);
    if (SUCCEEDED(hr) && mapped) {
      memcpy(dst, mapped, (size_t)size);
      memset(&range, 0, sizeof range);
      staging->lpVtbl->Unmap(staging, 0, &range);
    }
  }
  if (list) list->lpVtbl->Release(list);
  if (allocator) allocator->lpVtbl->Release(allocator);
  staging->lpVtbl->Release(staging);
  return SUCCEEDED(hr) ? 1 : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_root_constants(uint64_t cmd_p, int32_t index,
                                                             const uint32_t *data, int32_t count) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || index < 0 || !data || count <= 0) return 0;
  cmds->list->lpVtbl->SetGraphicsRoot32BitConstants(cmds->list, (UINT)index, (UINT)count, data, 0);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_root_constants(uint64_t cmd_p,
                                                                     int32_t index,
                                                                     const uint32_t *data,
                                                                     int32_t count) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || index < 0 || !data || count <= 0) return 0;
  cmds->list->lpVtbl->SetComputeRoot32BitConstants(cmds->list, (UINT)index, (UINT)count, data, 0);
  return 1;
}

// ---------------------------------------------------------------------------
// Storage (UAV) buffers and plain copies
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_storage_buffer_create(uint64_t dev_p, int32_t size) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxBuffer *buf;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_UNORDERED_ACCESS_VIEW_DESC uav;
  D3D12_CPU_DESCRIPTOR_HANDLE handle;
  UINT slot;
  HRESULT hr;
  if (!dev || size <= 0) return 0;
  if (!ensure_srv_heap(dev)) return 0;

  buf = (TychoDxBuffer *)calloc(1, sizeof(TychoDxBuffer));
  if (!buf) return 0;
  buf->size = size;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
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
  desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_COMMON,
      NULL, &kIID_ID3D12Resource, (void **)&buf->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(buf);
    return 0;
  }

  if (dev->srv_free_count > 0) {
    dev->srv_free_count -= 1;
    slot = dev->srv_free[dev->srv_free_count];
  } else if (dev->srv_used < dev->srv_capacity) {
    slot = dev->srv_used++;
  } else {
    buf->resource->lpVtbl->Release(buf->resource);
    free(buf);
    g_last_hr = (HRESULT)0x8007000E;
    return 0;
  }
  dev->srv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(dev->srv_heap, &handle);
  handle.ptr += (SIZE_T)slot * dev->srv_increment;
  memset(&uav, 0, sizeof uav);
  // Raw buffer view (`RWByteAddressBuffer`): R32_TYPELESS plus the RAW flag.
  // UNKNOWN format with a zero stride is rejected by the debug layer.
  uav.Format = DXGI_FORMAT_R32_TYPELESS;
  uav.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
  uav.Buffer.NumElements = (UINT)(size / 4);
  uav.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_RAW;
  dev->device->lpVtbl->CreateUnorderedAccessView(dev->device, buf->resource, NULL, &uav, handle);
  buf->uav_slot = slot;
  buf->has_uav = 1;
  buf->uav_device = dev;
  return (uint64_t)(uintptr_t)buf;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_buffer_uav(uint64_t cmd_p, int32_t root_index,
                                                         uint64_t buf_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxBuffer *buf = as_buffer(buf_p);
  ID3D12DescriptorHeap *heaps[1];
  D3D12_GPU_DESCRIPTOR_HANDLE gpu;
  if (!cmds || !cmds->dev || !buf || !buf->has_uav || root_index < 0) return 0;
  heaps[0] = cmds->dev->srv_heap;
  cmds->list->lpVtbl->SetDescriptorHeaps(cmds->list, 1, heaps);
  cmds->dev->srv_heap->lpVtbl->GetGPUDescriptorHandleForHeapStart(cmds->dev->srv_heap, &gpu);
  gpu.ptr += (SIZE_T)buf->uav_slot * cmds->dev->srv_increment;
  cmds->list->lpVtbl->SetComputeRootDescriptorTable(cmds->list, (UINT)root_index, gpu);
  return 1;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_readback_buffer_create(uint64_t dev_p, int32_t size) {
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
  heap.Type = D3D12_HEAP_TYPE_READBACK;
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
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_COPY_DEST, NULL,
      &kIID_ID3D12Resource, (void **)&buf->resource);
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

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_copy_buffer(uint64_t cmd_p, uint64_t src_p,
                                                      uint64_t dst_p, int32_t size) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxBuffer *src = as_buffer(src_p);
  TychoDxBuffer *dst = as_buffer(dst_p);
  if (!cmds || !src || !dst || size <= 0) return 0;
  if (size > src->size || size > dst->size) return 0;
  cmds->list->lpVtbl->CopyBufferRegion(cmds->list, dst->resource, 0, src->resource, 0,
                                       (UINT64)size);
  return 1;
}

// `count_buffer` holds a single UINT32 that bounds how many arguments run.
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_execute_indirect_counted(
    uint64_t cmd_p, uint64_t tex_p, int32_t kind, uint64_t arg_buffer_p, int32_t arg_offset,
    int32_t max_count, uint64_t count_buffer_p, int32_t count_offset, int32_t flip_y) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxBuffer *args = as_buffer(arg_buffer_p);
  TychoDxBuffer *counts = as_buffer(count_buffer_p);
  ID3D12CommandSignature *sig;
  if (!cmds || !cmds->dev || !args || !args->resource || !counts || !counts->resource) return 0;
  if (max_count <= 0) return 0;
  sig = ensure_indirect_signature(cmds->dev, kind);
  if (!sig) return 0;
  if (kind != 2 && !dx12_prepare_draw(cmds, as_texture(tex_p), flip_y)) return 0;
  cmds->list->lpVtbl->ExecuteIndirect(cmds->list, sig, (UINT)max_count, args->resource,
                                      (UINT64)arg_offset, counts->resource, (UINT64)count_offset);
  return 1;
}

// ---------------------------------------------------------------------------
// Indirect draws / dispatches and timestamp queries
// ---------------------------------------------------------------------------

// Argument layouts match Vulkan's byte-for-byte (the RHI buffers are shared):
// draw = 16 B, draw-indexed = 20 B, dispatch = 12 B.
static const UINT kIndirectStrides[3] = {16, 20, 12};

static ID3D12CommandSignature *ensure_indirect_signature(TychoDxDevice *dev, int32_t kind) {
  D3D12_INDIRECT_ARGUMENT_DESC arg;
  D3D12_COMMAND_SIGNATURE_DESC desc;
  HRESULT hr;
  if (!dev || kind < 0 || kind > 2) return NULL;
  if (dev->indirect_sig[kind]) return dev->indirect_sig[kind];
  memset(&arg, 0, sizeof arg);
  arg.Type = kind == 0   ? D3D12_INDIRECT_ARGUMENT_TYPE_DRAW
             : kind == 1 ? D3D12_INDIRECT_ARGUMENT_TYPE_DRAW_INDEXED
                         : D3D12_INDIRECT_ARGUMENT_TYPE_DISPATCH;
  memset(&desc, 0, sizeof desc);
  desc.ByteStride = kIndirectStrides[kind];
  desc.NumArgumentDescs = 1;
  desc.pArgumentDescs = &arg;
  hr = dev->device->lpVtbl->CreateCommandSignature(dev->device, &desc, NULL,
                                                   &kIID_ID3D12CommandSignature,
                                                   (void **)&dev->indirect_sig[kind]);
  set_hr(hr);
  if (FAILED(hr)) {
    dev->indirect_sig[kind] = NULL;
    return NULL;
  }
  return dev->indirect_sig[kind];
}

// `tex` is ignored for dispatch (kind 2); graphics kinds need the render target.
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_execute_indirect(uint64_t cmd_p, uint64_t tex_p,
                                                           int32_t kind, uint64_t arg_buffer_p,
                                                           int32_t arg_offset, int32_t max_count,
                                                           int32_t flip_y) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxBuffer *args = as_buffer(arg_buffer_p);
  ID3D12CommandSignature *sig;
  if (!cmds || !cmds->dev || !args || !args->resource || max_count <= 0) return 0;
  sig = ensure_indirect_signature(cmds->dev, kind);
  if (!sig) return 0;
  if (kind != 2 && !dx12_prepare_draw(cmds, as_texture(tex_p), flip_y)) return 0;
  cmds->list->lpVtbl->ExecuteIndirect(cmds->list, sig, (UINT)max_count, args->resource,
                                      (UINT64)arg_offset, NULL, 0);
  return 1;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_timestamp_pool_create(uint64_t dev_p, int32_t count) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxTimestampPool *pool;
  D3D12_QUERY_HEAP_DESC heap_desc;
  D3D12_HEAP_PROPERTIES heap_props;
  D3D12_RESOURCE_DESC res_desc;
  void *mapped = NULL;
  HRESULT hr;
  if (!dev || count <= 0) return 0;
  pool = (TychoDxTimestampPool *)calloc(1, sizeof(TychoDxTimestampPool));
  if (!pool) return 0;
  pool->count = (UINT)count;

  memset(&heap_desc, 0, sizeof heap_desc);
  heap_desc.Type = D3D12_QUERY_HEAP_TYPE_TIMESTAMP;
  heap_desc.Count = (UINT)count;
  hr = dev->device->lpVtbl->CreateQueryHeap(dev->device, &heap_desc, &kIID_ID3D12QueryHeap,
                                            (void **)&pool->heap);
  set_hr(hr);
  if (FAILED(hr)) {
    free(pool);
    return 0;
  }

  memset(&heap_props, 0, sizeof heap_props);
  heap_props.Type = D3D12_HEAP_TYPE_READBACK;
  heap_props.CreationNodeMask = 1;
  heap_props.VisibleNodeMask = 1;
  memset(&res_desc, 0, sizeof res_desc);
  res_desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
  res_desc.Width = (UINT64)count * sizeof(UINT64);
  res_desc.Height = 1;
  res_desc.DepthOrArraySize = 1;
  res_desc.MipLevels = 1;
  res_desc.Format = DXGI_FORMAT_UNKNOWN;
  res_desc.SampleDesc.Count = 1;
  res_desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap_props, D3D12_HEAP_FLAG_NONE, &res_desc, D3D12_RESOURCE_STATE_COPY_DEST,
      NULL, &kIID_ID3D12Resource, (void **)&pool->readback);
  set_hr(hr);
  if (FAILED(hr)) {
    pool->heap->lpVtbl->Release(pool->heap);
    free(pool);
    return 0;
  }
  if (FAILED(pool->readback->lpVtbl->Map(pool->readback, 0, NULL, &mapped)) || !mapped) {
    pool->readback->lpVtbl->Release(pool->readback);
    pool->heap->lpVtbl->Release(pool->heap);
    free(pool);
    return 0;
  }
  pool->mapped = (UINT64 *)mapped;
  if (!dev->timestamp_freq) {
    UINT64 freq = 0;
    if (SUCCEEDED(dev->queue->lpVtbl->GetTimestampFrequency(dev->queue, &freq))) {
      dev->timestamp_freq = freq;
    }
  }
  pool->frequency = dev->timestamp_freq;
  return (uint64_t)(uintptr_t)pool;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_write_timestamp(uint64_t cmd_p, uint64_t pool_p,
                                                          int32_t index) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  if (!cmds || !pool || index < 0 || (UINT)index >= pool->count) return 0;
  cmds->list->lpVtbl->EndQuery(cmds->list, pool->heap, D3D12_QUERY_TYPE_TIMESTAMP, (UINT)index);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_resolve_timestamps(uint64_t cmd_p, uint64_t pool_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  if (!cmds || !pool) return 0;
  cmds->list->lpVtbl->ResolveQueryData(cmds->list, pool->heap, D3D12_QUERY_TYPE_TIMESTAMP, 0,
                                       pool->count, pool->readback, 0);
  return 1;
}

MOONBIT_FFI_EXPORT int64_t tycho_dx12_timestamp_read(uint64_t pool_p, int32_t index) {
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  if (!pool || !pool->mapped || index < 0 || (UINT)index >= pool->count) return -1;
  return (int64_t)pool->mapped[index];
}

MOONBIT_FFI_EXPORT int64_t tycho_dx12_timestamp_frequency(uint64_t pool_p) {
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  return pool ? (int64_t)pool->frequency : 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_timestamp_pool_count(uint64_t pool_p) {
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  return pool ? (int32_t)pool->count : 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_timestamp_pool_destroy(uint64_t pool_p) {
  TychoDxTimestampPool *pool = as_timestamp_pool(pool_p);
  if (!pool) return;
  if (pool->readback) {
    pool->readback->lpVtbl->Unmap(pool->readback, 0, NULL);
    pool->readback->lpVtbl->Release(pool->readback);
  }
  if (pool->heap) pool->heap->lpVtbl->Release(pool->heap);
  free(pool);
}

// ---------------------------------------------------------------------------
// Placed buffers (offsets come from the shared RegionPool on the MoonBit side)
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_heap_create(uint64_t dev_p, int32_t size) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxBufferHeap *out;
  D3D12_HEAP_DESC desc;
  HRESULT hr;
  if (!dev || size <= 0) return 0;
  out = (TychoDxBufferHeap *)calloc(1, sizeof(TychoDxBufferHeap));
  if (!out) return 0;
  out->size = size;
  out->device = dev->device;
  out->device->lpVtbl->AddRef(out->device);
  memset(&desc, 0, sizeof desc);
  desc.SizeInBytes = (UINT64)size;
  desc.Properties.Type = D3D12_HEAP_TYPE_UPLOAD;
  desc.Properties.CreationNodeMask = 1;
  desc.Properties.VisibleNodeMask = 1;
  desc.Alignment = 0;
  desc.Flags = D3D12_HEAP_FLAG_ALLOW_ONLY_BUFFERS;
  hr = dev->device->lpVtbl->CreateHeap(dev->device, &desc, &kIID_ID3D12Heap,
                                       (void **)&out->heap);
  set_hr(hr);
  if (FAILED(hr)) {
    out->device->lpVtbl->Release(out->device);
    free(out);
    return 0;
  }
  return (uint64_t)(uintptr_t)out;
}

MOONBIT_FFI_EXPORT void tycho_dx12_buffer_heap_destroy(uint64_t p) {
  TychoDxBufferHeap *heap = as_buffer_heap(p);
  if (!heap) return;
  if (heap->heap) heap->heap->lpVtbl->Release(heap->heap);
  if (heap->device) heap->device->lpVtbl->Release(heap->device);
  free(heap);
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_place(uint64_t heap_p, int32_t offset,
                                                    int32_t size) {
  TychoDxBufferHeap *heap = as_buffer_heap(heap_p);
  TychoDxBuffer *buf;
  D3D12_RESOURCE_DESC desc;
  void *mapped = NULL;
  HRESULT hr;
  if (!heap || !heap->heap || !heap->device) return 0;
  if (offset < 0 || size <= 0) return 0;
  if ((int64_t)offset + (int64_t)size > (int64_t)heap->size) return 0;

  buf = (TychoDxBuffer *)calloc(1, sizeof(TychoDxBuffer));
  if (!buf) return 0;
  buf->size = size;
  buf->placed = 1;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
  desc.Width = (UINT64)size;
  desc.Height = 1;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = DXGI_FORMAT_UNKNOWN;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
  hr = heap->device->lpVtbl->CreatePlacedResource(
      heap->device, heap->heap, (UINT64)offset, &desc, D3D12_RESOURCE_STATE_GENERIC_READ,
      NULL, &kIID_ID3D12Resource, (void **)&buf->resource);
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

// ---------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------

// `TextureFormat` ordinals from tycho/types.mbt. The mapping lives here so the
// MoonBit side never has to know a numeric DXGI value.
static DXGI_FORMAT dx12_format_from_code(int32_t code) {
  switch (code) {
    case 0:
      return DXGI_FORMAT_R8G8B8A8_UNORM;
    case 1:
      return DXGI_FORMAT_B8G8R8A8_UNORM;
    case 2:
      return DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
    case 3:
      return DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
    case 4:
      return DXGI_FORMAT_R16G16B16A16_FLOAT;
    case 5:
      return DXGI_FORMAT_R16G16_FLOAT;
    case 6:
      return DXGI_FORMAT_R8_UNORM;
    case 7:
      return DXGI_FORMAT_R32G32B32A32_FLOAT;
    case 8:
      return DXGI_FORMAT_D32_FLOAT;
    case 9:
      return DXGI_FORMAT_D24_UNORM_S8_UINT;
    default:
      return DXGI_FORMAT_UNKNOWN;
  }
}

static int dx12_format_is_depth(DXGI_FORMAT format) {
  return format == DXGI_FORMAT_D32_FLOAT || format == DXGI_FORMAT_D24_UNORM_S8_UINT;
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
  if (buf->has_uav && buf->uav_device &&
      buf->uav_device->srv_free_count < TYCHO_DX12_SRV_HEAP_SIZE) {
    buf->uav_device->srv_free[buf->uav_device->srv_free_count] = buf->uav_slot;
    buf->uav_device->srv_free_count += 1;
  }
  if (buf->resource) {
    if (buf->mapped) {
      buf->resource->lpVtbl->Unmap(buf->resource, 0, NULL);
    }
    // A placed resource owns no heap of its own; releasing it is enough.
    buf->resource->lpVtbl->Release(buf->resource);
  }
  free(buf);
}

// ---------------------------------------------------------------------------
// Storage textures (UAV), compute pipelines and dispatch
// ---------------------------------------------------------------------------

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_storage_texture_create(uint64_t dev_p, int32_t width,
                                                              int32_t height) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxTexture *tex;
  D3D12_HEAP_PROPERTIES heap;
  D3D12_RESOURCE_DESC desc;
  D3D12_UNORDERED_ACCESS_VIEW_DESC uav_desc;
  D3D12_CPU_DESCRIPTOR_HANDLE handle;
  UINT slot;
  HRESULT hr;
  if (!dev || width <= 0 || height <= 0) return 0;
  if (!ensure_srv_heap(dev)) return 0;

  tex = (TychoDxTexture *)calloc(1, sizeof(TychoDxTexture));
  if (!tex) return 0;
  tex->width = width;
  tex->height = height;
  tex->format = TYCHO_DX12_RT_FORMAT;
  tex->owned = 1;
  tex->state = D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
  tex->state_tag = TYCHO_DX12_STATE_UNORDERED_ACCESS;

  memset(&heap, 0, sizeof heap);
  heap.Type = D3D12_HEAP_TYPE_DEFAULT;
  heap.CreationNodeMask = 1;
  heap.VisibleNodeMask = 1;

  memset(&desc, 0, sizeof desc);
  desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
  desc.Width = (UINT64)width;
  desc.Height = (UINT)height;
  desc.DepthOrArraySize = 1;
  desc.MipLevels = 1;
  desc.Format = TYCHO_DX12_RT_FORMAT;
  desc.SampleDesc.Count = 1;
  desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
  desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;

  hr = dev->device->lpVtbl->CreateCommittedResource(
      dev->device, &heap, D3D12_HEAP_FLAG_NONE, &desc,
      D3D12_RESOURCE_STATE_UNORDERED_ACCESS, NULL, &kIID_ID3D12Resource,
      (void **)&tex->resource);
  set_hr(hr);
  if (FAILED(hr)) {
    free(tex);
    return 0;
  }

  if (dev->srv_free_count > 0) {
    dev->srv_free_count -= 1;
    slot = dev->srv_free[dev->srv_free_count];
  } else if (dev->srv_used < dev->srv_capacity) {
    slot = dev->srv_used++;
  } else {
    tex->resource->lpVtbl->Release(tex->resource);
    free(tex);
    g_last_hr = (HRESULT)0x8007000E;  // E_OUTOFMEMORY: descriptor heap exhausted
    return 0;
  }
  dev->srv_heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(dev->srv_heap, &handle);
  handle.ptr += (SIZE_T)slot * dev->srv_increment;
  memset(&uav_desc, 0, sizeof uav_desc);
  uav_desc.Format = TYCHO_DX12_RT_FORMAT;
  uav_desc.ViewDimension = D3D12_UAV_DIMENSION_TEXTURE2D;
  dev->device->lpVtbl->CreateUnorderedAccessView(dev->device, tex->resource, NULL, &uav_desc,
                                                     handle);
  tex->srv_slot = slot;
  tex->has_srv = 1;
  tex->srv_is_uav = 1;
  tex->srv_device = dev;
  return (uint64_t)(uintptr_t)tex;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_compute_pipeline_create(uint64_t dev_p,
                                                               const uint8_t *cs, int32_t cs_len,
                                                               int32_t cbv_count,
                                                               int32_t uav_tables,
                                                               int32_t push_bytes) {
  TychoDxDevice *dev = as_device(dev_p);
  TychoDxPipeline *pipe;
  ID3DBlob *rs_blob = NULL;
  ID3DBlob *rs_err = NULL;
  D3D12_VERSIONED_ROOT_SIGNATURE_DESC rs_desc;
  D3D12_ROOT_PARAMETER root_params[TYCHO_DX12_MAX_ROOT_CBVS + 2];
  D3D12_DESCRIPTOR_RANGE uav_range;
  D3D12_COMPUTE_PIPELINE_STATE_DESC pso_desc;
  HRESULT hr;
  int i;
  if (!dev || !cs || cs_len <= 0) return 0;
  if (cbv_count < 0 || cbv_count > TYCHO_DX12_MAX_ROOT_CBVS) return 0;
  if (uav_tables < 0 || uav_tables > 8) return 0;
  if (push_bytes < 0 || push_bytes > 256 || (push_bytes % 4) != 0) return 0;

  pipe = (TychoDxPipeline *)calloc(1, sizeof(TychoDxPipeline));
  if (!pipe) return 0;

  memset(root_params, 0, sizeof root_params);
  for (i = 0; i < cbv_count; i++) {
    root_params[i].ParameterType = D3D12_ROOT_PARAMETER_TYPE_CBV;
    root_params[i].Descriptor.ShaderRegister = (UINT)i;
    root_params[i].Descriptor.RegisterSpace = 0;
    root_params[i].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
  }
  memset(&rs_desc, 0, sizeof rs_desc);
  rs_desc.Version = D3D_ROOT_SIGNATURE_VERSION_1_0;
  if (uav_tables > 0) {
    // RUAVs u0..u(n-1) in space 0, one table at index cbv_count.
    memset(&uav_range, 0, sizeof uav_range);
    uav_range.RangeType = D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
    uav_range.NumDescriptors = (UINT)uav_tables;
    uav_range.BaseShaderRegister = 0;
    uav_range.RegisterSpace = 0;
    root_params[cbv_count].ParameterType = D3D12_ROOT_PARAMETER_TYPE_DESCRIPTOR_TABLE;
    root_params[cbv_count].DescriptorTable.NumDescriptorRanges = 1;
    root_params[cbv_count].DescriptorTable.pDescriptorRanges = &uav_range;
    root_params[cbv_count].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
  }
  {
    // Same convention as the graphics path: push constants live at `b15, space0`.
    int push_index = cbv_count + (uav_tables > 0 ? 1 : 0);
    if (push_bytes > 0) {
      root_params[push_index].ParameterType = D3D12_ROOT_PARAMETER_TYPE_32BIT_CONSTANTS;
      root_params[push_index].Constants.ShaderRegister = 15;
      root_params[push_index].Constants.RegisterSpace = 0;
      root_params[push_index].Constants.Num32BitValues = (UINT)(push_bytes / 4);
      root_params[push_index].ShaderVisibility = D3D12_SHADER_VISIBILITY_ALL;
    }
  }
  rs_desc.Desc_1_0.NumParameters =
      (UINT)(cbv_count + (uav_tables > 0 ? 1 : 0) + (push_bytes > 0 ? 1 : 0));
  rs_desc.Desc_1_0.pParameters = rs_desc.Desc_1_0.NumParameters > 0 ? root_params : NULL;
  rs_desc.Desc_1_0.Flags = D3D12_ROOT_SIGNATURE_FLAG_NONE;
  hr = g_serialize_rs(&rs_desc, &rs_blob, &rs_err);
  set_hr(hr);
  if (FAILED(hr)) {
    fprintf(stderr, "[tycho-dx12] compute root signature serialise failed: 0x%08lX\n",
            (unsigned long)hr);
    if (rs_err) {
      fprintf(stderr, "[tycho-dx12] %s\n", (const char *)rs_err->lpVtbl->GetBufferPointer(rs_err));
      rs_err->lpVtbl->Release(rs_err);
    }
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
    dump_info_queue(dev, "CreateRootSignature(compute)");
    free(pipe);
    return 0;
  }

  memset(&pso_desc, 0, sizeof pso_desc);
  pso_desc.pRootSignature = pipe->root_signature;
  pso_desc.CS.pShaderBytecode = cs;
  pso_desc.CS.BytecodeLength = (SIZE_T)cs_len;
  hr = dev->device->lpVtbl->CreateComputePipelineState(dev->device, &pso_desc,
                                                       &kIID_ID3D12PipelineState,
                                                       (void **)&pipe->pso);
  set_hr(hr);
  if (FAILED(hr)) {
    fprintf(stderr, "[tycho-dx12] CreateComputePipelineState failed: 0x%08lX\n", (unsigned long)hr);
    dump_info_queue(dev, "CreateComputePipelineState");
    pipe->root_signature->lpVtbl->Release(pipe->root_signature);
    free(pipe);
    return 0;
  }
  return (uint64_t)(uintptr_t)pipe;
}

// Compute work uses the compute root signature / descriptor tables, which is a
// different set of D3D12 calls from the graphics ones, hence separate entry
// points instead of one "set pipeline".
MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_pipeline(uint64_t cmd_p, uint64_t pipe_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxPipeline *pipe = as_pipeline(pipe_p);
  if (!cmds || !pipe) return 0;
  cmds->list->lpVtbl->SetComputeRootSignature(cmds->list, pipe->root_signature);
  cmds->list->lpVtbl->SetPipelineState(cmds->list, pipe->pso);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_uav(uint64_t cmd_p, int32_t root_index,
                                                  uint64_t tex_p) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  TychoDxTexture *tex = as_texture(tex_p);
  ID3D12DescriptorHeap *heaps[1];
  D3D12_GPU_DESCRIPTOR_HANDLE gpu;
  if (!cmds || !cmds->dev || !tex || !tex->has_srv || !tex->srv_is_uav || root_index < 0) {
    return 0;
  }
  heaps[0] = cmds->dev->srv_heap;
  cmds->list->lpVtbl->SetDescriptorHeaps(cmds->list, 1, heaps);
  cmds->dev->srv_heap->lpVtbl->GetGPUDescriptorHandleForHeapStart(cmds->dev->srv_heap, &gpu);
  gpu.ptr += (SIZE_T)tex->srv_slot * cmds->dev->srv_increment;
  cmds->list->lpVtbl->SetComputeRootDescriptorTable(cmds->list, (UINT)root_index, gpu);
  return 1;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_dispatch(uint64_t cmd_p, int32_t x, int32_t y,
                                                   int32_t z) {
  TychoDxCommands *cmds = as_commands(cmd_p);
  if (!cmds || x <= 0 || y <= 0 || z <= 0) return 0;
  cmds->list->lpVtbl->Dispatch(cmds->list, (UINT)x, (UINT)y, (UINT)z);
  return 1;
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
  tex->format = TYCHO_DX12_RT_FORMAT;
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

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_draw_indexed(uint64_t cmd, uint64_t tex,
                                                       int32_t index_count, int32_t instances,
                                                       int32_t first_index,
                                                       int32_t vertex_offset,
                                                       int32_t flip_y) {
  (void)cmd;
  (void)tex;
  (void)index_count;
  (void)instances;
  (void)first_index;
  (void)vertex_offset;
  (void)flip_y;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_extra_targets(uint64_t cmd, uint64_t t1,
                                                            uint64_t t2, uint64_t t3) {
  (void)cmd;
  (void)t1;
  (void)t2;
  (void)t3;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_bind_vertex(uint64_t cmd, int32_t slot,
                                                      uint64_t gpu_address, int32_t size,
                                                      int32_t stride) {
  (void)cmd;
  (void)slot;
  (void)gpu_address;
  (void)size;
  (void)stride;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_bind_index(uint64_t cmd, uint64_t gpu_address,
                                                     int32_t size, int32_t index32) {
  (void)cmd;
  (void)gpu_address;
  (void)size;
  (void)index32;
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

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_root_constants_bytes(uint64_t cmd, int32_t index,
                                                                   const void *data,
                                                                   int32_t words) {
  (void)cmd;
  (void)index;
  (void)data;
  (void)words;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_root_constants_bytes(
    uint64_t cmd, int32_t index, const void *data, int32_t words) {
  (void)cmd;
  (void)index;
  (void)data;
  (void)words;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_buffer_download(uint64_t dev, uint64_t buf, uint8_t *dst,
                                                      int32_t size) {
  (void)dev;
  (void)buf;
  (void)dst;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_root_constants(uint64_t cmd, int32_t index,
                                                             const uint32_t *data,
                                                             int32_t count) {
  (void)cmd;
  (void)index;
  (void)data;
  (void)count;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_root_constants(uint64_t cmd, int32_t index,
                                                                     const uint32_t *data,
                                                                     int32_t count) {
  (void)cmd;
  (void)index;
  (void)data;
  (void)count;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_storage_buffer_create(uint64_t dev, int32_t size) {
  (void)dev;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_buffer_uav(uint64_t cmd, int32_t root_index,
                                                         uint64_t buf) {
  (void)cmd;
  (void)root_index;
  (void)buf;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_readback_buffer_create(uint64_t dev, int32_t size) {
  (void)dev;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_copy_buffer(uint64_t cmd, uint64_t src, uint64_t dst,
                                                      int32_t size) {
  (void)cmd;
  (void)src;
  (void)dst;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_execute_indirect_counted(
    uint64_t cmd, uint64_t tex, int32_t kind, uint64_t arg_buffer, int32_t arg_offset,
    int32_t max_count, uint64_t count_buffer, int32_t count_offset, int32_t flip_y) {
  (void)cmd;
  (void)tex;
  (void)kind;
  (void)arg_buffer;
  (void)arg_offset;
  (void)max_count;
  (void)count_buffer;
  (void)count_offset;
  (void)flip_y;
  return 0;
}

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
                                                       int32_t flip_y, int32_t depth_enable,
                                                       int32_t depth_write,
                                                       int32_t srv_tables,
                                                       int32_t push_bytes,
                                                       int32_t color_count,
                                                       const int32_t *color_formats,
                                                       int32_t input_count,
                                                       const int32_t *inputs) {
  (void)dev;
  (void)vs;
  (void)vs_len;
  (void)ps;
  (void)ps_len;
  (void)cbv_count;
  (void)flip_y;
  (void)depth_enable;
  (void)depth_write;
  (void)srv_tables;
  (void)push_bytes;
  (void)input_count;
  (void)inputs;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_pipeline_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_texture_create(uint64_t dev, int32_t width,
                                                      int32_t height, int32_t format) {
  (void)dev;
  (void)width;
  (void)height;
  (void)format;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_texture_destroy(uint64_t p) { (void)p; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_depth_create(uint64_t dev, int32_t width, int32_t height,
                                                    int32_t format) {
  (void)dev;
  (void)width;
  (void)height;
  (void)format;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_depth(uint64_t cmd, uint64_t tex) {
  (void)cmd;
  (void)tex;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_clear_depth(uint64_t cmd, uint64_t tex, float depth) {
  (void)cmd;
  (void)tex;
  (void)depth;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_texture_create_uploaded(uint64_t dev, int32_t width,
                                                               int32_t height,
                                                               const uint8_t *pixels,
                                                               int32_t pixel_bytes,
                                                               int32_t format) {
  (void)dev;
  (void)width;
  (void)height;
  (void)pixels;
  (void)pixel_bytes;
  (void)format;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_texture(uint64_t cmd, int32_t root_index,
                                                      int32_t sampler_root, uint64_t tex,
                                                      uint64_t sampler) {
  (void)cmd;
  (void)root_index;
  (void)sampler_root;
  (void)tex;
  (void)sampler;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_sampler_create(uint64_t dev, int32_t filter,
                                                      int32_t address, float anisotropy,
                                                      float min_lod, float max_lod,
                                                      float mip_lod_bias) {
  (void)dev;
  (void)filter;
  (void)address;
  (void)anisotropy;
  (void)min_lod;
  (void)max_lod;
  (void)mip_lod_bias;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_sampler_destroy(uint64_t sampler) { (void)sampler; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_storage_texture_create(uint64_t dev, int32_t width,
                                                              int32_t height) {
  (void)dev;
  (void)width;
  (void)height;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_compute_pipeline_create(uint64_t dev, const uint8_t *cs,
                                                               int32_t cs_len, int32_t cbv_count,
                                                               int32_t uav_tables,
                                                               int32_t push_bytes) {
  (void)dev;
  (void)cs;
  (void)cs_len;
  (void)cbv_count;
  (void)uav_tables;
  (void)push_bytes;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_compute_pipeline(uint64_t cmd, uint64_t pipe) {
  (void)cmd;
  (void)pipe;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_set_uav(uint64_t cmd, int32_t root_index,
                                                  uint64_t tex) {
  (void)cmd;
  (void)root_index;
  (void)tex;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_dispatch(uint64_t cmd, int32_t x, int32_t y,
                                                   int32_t z) {
  (void)cmd;
  (void)x;
  (void)y;
  (void)z;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_heap_create(uint64_t dev, int32_t size) {
  (void)dev;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_buffer_heap_destroy(uint64_t heap) { (void)heap; }

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_buffer_place(uint64_t heap, int32_t offset,
                                                    int32_t size) {
  (void)heap;
  (void)offset;
  (void)size;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_execute_indirect(uint64_t cmd, uint64_t tex,
                                                           int32_t kind, uint64_t arg_buffer,
                                                           int32_t arg_offset, int32_t max_count,
                                                           int32_t flip_y) {
  (void)cmd;
  (void)tex;
  (void)kind;
  (void)arg_buffer;
  (void)arg_offset;
  (void)max_count;
  (void)flip_y;
  return 0;
}

MOONBIT_FFI_EXPORT uint64_t tycho_dx12_timestamp_pool_create(uint64_t dev, int32_t count) {
  (void)dev;
  (void)count;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_write_timestamp(uint64_t cmd, uint64_t pool,
                                                          int32_t index) {
  (void)cmd;
  (void)pool;
  (void)index;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_cmd_resolve_timestamps(uint64_t cmd, uint64_t pool) {
  (void)cmd;
  (void)pool;
  return 0;
}

MOONBIT_FFI_EXPORT int64_t tycho_dx12_timestamp_read(uint64_t pool, int32_t index) {
  (void)pool;
  (void)index;
  return -1;
}

MOONBIT_FFI_EXPORT int64_t tycho_dx12_timestamp_frequency(uint64_t pool) {
  (void)pool;
  return 0;
}

MOONBIT_FFI_EXPORT int32_t tycho_dx12_timestamp_pool_count(uint64_t pool) {
  (void)pool;
  return 0;
}

MOONBIT_FFI_EXPORT void tycho_dx12_timestamp_pool_destroy(uint64_t pool) { (void)pool; }

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
