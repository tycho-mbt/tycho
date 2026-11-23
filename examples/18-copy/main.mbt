// Example 18 — copy / clear / blit / resolve + events + labels + secondary
// command buffers (headless, offscreen images). Third execution-coverage batch.
// Optional entry points are gated on device-level resolvability; the result is
// asserted by reading back a copied pixel, not by return codes alone.

///|
let na : @vk.VkAllocationCallbacks = @vk.VkAllocationCallbacks::null()

///|
fn alloc_mem(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  req : @vk.VkMemoryRequirements,
  props : UInt32,
) -> @vk.VkDeviceMemory {
  let mp = @vk.VkPhysicalDeviceMemoryProperties::new()
  (ifn.vkGetPhysicalDeviceMemoryProperties)(phys, mp)
  let mut mi = 0
  for i = 0; i < mp.get_memoryTypeCount().reinterpret_as_int(); i = i + 1 {
    if (req.get_memoryTypeBits() & ((1 : UInt32) << i)) != (0 : UInt32) {
      if (mp.get_memoryTypes_at(i).get_propertyFlags() & props) == props {
        mi = i
        break
      }
    }
  }
  let mai = @vk.VkMemoryAllocateInfo::new()
  mai.set_allocationSize(req.get_size())
  mai.set_memoryTypeIndex(mi.reinterpret_as_uint())
  let out = FixedArray::make(1, @vk.VkDeviceMemory::null())
  let _ = (dfn.vkAllocateMemory)(dev, mai, na, out)
  out[0]
}

///|
fn img_barrier(
  cb : @vk.VkCommandBuffer,
  dfn : @vk.DeviceFn,
  image : @vk.VkImage,
  old : UInt32,
  new_layout : UInt32,
  src_stage : UInt64,
  src_access : UInt64,
  dst_stage : UInt64,
  dst_access : UInt64,
  aspect : UInt32,
) -> Unit {
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(aspect)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let b = @vk.VkImageMemoryBarrier2::new()
  b.set_srcStageMask(src_stage)
  b.set_srcAccessMask(src_access)
  b.set_dstStageMask(dst_stage)
  b.set_dstAccessMask(dst_access)
  b.set_oldLayout(old)
  b.set_newLayout(new_layout)
  b.set_srcQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b.set_dstQueueFamilyIndex((0xFFFFFFFF : UInt32))
  b.set_image(image)
  b.set_subresourceRange(range)
  let dep = @vk.VkDependencyInfo::new()
  dep.set_imageMemoryBarrierCount((1 : UInt32))
  dep.set_pImageMemoryBarriers(b)
  (dfn.vkCmdPipelineBarrier2)(cb, dep)
  dep.free()
  b.free()
  range.free()
}

///|
fn make_image(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  format : UInt32,
  samples : UInt32,
  usage : UInt32,
) -> (@vk.VkImage, @vk.VkDeviceMemory) {
  let ci = @vk.VkImageCreateInfo::new()
  ci.set_imageType(@vk.VK_IMAGE_TYPE_2D)
  ci.set_format(format)
  let ext = @vk.VkExtent3D::new()
  ext.set_width((64 : UInt32))
  ext.set_height((64 : UInt32))
  ext.set_depth((1 : UInt32))
  ci.set_extent(ext)
  ci.set_mipLevels((1 : UInt32))
  ci.set_arrayLayers((1 : UInt32))
  ci.set_samples(samples)
  ci.set_tiling(@vk.VK_IMAGE_TILING_OPTIMAL)
  ci.set_usage(usage)
  let out = FixedArray::make(1, @vk.VkImage::null())
  let r = (dfn.vkCreateImage)(dev, ci, na, out)
  if r != 0 {
    return (@vk.VkImage::null(), @vk.VkDeviceMemory::null())
  }
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetImageMemoryRequirements)(dev, out[0], req)
  let mem = alloc_mem(dev, dfn, ifn, phys, req, @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)
  let _ = (dfn.vkBindImageMemory)(dev, out[0], mem, (0 : UInt64))
  ci.free()
  ext.free()
  (out[0], mem)
}

