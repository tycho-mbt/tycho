name = "laplaceliu/tycho"

version = "0.10.0"

license = "Apache-2.0"

readme = "README.md"

repository = "https://github.com/tycho-mbt/tycho"

preferred_target = "native"

description = "Tycho RHI — unified pure-MoonBit render hardware interface (Vulkan 1.3 backend + DX12 backend seam; Metal planned)"

keywords = [ "graphics", "rhi", "vulkan", "gpu", "tycho" ]

import {
  "laplaceliu/tycho_vulkan@0.7.0",
  "laplaceliu/tycho_dx12@0.1.0",
  "laplaceliu/tycho_window@0.8.1",
  "laplaceliu/tycho_shader@0.8.0",
  "laplaceliu/tycho_math@0.9.0",
}
