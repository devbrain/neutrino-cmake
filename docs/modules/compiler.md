# NeutrinoCompiler

Compiler detection, platform identification, and feature flags.

## Compiler Detection

After including NeutrinoInit, these variables are available:

| Variable | Description |
|----------|-------------|
| `NEUTRINO_COMPILER_IS_MSVC` | ON for MSVC |
| `NEUTRINO_COMPILER_IS_GCC` | ON for GCC |
| `NEUTRINO_COMPILER_IS_CLANG` | ON for Clang (including AppleClang) |
| `NEUTRINO_COMPILER_IS_APPLECLANG` | ON for AppleClang specifically |
| `NEUTRINO_COMPILER_IS_INTEL` | ON for Intel compiler |
| `NEUTRINO_COMPILER_NAME` | Human-readable compiler name |
| `NEUTRINO_COMPILER_VERSION` | Compiler version string |

## Platform Detection

| Variable | Description |
|----------|-------------|
| `NEUTRINO_PLATFORM_WINDOWS` | ON for Windows |
| `NEUTRINO_PLATFORM_LINUX` | ON for Linux |
| `NEUTRINO_PLATFORM_MACOS` | ON for macOS |
| `NEUTRINO_PLATFORM_IOS` | ON for iOS |
| `NEUTRINO_PLATFORM_ANDROID` | ON for Android |
| `NEUTRINO_PLATFORM_EMSCRIPTEN` | ON for WebAssembly |
| `NEUTRINO_PLATFORM_UNIX` | ON for Unix-like (Linux, macOS) |
| `NEUTRINO_PLATFORM_NAME` | Human-readable platform name |

## Architecture Detection

| Variable | Description |
|----------|-------------|
| `NEUTRINO_ARCH_X86` | ON for 32-bit x86 |
| `NEUTRINO_ARCH_X64` | ON for 64-bit x86 |
| `NEUTRINO_ARCH_ARM` | ON for 32-bit ARM |
| `NEUTRINO_ARCH_ARM64` | ON for 64-bit ARM |
| `NEUTRINO_ARCH_WASM` | ON for WebAssembly |
| `NEUTRINO_ARCH_NAME` | Human-readable architecture name |

## Build Type Detection

| Variable | Description |
|----------|-------------|
| `NEUTRINO_DEBUG_BUILD` | ON for Debug builds |
| `NEUTRINO_MULTI_CONFIG` | ON for multi-config generators (VS, Xcode) |
| `NEUTRINO_CROSS_COMPILING` | ON when cross-compiling |

## Feature Detection

| Variable | Description |
|----------|-------------|
| `NEUTRINO_LTO_SUPPORTED` | ON if LTO is available |

## Functions

### neutrino_target_compile_features

Add compile features with auto-detected visibility:

```cmake
add_library(mylib INTERFACE)
neutrino_target_compile_features(mylib cxx_std_20)
```

Uses INTERFACE for header-only libraries, PUBLIC for compiled libraries.

### neutrino_enable_lto

Enable Link Time Optimization:

```cmake
add_library(mylib src/mylib.cc)
neutrino_enable_lto(mylib)
```

Only applies if LTO is supported.

## Usage Examples

### Compiler-Specific Code

```cmake
if(NEUTRINO_COMPILER_IS_MSVC)
    target_compile_definitions(mylib PRIVATE NOMINMAX)
elseif(NEUTRINO_COMPILER_IS_GCC)
    target_compile_options(mylib PRIVATE -fvisibility=hidden)
endif()
```

### Platform-Specific Code

```cmake
if(NEUTRINO_PLATFORM_WINDOWS)
    target_link_libraries(mylib PRIVATE ws2_32)
elseif(NEUTRINO_PLATFORM_LINUX)
    target_link_libraries(mylib PRIVATE pthread)
endif()
```

### Cross-Compilation Check

```cmake
if(NEUTRINO_CROSS_COMPILING)
    message(STATUS "Cross-compiling for ${NEUTRINO_PLATFORM_NAME}")
endif()
```

## Status Output

When NeutrinoCompiler is loaded, it prints:

```
[Neutrino] Compiler: GCC 13.2.0
[Neutrino] Platform: Linux (x86_64)
```
