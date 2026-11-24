// Pure-MoonBit free-list GPU memory sub-allocator.
// Separates pure interval management (RegionPool, unit-tested without GPU)
// from Vulkan device memory blocks (SubAllocator).

///|
priv struct FreeRegion {
  offset : UInt64
  size : UInt64
}

///|
priv struct RegionPool {
  free_list : Array[FreeRegion]
  mut alloc_count : Int
  mut used_size : UInt64
}

///|
fn align_up_u64(val : UInt64, align : UInt64) -> UInt64 {
  if align <= (1 : UInt64) {
    return val
  }
  let rem = val % align
  if rem == (0 : UInt64) {
    val
  } else {
    val + (align - rem)
  }
}

///|
fn RegionPool::new(total_size : UInt64) -> RegionPool {
  let free_list : Array[FreeRegion] = []
  if total_size > (0 : UInt64) {
    free_list.push({ offset: (0 : UInt64), size: total_size })
  }
  { free_list, alloc_count: 0, used_size: (0 : UInt64) }
}

///|
fn RegionPool::try_alloc(
  self : RegionPool,
  size : UInt64,
  alignment : UInt64,
) -> UInt64? {
  if size == (0 : UInt64) {
    return None
  }
  let align = if alignment == (0 : UInt64) { (1 : UInt64) } else { alignment }
  for i = 0; i < self.free_list.length(); i = i + 1 {
    let reg = self.free_list[i]
    let aligned = align_up_u64(reg.offset, align)
    let pad = aligned - reg.offset
    if reg.size >= pad + size {
      let rem_after = reg.size - (pad + size)
      let _ = self.free_list.remove(i)
      let mut insert_at = i
      if pad > (0 : UInt64) {
        self.free_list.insert(insert_at, { offset: reg.offset, size: pad })
        insert_at = insert_at + 1
      }
      if rem_after > (0 : UInt64) {
        self.free_list.insert(insert_at, {
          offset: aligned + size,
          size: rem_after,
        })
      }
      self.alloc_count = self.alloc_count + 1
      self.used_size = self.used_size + size
      return Some(aligned)
    }
  }
  None
}

///|
fn RegionPool::free(self : RegionPool, offset : UInt64, size : UInt64) -> Unit {
  if size == (0 : UInt64) {
    return
  }
  // Find sorted insertion point
  let mut idx = 0
  while idx < self.free_list.length() && self.free_list[idx].offset < offset {
    idx = idx + 1
  }
  self.free_list.insert(idx, { offset, size })
  // Coalesce with next region
  if idx + 1 < self.free_list.length() {
    let cur = self.free_list[idx]
    let nxt = self.free_list[idx + 1]
    if cur.offset + cur.size == nxt.offset {
      self.free_list[idx] = { offset: cur.offset, size: cur.size + nxt.size }
      let _ = self.free_list.remove(idx + 1)
    }
  }
  // Coalesce with previous region
  if idx > 0 {
    let prev = self.free_list[idx - 1]
    let cur = self.free_list[idx]
    if prev.offset + prev.size == cur.offset {
      self.free_list[idx - 1] = {
        offset: prev.offset,
        size: prev.size + cur.size,
      }
      let _ = self.free_list.remove(idx)
    }
  }
  self.alloc_count = self.alloc_count - 1
  self.used_size = self.used_size - size
}

///|
fn RegionPool::used_bytes(self : RegionPool) -> UInt64 {
  self.used_size
}

///|
// 16 MiB default GPU memory block size.
const DEFAULT_BLOCK_SIZE : UInt64 = 16777216

///|
priv struct MemBlock {
  memory : @vk.VkDeviceMemory
  mem_type : Int
  is_image : Bool
  pool : RegionPool
  mapped : UInt64
}

///|
priv struct MemAlloc {
  block_idx : Int
  memory : @vk.VkDeviceMemory
  offset : UInt64
  size : UInt64
  mapped : UInt64
}

///|
priv struct SubAllocator {
  dev : @vk.VkDevice
  dfn : @vk.DeviceFn
  ifn : @vk.InstanceFn
  phys : @vk.VkPhysicalDevice
  enable_device_address : Bool
  blocks : Array[MemBlock]
  mut active_allocs : Int
}

///|
fn SubAllocator::new(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  enable_device_address? : Bool = false,
) -> SubAllocator {
  { dev, dfn, ifn, phys, enable_device_address, blocks: [], active_allocs: 0 }
}

///|
fn find_memory_type(
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  type_bits : UInt32,
  flags : UInt32,
) -> Int? {
  let props = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, props)
  let n = props.get_memoryTypeCount().reinterpret_as_int()
  for i = 0; i < n; i = i + 1 {
    if (type_bits & ((1 : UInt32) << i)) != (0 : UInt32) {
      if (props.get_memoryTypes_at(i).get_propertyFlags() & flags) == flags {
        props.free()
        return Some(i)
      }
    }
  }
  props.free()
  None
}

