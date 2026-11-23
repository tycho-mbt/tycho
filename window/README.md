# laplaceliu/tycho_window

Thin pure-MoonBit windowing and Vulkan WSI surface wrapper over GLFW 3 for the Tycho graphics stack.

Users call `@win.initialize()`, `@win.create(...)`, `@win.create_surface(...)`, `@win.surface_extensions()`, `@win.poll()`, and `@win.destroy(...)` without writing C or GLFW FFI declarations.
