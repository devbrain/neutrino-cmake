# imgui

Dear ImGui - Immediate mode GUI library.

## Targets

| Target | Description |
|--------|-------------|
| `imgui::imgui` | Core library |
| `imgui::backend_sdl2` | SDL2 platform backend |
| `imgui::backend_sdl3` | SDL3 platform backend |
| `imgui::backend_opengl3` | OpenGL3 renderer |
| `imgui::backend_vulkan` | Vulkan renderer |
| `imgui::backend_sdlrenderer2` | SDL2 Renderer backend |
| `imgui::backend_sdlrenderer3` | SDL3 Renderer backend |

## Usage

### Basic

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/imgui.cmake)
neutrino_fetch_imgui()

target_link_libraries(myapp PRIVATE imgui::imgui)
```

### With Backends

Enable backends before fetching:

```cmake
set(NEUTRINO_IMGUI_BACKEND_SDL3 ON CACHE BOOL "")
set(NEUTRINO_IMGUI_BACKEND_OPENGL3 ON CACHE BOOL "")

include(${NEUTRINO_CMAKE_DIR}/deps/imgui.cmake)
neutrino_fetch_imgui()

target_link_libraries(myapp PRIVATE
    imgui::imgui
    imgui::backend_sdl3
    imgui::backend_opengl3
)
```

### Convenience Functions

```cmake
# SDL3 + OpenGL3 combo
neutrino_fetch_imgui_sdl3_opengl3()

# SDL3 + SDL Renderer combo
neutrino_fetch_imgui_sdl3_renderer()
```

## Version

```cmake
set(NEUTRINO_IMGUI_VERSION "1.91.6" CACHE STRING "")
```

## Backend Options

| Option | Description |
|--------|-------------|
| `NEUTRINO_IMGUI_BACKEND_SDL2` | SDL2 platform |
| `NEUTRINO_IMGUI_BACKEND_SDL3` | SDL3 platform |
| `NEUTRINO_IMGUI_BACKEND_GLFW` | GLFW platform |
| `NEUTRINO_IMGUI_BACKEND_OPENGL3` | OpenGL3 renderer |
| `NEUTRINO_IMGUI_BACKEND_VULKAN` | Vulkan renderer |
| `NEUTRINO_IMGUI_BACKEND_SDLRENDERER2` | SDL2 Renderer |
| `NEUTRINO_IMGUI_BACKEND_SDLRENDERER3` | SDL3 Renderer |

## Links

- [Dear ImGui GitHub](https://github.com/ocornut/imgui)
