# 17-objects

Example 17 — object lifecycle / memory / sync / descriptor coverage (headless).

Two driver quirks are handled explicitly:
* a promoted core name may not resolve at device level even though its KHR
alias does (vkMapMemory2, vkGetImageSubresourceLayout2, ...), so every
core-name call is gated on vkGetDeviceProcAddr;
* device-address queries need memory allocated with VkMemoryAllocateFlagsInfo.

## Windowing

This example runs headless (offscreen compute/graphics/API verification) and does not open a window.

## Run

```bash
./build.sh
./_build/native/debug/build/laplaceliu/tycho_vulkan_examples/17-objects/17-objects.exe
```

## Output

```text
Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-format-01650 ] | MessageID = 0x9f80a3e9
vkCreateSamplerYcbcrConversion(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support either VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT or VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: The potential format features of the sampler Y'CBCR conversion must support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT or VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-format-01650)

Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-xChromaOffset-01652 ] | MessageID = 0x681d493e
vkCreateSamplerYcbcrConversion(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT so xChromaOffset can't be VK_CHROMA_LOCATION_MIDPOINT
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: If the potential format features of the sampler Y'CBCR conversion do not support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT, xChromaOffset and yChromaOffset must not be VK_CHROMA_LOCATION_MIDPOINT if the corresponding components are downsampled (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-xChromaOffset-01652)

Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-chromaFilter-01657 ] | MessageID = 0xb530d3b4
vkCreateSamplerYcbcrConversion(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT so chromaFilter must not be VK_FILTER_LINEAR
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: If the potential format features of the sampler Y'CBCR conversion do not support VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT, chromaFilter must not be VK_FILTER_LINEAR (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-chromaFilter-01657)

Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-format-01650 ] | MessageID = 0x9f80a3e9
vkCreateSamplerYcbcrConversionKHR(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support either VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT or VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: The potential format features of the sampler Y'CBCR conversion must support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT or VK_FORMAT_FEATURE_COSITED_CHROMA_SAMPLES_BIT (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-format-01650)

Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-xChromaOffset-01652 ] | MessageID = 0x681d493e
vkCreateSamplerYcbcrConversionKHR(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT so xChromaOffset can't be VK_CHROMA_LOCATION_MIDPOINT
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: If the potential format features of the sampler Y'CBCR conversion do not support VK_FORMAT_FEATURE_MIDPOINT_CHROMA_SAMPLES_BIT, xChromaOffset and yChromaOffset must not be VK_CHROMA_LOCATION_MIDPOINT if the corresponding components are downsampled (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-xChromaOffset-01652)

Validation Error: [ VUID-VkSamplerYcbcrConversionCreateInfo-chromaFilter-01657 ] | MessageID = 0xb530d3b4
vkCreateSamplerYcbcrConversionKHR(): pCreateInfo->format (VK_FORMAT_G8B8G8R8_422_UNORM) doesn't support VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT so chromaFilter must not be VK_FILTER_LINEAR
(supported features: VkFormatFeatureFlags2(0)).
The Vulkan spec states: If the potential format features of the sampler Y'CBCR conversion do not support VK_FORMAT_FEATURE_SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_BIT, chromaFilter must not be VK_FILTER_LINEAR (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/samplers.html#VUID-VkSamplerYcbcrConversionCreateInfo-chromaFilter-01657)

Validation Error: [ VUID-vkGetMemoryFdPropertiesKHR-handleType-00674 ] | MessageID = 0x74ca4b9e
vkGetMemoryFdPropertiesKHR(): handleType (VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT) is not allowed.
The Vulkan spec states: handleType must not be VK_EXTERNAL_MEMORY_HANDLE_TYPE_OPAQUE_FD_BIT (https://vulkan.lunarg.com/doc/view/1.4.363.1/linux/antora/spec/latest/chapters/memory.html#VUID-vkGetMemoryFdPropertiesKHR-handleType-00674)

[17-obj] memory fd properties result=-13
[17-obj] commands exercised=89
[17-obj] OK — 89 object/memory/sync commands, results asserted
```
