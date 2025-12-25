# neutrino-cmake

CMake tooling for the Neutrino C++ ecosystem.

## Overview

neutrino-cmake provides centralized CMake modules for consistent builds across all Neutrino ecosystem projects:

- **Standardized options** - Consistent naming convention (`NEUTRINO_<COMP>_BUILD_*`)
- **Compiler warnings** - Pre-configured strict warnings for MSVC, GCC, and Clang
- **Sanitizers** - Easy ASan, UBSan, TSan, MSan integration
- **Dependency recipes** - Ready-to-use FetchContent configurations for 17+ libraries
- **Installation helpers** - Package config file generation
- **Cross-compilation** - Emscripten and host tools support

## Documentation

- [Getting Started](docs/getting-started.md) - Step-by-step integration guide
- [Creating a Library](docs/creating-a-library.md) - How to create a new Neutrino library
- [Dependencies](docs/dependencies/) - Individual dependency documentation
- [Modules](docs/modules/) - Core module documentation

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

| Module | Description | Docs |
|--------|-------------|------|
| `NeutrinoInit.cmake` | Entry point - includes all other modules | |
| `NeutrinoPolicies.cmake` | CMake version and policy configuration | |
| `NeutrinoCompiler.cmake` | Compiler and platform detection | [docs](docs/modules/compiler.md) |
| `NeutrinoOptions.cmake` | Standardized option definitions | [docs](docs/modules/options.md) |
| `NeutrinoWarnings.cmake` | Compiler warning flags | [docs](docs/modules/warnings.md) |
| `NeutrinoSanitizers.cmake` | Runtime sanitizer support | [docs](docs/modules/sanitizers.md) |
| `NeutrinoInstall.cmake` | Installation and packaging helpers | [docs](docs/modules/install.md) |
| `NeutrinoHostTools.cmake` | Cross-compilation host tool support | [docs](docs/modules/host-tools.md) |

## Dependency Recipes

Located in `cmake/deps/`. See [dependencies overview](docs/dependencies/) for full documentation.

| Recipe | Target | Description |
|--------|--------|-------------|
| [`doctest.cmake`](docs/dependencies/doctest.md) | `doctest::doctest` | Testing framework |
| [`termcolor.cmake`](docs/dependencies/termcolor.md) | `termcolor::termcolor` | Terminal colors |
| [`utf8cpp.cmake`](docs/dependencies/utf8cpp.md) | `utf8cpp::utf8cpp` | UTF-8 handling |
| [`expected.cmake`](docs/dependencies/expected.md) | `tl::expected` | std::expected backport |
| [`xsimd.cmake`](docs/dependencies/xsimd.md) | `xsimd::xsimd` | SIMD abstraction |
| [`benchmark.cmake`](docs/dependencies/benchmark.md) | `benchmark::benchmark` | Google Benchmark |
| [`SDL2.cmake`](docs/dependencies/SDL2.md) | `SDL2::SDL2` | SDL2 |
| [`SDL3.cmake`](docs/dependencies/SDL3.md) | `SDL3::SDL3` | SDL3 |
| [`imgui.cmake`](docs/dependencies/imgui.md) | `imgui::imgui` | Dear ImGui |
| [`failsafe.cmake`](docs/dependencies/failsafe.md) | `neutrino::failsafe` | Error handling |
| [`euler.cmake`](docs/dependencies/euler.md) | `neutrino::euler` | Line rasterization |
| [`mio.cmake`](docs/dependencies/mio.md) | `neutrino::mio` | Memory-mapped I/O |
| [`libiff.cmake`](docs/dependencies/libiff.md) | `neutrino::iff` | IFF file format |
| [`scaler.cmake`](docs/dependencies/scaler.md) | `neutrino::scaler` | Image scaling |
| [`mz-explode.cmake`](docs/dependencies/mz-explode.md) | `neutrino::mzexplode` | MZ decompression |
| [`datascript.cmake`](docs/dependencies/datascript.md) | `neutrino::datascript` | Binary parser generator |
| [`sdlpp.cmake`](docs/dependencies/sdlpp.md) | `neutrino::sdlpp` | C++ SDL3 wrapper |

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
