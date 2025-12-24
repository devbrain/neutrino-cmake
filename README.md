# neutrino-cmake

CMake tooling for the Neutrino C++ ecosystem.

## Overview

neutrino-cmake provides centralized CMake modules for consistent builds across all Neutrino ecosystem projects:

- **Standardized options** - Consistent naming convention (`NEUTRINO_<COMP>_BUILD_*`)
- **Compiler warnings** - Pre-configured strict warnings for MSVC, GCC, and Clang
- **Sanitizers** - Easy ASan, UBSan, TSan, MSan integration
- **Dependency recipes** - Ready-to-use FetchContent configurations
- **Installation helpers** - Package config file generation
- **Cross-compilation** - Emscripten and host tools support

## Quick Start

### Using in Your Project

```cmake
cmake_minimum_required(VERSION 3.20)
project(mylib VERSION 1.0.0 LANGUAGES CXX)

include(FetchContent)

FetchContent_Declare(neutrino_cmake
    GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
    GIT_TAG master
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(neutrino_cmake)

list(APPEND CMAKE_MODULE_PATH "${neutrino_cmake_SOURCE_DIR}/cmake")
include(NeutrinoInit)

# Now use neutrino-cmake functions
neutrino_define_options(mylib)

add_library(mylib INTERFACE)
add_library(neutrino::mylib ALIAS mylib)

neutrino_target_warnings(mylib)
```

### Creating a New Project

Use the project generator:

```bash
./scripts/neutrino-new.py mylib --type=header-only --std=20 --with-tests
```

## Available Modules

| Module | Description |
|--------|-------------|
| `NeutrinoInit.cmake` | Entry point - includes all other modules |
| `NeutrinoPolicies.cmake` | CMake version and policy configuration |
| `NeutrinoCompiler.cmake` | Compiler and platform detection |
| `NeutrinoOptions.cmake` | Standardized option definitions |
| `NeutrinoWarnings.cmake` | Compiler warning flags |
| `NeutrinoSanitizers.cmake` | Runtime sanitizer support |
| `NeutrinoInstall.cmake` | Installation and packaging helpers |
| `NeutrinoHostTools.cmake` | Cross-compilation host tool support |

## Dependency Recipes

Located in `cmake/deps/`:

| Recipe | Target | Description |
|--------|--------|-------------|
| `doctest.cmake` | `doctest::doctest` | Testing framework |
| `termcolor.cmake` | `termcolor::termcolor` | Terminal colors |
| `utf8cpp.cmake` | `utf8cpp::utf8cpp` | UTF-8 handling |
| `expected.cmake` | `tl::expected` | std::expected backport |
| `xsimd.cmake` | `xsimd::xsimd` | SIMD abstraction |
| `benchmark.cmake` | `benchmark::benchmark` | Google Benchmark |
| `SDL2.cmake` | `SDL2::SDL2` | SDL2 |
| `SDL3.cmake` | `SDL3::SDL3` | SDL3 |
| `imgui.cmake` | `imgui::imgui` | Dear ImGui |
| `failsafe.cmake` | `neutrino::failsafe` | Error handling |
| `euler.cmake` | `neutrino::euler` | Line rasterization |
| `mio.cmake` | `neutrino::mio` | Memory-mapped I/O |
| `libiff.cmake` | `neutrino::iff` | IFF file format |
| `scaler.cmake` | `neutrino::scaler` | Image scaling |
| `mz-explode.cmake` | `neutrino::mzexplode` | MZ decompression |
| `datascript.cmake` | `neutrino::datascript` | Binary parser generator |
| `sdlpp.cmake` | `neutrino::sdlpp` | C++ SDL3 wrapper |

### Using a Dependency

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)
neutrino_fetch_failsafe()

target_link_libraries(mylib PUBLIC neutrino::failsafe)
```

## Configuration Options

### Build Options

```bash
cmake -B build \
    -DNEUTRINO_MYLIB_BUILD_TESTS=ON \
    -DNEUTRINO_MYLIB_BUILD_EXAMPLES=ON \
    -DNEUTRINO_MYLIB_BUILD_BENCHMARKS=OFF
```

### Sanitizers

```bash
cmake -B build \
    -DNEUTRINO_ENABLE_ASAN=ON \
    -DNEUTRINO_ENABLE_UBSAN=ON
```

### Warnings

```bash
cmake -B build \
    -DNEUTRINO_WARNINGS_AS_ERRORS=ON  # Default: ON
```

## Target Namespace

All Neutrino ecosystem libraries use the `neutrino::` namespace:

```cmake
target_link_libraries(myapp PRIVATE
    neutrino::failsafe
    neutrino::euler
    neutrino::sdlpp
)
```

## License

MIT License
