# NeutrinoHostTools

Cross-compilation support for host tools (code generators).

When cross-compiling (e.g., for Emscripten), code generators still need to run on the host machine. This module builds such tools natively even when the main build is cross-compiled.

## Concepts

- **Host tools**: Run on the build machine (e.g., code generators, asset processors)
- **Runtime tools**: Run on the target platform (disabled when cross-compiling)

## Variables

| Variable | Description |
|----------|-------------|
| `NEUTRINO_HOST_TOOLS_DIR` | Directory for host tool builds |
| `NEUTRINO_HOST_TOOLS` | List of registered host tools |

## Functions

### neutrino_require_host_tool

Ensure a host tool is available:

```cmake
neutrino_require_host_tool(datascript
    GIT_REPOSITORY https://github.com/devbrain/datascript.git
    GIT_TAG master
    CMAKE_ARGS -DDATASCRIPT_BUILD_TESTS=OFF
)
```

Arguments:

| Argument | Description |
|----------|-------------|
| `PACKAGE` | Package name for find_package (default: tool name) |
| `TARGET` | CMake target providing the tool |
| `GIT_REPOSITORY` | Git URL for building from source |
| `GIT_TAG` | Git tag/branch to use |
| `CMAKE_ARGS` | Additional CMake arguments |

After calling, the tool is available as:
```cmake
${NEUTRINO_DATASCRIPT_EXECUTABLE}
```

### neutrino_add_host_tool_dependency

Add dependency on a host tool:

```cmake
neutrino_add_host_tool_dependency(my_generated_files datascript)
```

### neutrino_run_host_tool

Run a host tool to generate files:

```cmake
neutrino_run_host_tool(datascript
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/generated/types.hh"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/schema.ds"
    ARGS
        -o "${CMAKE_CURRENT_BINARY_DIR}/generated"
        "${CMAKE_CURRENT_SOURCE_DIR}/schema.ds"
    COMMENT "Generating types from schema"
)
```

Arguments:

| Argument | Description |
|----------|-------------|
| `OUTPUT` | Generated file(s) |
| `DEPENDS` | Input files |
| `ARGS` | Arguments to pass to the tool |
| `WORKING_DIRECTORY` | Working directory |
| `COMMENT` | Build output message |

### neutrino_bootstrap_local_tool

Build a local developer or build tool natively on the host machine:

```cmake
neutrino_bootstrap_local_tool(bin2c
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/tools/buildtools/bin2c.cc"
    STD 20
)
```

When not cross-compiling, it creates a normal executable target. When cross-compiling, it compiles the tool natively using the host compiler and registers it as an `IMPORTED` global target, satisfying target generator expressions like `$<TARGET_FILE:bin2c>` elsewhere in the project.

Arguments:

| Argument | Description |
|----------|-------------|
| `SOURCES` | List of source files for the tool |
| `STD` | C++ standard to compile with (default: `20`) |

After calling, the tool is also registered and available as:
```cmake
${NEUTRINO_BIN2C_EXECUTABLE}
```

## How It Works

### Not Cross-Compiling

1. If the tool target exists in the current build, uses it
2. Otherwise, searches for an installed tool via `find_program`

### Cross-Compiling

1. Searches for a pre-installed tool on the host
2. If not found and `GIT_REPOSITORY` is provided, builds the tool natively using ExternalProject
3. The tool is built in `${NEUTRINO_HOST_TOOLS_DIR}`

## Example: Code Generator

```cmake
# Require the code generator
neutrino_require_host_tool(datascript
    GIT_REPOSITORY https://github.com/devbrain/datascript.git
    GIT_TAG master
)

# Generate code from schema
neutrino_run_host_tool(datascript
    OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/generated/types.hh"
        "${CMAKE_CURRENT_BINARY_DIR}/generated/types.cc"
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/schema.ds"
    ARGS
        --cpp
        -o "${CMAKE_CURRENT_BINARY_DIR}/generated"
        "${CMAKE_CURRENT_SOURCE_DIR}/schema.ds"
)

# Use generated files
add_library(mylib
    src/mylib.cc
    "${CMAKE_CURRENT_BINARY_DIR}/generated/types.cc"
)

target_include_directories(mylib PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

neutrino_add_host_tool_dependency(mylib datascript)
```

## Cross-Compilation Example

Building for WebAssembly while using native code generator:

```bash
# Configure with Emscripten
emcmake cmake -B build \
    -DCMAKE_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake

# Build - datascript is built natively, main project with Emscripten
cmake --build build
```
