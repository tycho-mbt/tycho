name = "laplaceliu/tycho"

version = "0.8.0"

license = "Apache-2.0"

readme = "README.md"

repository = "https://github.com/tycho-mbt/tycho"

preferred_target = "native"

description = "Tycho RHI — unified pure-MoonBit render hardware interface (Vulkan 1.3 dynamic rendering + sub-allocator; Metal/DX12 planned)"

keywords = [ "graphics", "rhi", "vulkan", "gpu", "tycho" ]

import {
  "laplaceliu/tycho_vulkan@0.7.0",
  "laplaceliu/tycho_window@0.7.0",
  "laplaceliu/tycho_shader@0.7.0",
}
