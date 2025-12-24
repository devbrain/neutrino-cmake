# =============================================================================
# NeutrinoCompiler.cmake
# =============================================================================
# Compiler detection, platform identification, and feature flags for the
# Neutrino ecosystem.
# =============================================================================

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# Compiler Identification
# -----------------------------------------------------------------------------

# Use CACHE INTERNAL to make variables available across FetchContent boundaries
if(NOT DEFINED CACHE{NEUTRINO_COMPILER_IS_MSVC})
    set(NEUTRINO_COMPILER_IS_MSVC OFF CACHE INTERNAL "")
    set(NEUTRINO_COMPILER_IS_GCC OFF CACHE INTERNAL "")
    set(NEUTRINO_COMPILER_IS_CLANG OFF CACHE INTERNAL "")
    set(NEUTRINO_COMPILER_IS_APPLECLANG OFF CACHE INTERNAL "")
    set(NEUTRINO_COMPILER_IS_INTEL OFF CACHE INTERNAL "")

    if(MSVC)
        set(NEUTRINO_COMPILER_IS_MSVC ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_NAME "MSVC" CACHE INTERNAL "")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(NEUTRINO_COMPILER_IS_GCC ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_NAME "GCC" CACHE INTERNAL "")
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
        set(NEUTRINO_COMPILER_IS_APPLECLANG ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_IS_CLANG ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_NAME "AppleClang" CACHE INTERNAL "")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(NEUTRINO_COMPILER_IS_CLANG ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_NAME "Clang" CACHE INTERNAL "")
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Intel")
        set(NEUTRINO_COMPILER_IS_INTEL ON CACHE INTERNAL "")
        set(NEUTRINO_COMPILER_NAME "Intel" CACHE INTERNAL "")
    else()
        set(NEUTRINO_COMPILER_NAME "${CMAKE_CXX_COMPILER_ID}" CACHE INTERNAL "")
    endif()

    # Compiler version
    set(NEUTRINO_COMPILER_VERSION "${CMAKE_CXX_COMPILER_VERSION}" CACHE INTERNAL "")
endif()

# -----------------------------------------------------------------------------
# Platform Identification
# -----------------------------------------------------------------------------

set(NEUTRINO_PLATFORM_WINDOWS OFF)
set(NEUTRINO_PLATFORM_LINUX OFF)
set(NEUTRINO_PLATFORM_MACOS OFF)
set(NEUTRINO_PLATFORM_IOS OFF)
set(NEUTRINO_PLATFORM_ANDROID OFF)
set(NEUTRINO_PLATFORM_EMSCRIPTEN OFF)
set(NEUTRINO_PLATFORM_UNIX OFF)

if(EMSCRIPTEN)
    set(NEUTRINO_PLATFORM_EMSCRIPTEN ON)
    set(NEUTRINO_PLATFORM_NAME "Emscripten")
elseif(WIN32)
    set(NEUTRINO_PLATFORM_WINDOWS ON)
    set(NEUTRINO_PLATFORM_NAME "Windows")
elseif(APPLE)
    if(IOS)
        set(NEUTRINO_PLATFORM_IOS ON)
        set(NEUTRINO_PLATFORM_NAME "iOS")
    else()
        set(NEUTRINO_PLATFORM_MACOS ON)
        set(NEUTRINO_PLATFORM_NAME "macOS")
    endif()
elseif(ANDROID)
    set(NEUTRINO_PLATFORM_ANDROID ON)
    set(NEUTRINO_PLATFORM_NAME "Android")
elseif(UNIX)
    set(NEUTRINO_PLATFORM_LINUX ON)
    set(NEUTRINO_PLATFORM_UNIX ON)
    set(NEUTRINO_PLATFORM_NAME "Linux")
else()
    set(NEUTRINO_PLATFORM_NAME "Unknown")
endif()

# Unix-like platforms (Linux, macOS, but not Emscripten for some purposes)
if(UNIX AND NOT EMSCRIPTEN)
    set(NEUTRINO_PLATFORM_UNIX ON)
endif()

# Cross-compilation detection
set(NEUTRINO_CROSS_COMPILING OFF)
if(CMAKE_CROSSCOMPILING OR NEUTRINO_PLATFORM_EMSCRIPTEN OR NEUTRINO_PLATFORM_ANDROID OR NEUTRINO_PLATFORM_IOS)
    set(NEUTRINO_CROSS_COMPILING ON)