///|
fn SubAllocator::allocate_block(
  self : SubAllocator,
  mem_type : Int,
  block_size : UInt64,
  host_visible : Bool,
  is_image : Bool,
) -> Int raise RhiError {
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(block_size)
  mai.set_memoryTypeIndex(mem_type.reinterpret_as_uint())
  let maf = @vk.VkMemoryAllocateFlagsInfo::new()
  if self.enable_device_address {
    maf.set_flags(@vk.VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT)
    mai.set_pNext(maf.as_ptr())
  }
  let mem_out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let r = (self.dfn.vkAllocateMemory)(
    self.dev,
    mai,
    @vk.VkAllocationCallbacks::null(),
    mem_out,
  )
  maf.free()
  mai.free()
  if r != 0 {
    raise AllocationFailed("vkAllocateMemory failed with code \{r}")
  }
  let memory = mem_out[0]
  let mut mapped : UInt64 = (0 : UInt64)
  if host_visible {
    let ptr_out : FixedArray[UInt64] = FixedArray::make(1, (0 : UInt64))
    let mr = (self.dfn.vkMapMemory)(
      self.dev,
      memory,
      (0 : UInt64),
      block_size,
      (0 : UInt32),
      ptr_out,
    )
    if mr != 0 {
      (self.dfn.vkFreeMemory)(
        self.dev,
        memory,
        @vk.VkAllocationCallbacks::null(),
      )
      raise AllocationFailed("vkMapMemory failed with code \{mr}")
    }
    mapped = ptr_out[0]
  }
  let idx = self.blocks.length()
  self.blocks.push({
    memory,
    mem_type,
    is_image,
    pool: RegionPool::new(block_size),
    mapped,
  })
  idx
}

///|
fn SubAllocator::alloc(
  self : SubAllocator,
  req : @vk.VkMemoryRequirements,
  flags : UInt32,
  host_visible : Bool,
  is_image : Bool,
) -> MemAlloc raise RhiError {
  let type_bits = req.get_memoryTypeBits()
  let size = req.get_size()
  let align = req.get_alignment()
  let mem_type = match find_memory_type(self.ifn, self.phys, type_bits, flags) {
    Some(idx) => idx
    None =>
      raise AllocationFailed(
        "No compatible Vulkan memory type (bits=\{type_bits}, flags=\{flags})",
      )
  }
  // Search existing blocks matching (mem_type, is_image) and mapping capability.
  for i = 0; i < self.blocks.length(); i = i + 1 {
    let blk = self.blocks[i]
    if blk.mem_type == mem_type &&
      blk.is_image == is_image &&
      (!host_visible || blk.mapped != (0 : UInt64)) {
      match blk.pool.try_alloc(size, align) {
        Some(offset) => {
          self.active_allocs = self.active_allocs + 1
          let ptr = if blk.mapped != (0 : UInt64) {
            blk.mapped + offset
          } else {
            (0 : UInt64)
          }
          return { block_idx: i, memory: blk.memory, offset, size, mapped: ptr }
        }
        None => ()
      }
    }
  }
  let block_size = if size > DEFAULT_BLOCK_SIZE {
    size
  } else {
    DEFAULT_BLOCK_SIZE
  }
  let new_idx = self.allocate_block(mem_type, block_size, host_visible, is_image)
  let blk = self.blocks[new_idx]
  match blk.pool.try_alloc(size, align) {
    Some(offset) => {
      self.active_allocs = self.active_allocs + 1
      let ptr = if blk.mapped != (0 : UInt64) {
        blk.mapped + offset
      } else {
        (0 : UInt64)
      }
      { block_idx: new_idx, memory: blk.memory, offset, size, mapped: ptr }
    }
    None =>
      raise AllocationFailed(
        "Fresh memory block failed sub-allocation (size=\{size}, align=\{align})",
      )
  }
}

///|
fn SubAllocator::free(self : SubAllocator, alloc : MemAlloc) -> Unit {
  if alloc.block_idx >= 0 && alloc.block_idx < self.blocks.length() {
    self.blocks[alloc.block_idx].pool.free(alloc.offset, alloc.size)
    self.active_allocs = self.active_allocs - 1
  }
}

///|
fn SubAllocator::stats(self : SubAllocator) -> (Int, Int) {
  (self.blocks.length(), self.active_allocs)
}

///|
fn SubAllocator::used_bytes(self : SubAllocator) -> UInt64 {
  let mut sum : UInt64 = (0 : UInt64)
  for blk in self.blocks {
    sum = sum + blk.pool.used_bytes()
  }
  sum
}

///|
fn SubAllocator::destroy(self : SubAllocator) -> Unit {
  let na = @vk.VkAllocationCallbacks::null()
  for blk in self.blocks {
    if blk.mapped != (0 : UInt64) {
      (self.dfn.vkUnmapMemory)(self.dev, blk.memory)
    }
    (self.dfn.vkFreeMemory)(self.dev, blk.memory, na)
  }
  self.blocks.clear()
  self.active_allocs = 0
}