///|
fn make_buffer(
  dev : @vk.VkDevice,
  dfn : @vk.DeviceFn,
  ifn : @vk.InstanceFn,
  phys : @vk.VkPhysicalDevice,
  size : UInt64,
  usage : UInt32,
  props : UInt32,
) -> (@vk.VkBuffer, @vk.VkDeviceMemory) {
  let ci = @vk.VkBufferCreateInfo::new()
  ci.set_size(size)
  ci.set_usage(usage)
  let out = FixedArray::make(1, @vk.VkBuffer::null())
  let _ = (dfn.vkCreateBuffer)(dev, ci, na, out)
  let req = @vk.VkMemoryRequirements::new()
  (dfn.vkGetBufferMemoryRequirements)(dev, out[0], req)
  let mem = alloc_mem(dev, dfn, ifn, phys, req, props)
  let _ = (dfn.vkBindBufferMemory)(dev, out[0], mem, (0 : UInt64))
  ci.free()
  (out[0], mem)
}

///|
fn main {
  let app = @vk.VkApplicationInfo::new()
  app.set_pApplicationName(@vk.cstr("Tycho Copy"))
  app.set_apiVersion((4206592 : UInt32))
  let ici = @vk.VkInstanceCreateInfo::new()
  ici.set_pApplicationInfo(app)
  ici.set_enabledLayerCount((1 : UInt32))
  ici.set_ppEnabledLayerNames(@vk.cstr_array(["VK_LAYER_KHRONOS_validation"]))
  ici.set_enabledExtensionCount((1 : UInt32))
  ici.set_ppEnabledExtensionNames(@vk.cstr_array(["VK_EXT_debug_utils"]))
  let inst_out = FixedArray::make(1, @vk.VkInstance::null())
  let ir = @vk.vkCreateInstance(ici, na, inst_out)
  if ir != 0 {
    println("[18-copy] FAIL — vkCreateInstance=\{ir}")
    return
  }
  let inst = inst_out[0]
  let ifn = @vk.InstanceFn::load(inst)
  let pc = FixedArray::make(1, (16 : UInt32))
  let pdevs = FixedArray::make(16, @vk.VkPhysicalDevice::null())
  let _ = (ifn.vkEnumeratePhysicalDevices)(inst, pc, pdevs)
  let phys = pdevs[0]
  let mut n = 0

  let f13 = @vk.VkPhysicalDeviceVulkan13Features::new()
  f13.set_synchronization2((1 : UInt32))
  let dci = @vk.VkDeviceCreateInfo::new()
  dci.set_pNext(f13.as_ptr())
  let prio = FixedArray::make(1, (1.0 : Float))
  let qci = @vk.VkDeviceQueueCreateInfo::new()
  qci.set_queueFamilyIndex((0 : UInt32))
  qci.set_queueCount((1 : UInt32))
  qci.set_pQueuePriorities(prio)
  dci.set_queueCreateInfoCount((1 : UInt32))
  dci.set_pQueueCreateInfos(qci)
  let dev_out = FixedArray::make(1, @vk.VkDevice::null())
  let dr = (ifn.vkCreateDevice)(phys, dci, na, dev_out)
  if dr != 0 {
    println("[18-copy] FAIL — vkCreateDevice=\{dr}")
    return
  }
  let dev = dev_out[0]
  let dfn = @vk.DeviceFn::load(dev)
  let queue_out = FixedArray::make(1, @vk.VkQueue::null())
  (dfn.vkGetDeviceQueue)(dev, (0 : UInt32), (0 : UInt32), queue_out)
  let queue = queue_out[0]
  let has = fn(name : String) -> Bool {
    (ifn.vkGetDeviceProcAddr)(dev, @vk.cstr(name)) != (0 : UInt64)
  }

  let color_usage = @vk.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT
  let fmt = @vk.VK_FORMAT_R8G8B8A8_UNORM
  let one = @vk.VK_SAMPLE_COUNT_1_BIT
  let (src, src_mem) = make_image(dev, dfn, ifn, phys, fmt, one, color_usage)
  let (dst, dst_mem) = make_image(dev, dfn, ifn, phys, fmt, one, color_usage)
  let (msaa, msaa_mem) = make_image(dev, dfn, ifn, phys, fmt, @vk.VK_SAMPLE_COUNT_4_BIT, color_usage | @vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)
  let (depth, depth_mem) = make_image(dev, dfn, ifn, phys, @vk.VK_FORMAT_D32_SFLOAT, one, @vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT | @vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT)
  let host = @vk.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | @vk.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT
  let local = @vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT
  let npix = 64 * 64
  let bytes = (npix * 4).to_uint64()
  let (up, up_mem) = make_buffer(dev, dfn, ifn, phys, bytes, @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, host)
  let (rb, rb_mem) = make_buffer(dev, dfn, ifn, phys, bytes, @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)
  let (fill, fill_mem) = make_buffer(dev, dfn, ifn, phys, (1024 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT | @vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT, local)
  let (qbuf, qbuf_mem) = make_buffer(dev, dfn, ifn, phys, (64 : UInt64), @vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT, host)

  let parr : Array[Byte] = []
  for i = 0; i < npix; i = i + 1 {
    parr.push((50 : Byte))
    parr.push((100 : Byte))
    parr.push((200 : Byte))
    parr.push((255 : Byte))
  }
  let pattern = Bytes::from_array(parr)
  let _ = @vk.upload_bytes(dev, up_mem, pattern, npix * 4)

  let cpci = @vk.VkCommandPoolCreateInfo::new()
  cpci.set_queueFamilyIndex((0 : UInt32))
  cpci.set_flags(@vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT)
  let cp_out = FixedArray::make(1, @vk.VkCommandPool::null())
  let _ = (dfn.vkCreateCommandPool)(dev, cpci, na, cp_out)
  let cbai = @vk.VkCommandBufferAllocateInfo::new()
  cbai.set_commandPool(cp_out[0])
  cbai.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY)
  cbai.set_commandBufferCount((1 : UInt32))
  let cb_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai, cb_out)
  let cb = cb_out[0]
  let cbai2 = @vk.VkCommandBufferAllocateInfo::new()
  cbai2.set_commandPool(cp_out[0])
  cbai2.set_level(@vk.VK_COMMAND_BUFFER_LEVEL_SECONDARY)
  cbai2.set_commandBufferCount((1 : UInt32))
  let sec_out = FixedArray::make(1, @vk.VkCommandBuffer::null())
  let _ = (dfn.vkAllocateCommandBuffers)(dev, cbai2, sec_out)
  let sec = sec_out[0]

  let evci = @vk.VkEventCreateInfo::new()
  let ev_out = FixedArray::make(1, @vk.VkEvent::null())
  let _ = (dfn.vkCreateEvent)(dev, evci, na, ev_out)
  let ev = ev_out[0]
  let qpci = @vk.VkQueryPoolCreateInfo::new()
  qpci.set_queryType(@vk.VK_QUERY_TYPE_TIMESTAMP)
  qpci.set_queryCount((2 : UInt32))
  let qp_out = FixedArray::make(1, @vk.VkQueryPool::null())
  let _ = (dfn.vkCreateQueryPool)(dev, qpci, na, qp_out)
  let qp = qp_out[0]

  let top = @vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT
  let xfer = @vk.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT
  let xfer32 = @vk.VK_PIPELINE_STAGE_TRANSFER_BIT
  let tw = @vk.VK_ACCESS_2_TRANSFER_WRITE_BIT
  let tr = @vk.VK_ACCESS_2_TRANSFER_READ_BIT
  let color = @vk.VK_IMAGE_ASPECT_COLOR_BIT
  let tdst = @vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL
  let tsrc = @vk.VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL
  let undef = @vk.VK_IMAGE_LAYOUT_UNDEFINED
  let range = @vk.VkImageSubresourceRange::new()
  range.set_aspectMask(color)
  range.set_levelCount((1 : UInt32))
  range.set_layerCount((1 : UInt32))
  let extent = @vk.VkExtent3D::new()
  extent.set_width((64 : UInt32))
  extent.set_height((64 : UInt32))
  extent.set_depth((1 : UInt32))
  let sub = @vk.VkImageSubresourceLayers::new()
  sub.set_aspectMask(color)
  sub.set_layerCount((1 : UInt32))

  // legacy + 2-variant region descriptors for the same 64x64 copy
  let bic = @vk.VkBufferImageCopy::new()
  bic.set_imageSubresource(sub)
  bic.set_imageExtent(extent)
  let bic2 = @vk.VkBufferImageCopy2::new()
  bic2.set_imageSubresource(sub)
  bic2.set_imageExtent(extent)
  let ic = @vk.VkImageCopy::new()
  ic.set_srcSubresource(sub)
  ic.set_dstSubresource(sub)
  ic.set_extent(extent)
  let ic2 = @vk.VkImageCopy2::new()
  ic2.set_srcSubresource(sub)
  ic2.set_dstSubresource(sub)
  ic2.set_extent(extent)
  let res = @vk.VkImageResolve::new()
  res.set_srcSubresource(sub)
  res.set_dstSubresource(sub)
  res.set_extent(extent)
  let res2 = @vk.VkImageResolve2::new()
  res2.set_srcSubresource(sub)
  res2.set_dstSubresource(sub)
  res2.set_extent(extent)
  // VkImageBlit offsets are a fixed array of two VkOffset3D; the setter takes
  // raw bytes. (0,0,0) -> (64,64,1), each component a little-endian int32.
  let oarr : Array[Byte] = []
  for i = 0; i < 24; i = i + 1 {
    oarr.push((0 : Byte))
  }
  oarr[12] = (64 : Byte)
  oarr[16] = (64 : Byte)
  oarr[20] = (1 : Byte)
  let offs = Bytes::from_array(oarr)
  let blit = @vk.VkImageBlit::new()
  blit.set_srcSubresource(sub)
  blit.set_dstSubresource(sub)
  blit.set_srcOffsets(offs)
  blit.set_dstOffsets(offs)
  let blit2 = @vk.VkImageBlit2::new()
  blit2.set_srcSubresource(sub)
  blit2.set_dstSubresource(sub)
  blit2.set_srcOffsets(offs)
  blit2.set_dstOffsets(offs)

  // ---- secondary command buffer: image -> buffer readback ----
  let inh = @vk.VkCommandBufferInheritanceInfo::new()
  let sbi = @vk.VkCommandBufferBeginInfo::new()
  sbi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT)
  sbi.set_pInheritanceInfo(inh)
  let _ = (dfn.vkBeginCommandBuffer)(sec, sbi)
  (dfn.vkCmdCopyImageToBuffer)(sec, dst, tsrc, rb, (1 : UInt32), bic)
  n = n + 1
  if has("vkCmdCopyImageToBuffer2KHR") {
    let ci2 = @vk.VkCopyImageToBufferInfo2::new()
    ci2.set_srcImage(dst)
    ci2.set_srcImageLayout(tsrc)
    ci2.set_dstBuffer(rb)
    ci2.set_regionCount((1 : UInt32))
    ci2.set_pRegions(bic2)
    (dfn.vkCmdCopyImageToBuffer2KHR)(sec, ci2)
    n = n + 1
    ci2.free()
  }
  let _ = (dfn.vkEndCommandBuffer)(sec)

  // ---- primary command buffer ----
  let bi = @vk.VkCommandBufferBeginInfo::new()
  bi.set_flags(@vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT)
  let _ = (dfn.vkBeginCommandBuffer)(cb, bi)
  let lbl = @vk.VkDebugUtilsLabelEXT::new()
  lbl.set_pLabelName(@vk.cstr("tycho-copy-region"))
  (dfn.vkCmdBeginDebugUtilsLabelEXT)(cb, lbl)
  n = n + 1
  (dfn.vkCmdInsertDebugUtilsLabelEXT)(cb, lbl)
  n = n + 1
  if has("vkCmdSetDeviceMask") {
    (dfn.vkCmdSetDeviceMask)(cb, (1 : UInt32))
    n = n + 1
  }
  if has("vkCmdSetDeviceMaskKHR") {
    (dfn.vkCmdSetDeviceMaskKHR)(cb, (1 : UInt32))
    n = n + 1
  }

  img_barrier(cb, dfn, src, undef, tdst, top, (0 : UInt64), xfer, tw, color)
  (dfn.vkCmdCopyBufferToImage)(cb, up, src, tdst, (1 : UInt32), bic)
  if has("vkCmdCopyBufferToImage2KHR") {
    let b2i = @vk.VkCopyBufferToImageInfo2::new()
    b2i.set_srcBuffer(up)
    b2i.set_dstImage(src)
    b2i.set_dstImageLayout(tdst)
    b2i.set_regionCount((1 : UInt32))
    b2i.set_pRegions(bic2)
    (dfn.vkCmdCopyBufferToImage2KHR)(cb, b2i)
    n = n + 1
    b2i.free()
  }
  img_barrier(cb, dfn, src, tdst, tsrc, xfer, tw, xfer, tr, color)
  img_barrier(cb, dfn, dst, undef, tdst, top, (0 : UInt64), xfer, tw, color)

  let cv = @vk.VkClearValue::new()
  cv.set_color_rgba((0.0 : Float), (0.0 : Float), (0.0 : Float), (1.0 : Float))
  (dfn.vkCmdClearColorImage)(cb, dst, tdst, cv.get_color(), (1 : UInt32), range)
  n = n + 1
  (dfn.vkCmdCopyImage)(cb, src, tsrc, dst, tdst, (1 : UInt32), ic)
  n = n + 1
  if has("vkCmdCopyImage2") {
    let ci2 = @vk.VkCopyImageInfo2::new()
    ci2.set_srcImage(src)
    ci2.set_srcImageLayout(tsrc)
    ci2.set_dstImage(dst)
    ci2.set_dstImageLayout(tdst)
    ci2.set_regionCount((1 : UInt32))
    ci2.set_pRegions(ic2)
    (dfn.vkCmdCopyImage2)(cb, ci2)
    n = n + 1
    ci2.free()
  }
  if has("vkCmdCopyImage2KHR") {
    let ci2 = @vk.VkCopyImageInfo2::new()
    ci2.set_srcImage(src)
    ci2.set_srcImageLayout(tsrc)
    ci2.set_dstImage(dst)
    ci2.set_dstImageLayout(tdst)
    ci2.set_regionCount((1 : UInt32))
    ci2.set_pRegions(ic2)
    (dfn.vkCmdCopyImage2KHR)(cb, ci2)
    n = n + 1
    ci2.free()
  }
  (dfn.vkCmdBlitImage)(cb, src, tsrc, dst, tdst, (1 : UInt32), blit, @vk.VK_FILTER_NEAREST)
  n = n + 1
  if has("vkCmdBlitImage2") {
    let bi2 = @vk.VkBlitImageInfo2::new()
    bi2.set_srcImage(src)
    bi2.set_srcImageLayout(tsrc)
    bi2.set_dstImage(dst)
    bi2.set_dstImageLayout(tdst)
    bi2.set_regionCount((1 : UInt32))
    bi2.set_pRegions(blit2)
    bi2.set_filter(@vk.VK_FILTER_NEAREST)
    (dfn.vkCmdBlitImage2)(cb, bi2)
    n = n + 1
    bi2.free()
  }
  if has("vkCmdBlitImage2KHR") {
    let bi2 = @vk.VkBlitImageInfo2::new()
    bi2.set_srcImage(src)
    bi2.set_srcImageLayout(tsrc)
    bi2.set_dstImage(dst)
    bi2.set_dstImageLayout(tdst)
    bi2.set_regionCount((1 : UInt32))
    bi2.set_pRegions(blit2)
    bi2.set_filter(@vk.VK_FILTER_NEAREST)
    (dfn.vkCmdBlitImage2KHR)(cb, bi2)
    n = n + 1
    bi2.free()
  }

  let mut resolved = false
  if msaa.as_ptr() != 0 {
    img_barrier(cb, dfn, msaa, undef, tdst, top, (0 : UInt64), xfer, tw, color)
    (dfn.vkCmdClearColorImage)(cb, msaa, tdst, cv.get_color(), (1 : UInt32), range)
    img_barrier(cb, dfn, msaa, tdst, tsrc, xfer, tw, xfer, tr, color)
    (dfn.vkCmdResolveImage)(cb, msaa, tsrc, dst, tdst, (1 : UInt32), res)
    n = n + 1
    resolved = true
    if has("vkCmdResolveImage2") {
      let ri2 = @vk.VkResolveImageInfo2::new()
      ri2.set_srcImage(msaa)
      ri2.set_srcImageLayout(tsrc)
      ri2.set_dstImage(dst)
      ri2.set_dstImageLayout(tdst)
      ri2.set_regionCount((1 : UInt32))
      ri2.set_pRegions(res2)
      (dfn.vkCmdResolveImage2)(cb, ri2)
      n = n + 1
      ri2.free()
    }
    if has("vkCmdResolveImage2KHR") {
      let ri2 = @vk.VkResolveImageInfo2::new()
      ri2.set_srcImage(msaa)
      ri2.set_srcImageLayout(tsrc)
      ri2.set_dstImage(dst)
      ri2.set_dstImageLayout(tdst)
      ri2.set_regionCount((1 : UInt32))
      ri2.set_pRegions(res2)
      (dfn.vkCmdResolveImage2KHR)(cb, ri2)
      n = n + 1
      ri2.free()
    }
    // restore the copied pattern so the readback assertion is about the copy
    (dfn.vkCmdCopyImage)(cb, src, tsrc, dst, tdst, (1 : UInt32), ic)
  }

  if depth.as_ptr() != 0 {
    img_barrier(cb, dfn, depth, undef, tdst, top, (0 : UInt64), xfer, tw, @vk.VK_IMAGE_ASPECT_DEPTH_BIT)
    let dsv = @vk.VkClearDepthStencilValue::new()
    dsv.set_depth((1.0 : Float))
    let drange = @vk.VkImageSubresourceRange::new()
    drange.set_aspectMask(@vk.VK_IMAGE_ASPECT_DEPTH_BIT)
    drange.set_levelCount((1 : UInt32))
    drange.set_layerCount((1 : UInt32))
    (dfn.vkCmdClearDepthStencilImage)(cb, depth, tdst, dsv, (1 : UInt32), drange)
    n = n + 1
    drange.free()
  }

  (dfn.vkCmdFillBuffer)(cb, fill, (0 : UInt64), (1024 : UInt64), (0xDEADBEEF : UInt32))
  n = n + 1
  let upd = FixedArray::make(16, (7 : Byte))
  (dfn.vkCmdUpdateBuffer)(cb, fill, (0 : UInt64), (16 : UInt64), @vk.byte_ptr(upd))
  n = n + 1
  let bc2 = @vk.VkBufferCopy2::new()
  bc2.set_srcOffset((0 : UInt64))
  bc2.set_dstOffset((512 : UInt64))
  bc2.set_size((512 : UInt64))
  if has("vkCmdCopyBuffer2") {
    let cb2 = @vk.VkCopyBufferInfo2::new()
    cb2.set_srcBuffer(fill)
    cb2.set_dstBuffer(fill)
    cb2.set_regionCount((1 : UInt32))
    cb2.set_pRegions(bc2)
    (dfn.vkCmdCopyBuffer2)(cb, cb2)
    n = n + 1
    cb2.free()
  }
  if has("vkCmdCopyBuffer2KHR") {
    let cb2 = @vk.VkCopyBufferInfo2::new()
    cb2.set_srcBuffer(fill)
    cb2.set_dstBuffer(fill)
    cb2.set_regionCount((1 : UInt32))
    cb2.set_pRegions(bc2)
    (dfn.vkCmdCopyBuffer2KHR)(cb, cb2)
    n = n + 1
    cb2.free()
  }

  // events: legacy + sync2 forms
  (dfn.vkCmdResetEvent)(cb, ev, xfer32)
  n = n + 1
  (dfn.vkCmdSetEvent)(cb, ev, xfer32)
  n = n + 1
  let ev_arr = FixedArray::make(1, ev)
  (dfn.vkCmdWaitEvents)(cb, (1 : UInt32), ev_arr, xfer32, xfer32, (0 : UInt32), @vk.VkMemoryBarrier::null(), (0 : UInt32), @vk.VkBufferMemoryBarrier::null(), (0 : UInt32), @vk.VkImageMemoryBarrier::null())
  n = n + 1
  let dep0 = @vk.VkDependencyInfo::new()
  if has("vkCmdResetEvent2") {
    (dfn.vkCmdResetEvent2)(cb, ev, xfer)
    n = n + 1
  }
  if has("vkCmdResetEvent2KHR") {
    (dfn.vkCmdResetEvent2KHR)(cb, ev, xfer)
    n = n + 1
  }
  if has("vkCmdSetEvent2") {
    (dfn.vkCmdSetEvent2)(cb, ev, dep0)
    n = n + 1
  }
  if has("vkCmdSetEvent2KHR") {
    (dfn.vkCmdSetEvent2KHR)(cb, ev, dep0)
    n = n + 1
  }
  if has("vkCmdWaitEvents2") {
    (dfn.vkCmdWaitEvents2)(cb, (1 : UInt32), ev_arr, dep0)
    n = n + 1
  }
  if has("vkCmdWaitEvents2KHR") {
    (dfn.vkCmdWaitEvents2KHR)(cb, (1 : UInt32), ev_arr, dep0)
    n = n + 1
  }

  (dfn.vkCmdResetQueryPool)(cb, qp, (0 : UInt32), (2 : UInt32))
  n = n + 1
  let mut ts_written = 0
  if has("vkCmdWriteTimestamp2") {
    (dfn.vkCmdWriteTimestamp2)(cb, xfer, qp, (0 : UInt32))
    n = n + 1
    ts_written = 1
  }
  if has("vkCmdWriteTimestamp2KHR") {
    (dfn.vkCmdWriteTimestamp2KHR)(cb, xfer, qp, ts_written.reinterpret_as_uint())
    n = n + 1
    ts_written = ts_written + 1
  }
  if ts_written == 0 {
    // fall back to the legacy timestamp so the copy has available queries
    (dfn.vkCmdWriteTimestamp)(cb, @vk.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT, qp, (0 : UInt32))
    ts_written = 1
  }
  // VK_QUERY_RESULT_WAIT_BIT is only valid on vkGetQueryPoolResults, not here.
  (dfn.vkCmdCopyQueryPoolResults)(cb, qp, (0 : UInt32), ts_written.reinterpret_as_uint(), qbuf, (0 : UInt64), (8 : UInt64), @vk.VK_QUERY_RESULT_64_BIT)
  n = n + 1

  img_barrier(cb, dfn, dst, tdst, tsrc, xfer, tw, xfer, tr, color)
  (dfn.vkCmdExecuteCommands)(cb, (1 : UInt32), sec_out)
  n = n + 1
  (dfn.vkCmdEndDebugUtilsLabelEXT)(cb)
  n = n + 1
  let _ = (dfn.vkEndCommandBuffer)(cb)

  let fci = @vk.VkFenceCreateInfo::new()
  let fence_out = FixedArray::make(1, @vk.VkFence::null())
  let _ = (dfn.vkCreateFence)(dev, fci, na, fence_out)
  let si = @vk.VkSubmitInfo::new()
  si.set_commandBufferCount((1 : UInt32))
  si.set_pCommandBuffers(cb_out)
  let sr = (dfn.vkQueueSubmit)(queue, (1 : UInt32), si, fence_out[0])
  let wr = (dfn.vkWaitForFences)(dev, (1 : UInt32), fence_out, (1 : UInt32), (10000000000 : UInt64))
  if sr != 0 || wr != 0 {
    println("[18-copy] FAIL — submit=\{sr} wait=\{wr}")
    return
  }
  let got = @vk.download_buffer(dev, rb_mem, npix * 4)
  let ok_pixel = got[0] == (50 : Byte) && got[1] == (100 : Byte) && got[2] == (200 : Byte) && got[3] == (255 : Byte)
  let _ = (dfn.vkDeviceWaitIdle)(dev)

  (dfn.vkDestroyFence)(dev, fence_out[0], na)
  (dfn.vkDestroyQueryPool)(dev, qp, na)
  (dfn.vkDestroyEvent)(dev, ev, na)
  (dfn.vkDestroyCommandPool)(dev, cp_out[0], na)
  (dfn.vkDestroyBuffer)(dev, up, na)
  (dfn.vkFreeMemory)(dev, up_mem, na)
  (dfn.vkDestroyBuffer)(dev, rb, na)
  (dfn.vkFreeMemory)(dev, rb_mem, na)
  (dfn.vkDestroyBuffer)(dev, fill, na)
  (dfn.vkFreeMemory)(dev, fill_mem, na)
  (dfn.vkDestroyBuffer)(dev, qbuf, na)
  (dfn.vkFreeMemory)(dev, qbuf_mem, na)
  (dfn.vkDestroyImage)(dev, src, na)
  (dfn.vkFreeMemory)(dev, src_mem, na)
  (dfn.vkDestroyImage)(dev, dst, na)
  (dfn.vkFreeMemory)(dev, dst_mem, na)
  if msaa.as_ptr() != 0 {
    (dfn.vkDestroyImage)(dev, msaa, na)
    (dfn.vkFreeMemory)(dev, msaa_mem, na)
  }
  if depth.as_ptr() != 0 {
    (dfn.vkDestroyImage)(dev, depth, na)
    (dfn.vkFreeMemory)(dev, depth_mem, na)
  }
  (dfn.vkDestroyDevice)(dev, na)
  (ifn.vkDestroyInstance)(inst, na)
  println("[18-copy] commands=\{n} resolved=\{resolved} pixel=\{got[0]},\{got[1]},\{got[2]},\{got[3]}")
  if ok_pixel && n >= 25 {
    println("[18-copy] OK — \{n} recording commands, copied pixel verified")
  } else {
    println("[18-copy] FAIL — pixel_ok=\{ok_pixel} n=\{n}")
  }
}