endif()

# -----------------------------------------------------------------------------
# Architecture Detection
# -----------------------------------------------------------------------------

set(NEUTRINO_ARCH_X86 OFF)
set(NEUTRINO_ARCH_X64 OFF)
set(NEUTRINO_ARCH_ARM OFF)
set(NEUTRINO_ARCH_ARM64 OFF)
set(NEUTRINO_ARCH_WASM OFF)

if(NEUTRINO_PLATFORM_EMSCRIPTEN)
    set(NEUTRINO_ARCH_WASM ON)
    set(NEUTRINO_ARCH_NAME "WebAssembly")
elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|ARM64|arm64")
        set(NEUTRINO_ARCH_ARM64 ON)
        set(NEUTRINO_ARCH_NAME "ARM64")
    else()
        set(NEUTRINO_ARCH_X64 ON)
        set(NEUTRINO_ARCH_NAME "x86_64")
    endif()
elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm|ARM")
        set(NEUTRINO_ARCH_ARM ON)
        set(NEUTRINO_ARCH_NAME "ARM")
    else()
        set(NEUTRINO_ARCH_X86 ON)
        set(NEUTRINO_ARCH_NAME "x86")
    endif()
else()
    set(NEUTRINO_ARCH_NAME "Unknown")
endif()

# -----------------------------------------------------------------------------
# Build Type Helpers
# -----------------------------------------------------------------------------

# Detect if this is a debug build
set(NEUTRINO_DEBUG_BUILD OFF)
if(CMAKE_BUILD_TYPE MATCHES "Debug" OR CMAKE_BUILD_TYPE STREQUAL "")
    set(NEUTRINO_DEBUG_BUILD ON)
endif()

# Multi-config generator detection (Visual Studio, Ninja Multi-Config, Xcode)
set(NEUTRINO_MULTI_CONFIG OFF)
get_property(_is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(_is_multi_config)
    set(NEUTRINO_MULTI_CONFIG ON)
endif()
unset(_is_multi_config)

# -----------------------------------------------------------------------------
# Compiler Feature Detection
# -----------------------------------------------------------------------------

# Check for specific compiler features we might need
include(CheckCXXCompilerFlag)

# LTO (Link Time Optimization) support
set(NEUTRINO_LTO_SUPPORTED OFF)
if(NOT NEUTRINO_PLATFORM_EMSCRIPTEN)
    include(CheckIPOSupported OPTIONAL RESULT_VARIABLE _ipo_module_found)
    if(_ipo_module_found)
        check_ipo_supported(RESULT NEUTRINO_LTO_SUPPORTED LANGUAGES CXX)
    endif()
    unset(_ipo_module_found)
endif()

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_target_compile_features(<target> <feature>...)

Add compile features to a target with appropriate visibility based on
target type (INTERFACE for header-only, PRIVATE for compiled).
#]=============================================================================]
function(neutrino_target_compile_features TARGET)
    get_target_property(_type ${TARGET} TYPE)
    if(_type STREQUAL "INTERFACE_LIBRARY")
        target_compile_features(${TARGET} INTERFACE ${ARGN})
    else()
        target_compile_features(${TARGET} PUBLIC ${ARGN})
    endif()
endfunction()

#[=============================================================================[
neutrino_enable_lto(<target>)

Enable Link Time Optimization for a target if supported.
#]=============================================================================]
function(neutrino_enable_lto TARGET)
    if(NEUTRINO_LTO_SUPPORTED)
        set_target_properties(${TARGET} PROPERTIES
            INTERPROCEDURAL_OPTIMIZATION ON
        )
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Status Output
# -----------------------------------------------------------------------------

message(STATUS "[Neutrino] Compiler: ${NEUTRINO_COMPILER_NAME} ${NEUTRINO_COMPILER_VERSION}")
message(STATUS "[Neutrino] Platform: ${NEUTRINO_PLATFORM_NAME} (${NEUTRINO_ARCH_NAME})")
if(NEUTRINO_CROSS_COMPILING)
    message(STATUS "[Neutrino] Cross-compiling: YES")
endif()
