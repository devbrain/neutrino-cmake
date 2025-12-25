# Dependency Recipes

neutrino-cmake provides ready-to-use FetchContent configurations for common dependencies.

## Usage

```cmake
# Include the recipe
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)

# Fetch the dependency
neutrino_fetch_failsafe()

# Link to your target
target_link_libraries(mylib PUBLIC neutrino::failsafe)
```

## Available Dependencies

### Third-Party Libraries

| Recipe | Target | Description |
|--------|--------|-------------|
| [doctest](doctest.md) | `doctest::doctest` | Testing framework |
| [termcolor](termcolor.md) | `termcolor::termcolor` | Terminal colors |
| [utf8cpp](utf8cpp.md) | `utf8cpp::utf8cpp` | UTF-8 handling |
| [expected](expected.md) | `tl::expected` | std::expected backport |
| [xsimd](xsimd.md) | `xsimd::xsimd` | SIMD abstraction |
| [benchmark](benchmark.md) | `benchmark::benchmark` | Google Benchmark |
| [SDL2](SDL2.md) | `SDL2::SDL2` | Simple DirectMedia Layer 2 |
| [SDL3](SDL3.md) | `SDL3::SDL3` | Simple DirectMedia Layer 3 |
| [imgui](imgui.md) | `imgui::imgui` | Dear ImGui |

### Neutrino Libraries

| Recipe | Target | Description |
|--------|--------|-------------|
| [failsafe](failsafe.md) | `neutrino::failsafe` | Error handling & logging |
| [euler](euler.md) | `neutrino::euler` | Line rasterization |
| [mio](mio.md) | `neutrino::mio` | Memory-mapped I/O |
| [libiff](libiff.md) | `neutrino::iff` | IFF/RIFF file parsing |
| [scaler](scaler.md) | `neutrino::scaler` | Image scaling |
| [mz-explode](mz-explode.md) | `neutrino::mzexplode` | MZ decompression |
| [datascript](datascript.md) | `neutrino::datascript` | Binary parser generator |
| [sdlpp](sdlpp.md) | `neutrino::sdlpp` | C++ SDL3 wrapper |

## Version Control

Each recipe has a version variable:

```cmake
# Override before fetching
set(NEUTRINO_DOCTEST_VERSION "2.4.11" CACHE STRING "")

include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
neutrino_fetch_doctest()
```

## System Package Detection

Many recipes first try to find a system-installed version:

```cmake
# Uses system package if available, otherwise fetches
neutrino_fetch_SDL2()
```

To force fetching:

```bash
cmake -B build -DCMAKE_DISABLE_FIND_PACKAGE_SDL2=ON
```

## Static vs Shared

For SDL2/SDL3:

```cmake
neutrino_fetch_SDL2(STATIC)  # Force static linking
neutrino_fetch_SDL2(SHARED)  # Force shared linking
```

## Multiple Dependencies Example

```cmake
# Fetch all needed dependencies
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
include(${NEUTRINO_CMAKE_DIR}/deps/SDL3.cmake)

neutrino_fetch_failsafe()
neutrino_fetch_SDL3()

# For tests only
if(NEUTRINO_MYLIB_BUILD_TESTS)
    neutrino_fetch_doctest()
endif()

# Link to targets
target_link_libraries(mylib PUBLIC
    neutrino::failsafe
    SDL3::SDL3
)

target_link_libraries(mylib_test PRIVATE
    doctest::doctest
)
```
