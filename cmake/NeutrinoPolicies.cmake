# =============================================================================
# NeutrinoPolicies.cmake
# =============================================================================
# CMake version requirements and policy settings for the Neutrino ecosystem.
#
# This module should be included at the very beginning of each project's
# CMakeLists.txt to ensure consistent behavior across all components.
# =============================================================================

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# Minimum CMake Version
# -----------------------------------------------------------------------------
# CMake 3.20+ is required for:
#   - CMAKE_<LANG>_BYTE_ORDER
#   - Improved FetchContent performance
#   - Better presets support
#   - PROJECT_IS_TOP_LEVEL

cmake_minimum_required(VERSION 3.20)

# -----------------------------------------------------------------------------
# Policy Settings
# -----------------------------------------------------------------------------

# CMP0077: option() honors normal variables
# Allows parent projects to override child options via set() before add_subdirectory()
if(POLICY CMP0077)
    cmake_policy(SET CMP0077 NEW)
endif()

# CMP0079: target_link_libraries() allows use with targets in other directories
if(POLICY CMP0079)
    cmake_policy(SET CMP0079 NEW)
endif()

# CMP0091: MSVC runtime library flags are selected by CMAKE_MSVC_RUNTIME_LIBRARY
if(POLICY CMP0091)
    cmake_policy(SET CMP0091 NEW)
endif()

# CMP0135: ExternalProject and FetchContent download timestamp policy
# Use the extraction timestamp instead of download timestamp
if(POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW)
endif()

# CMP0144: find_package uses upper-case <PACKAGENAME>_ROOT variables
if(POLICY CMP0144)
    cmake_policy(SET CMP0144 NEW)
endif()

# -----------------------------------------------------------------------------
# C++ Standard Defaults
# -----------------------------------------------------------------------------

# Default to C++20 if not specified
if(NOT DEFINED CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 20)
endif()

# Require the C++ standard (no fallback)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Disable compiler-specific extensions for portability
set(CMAKE_CXX_EXTENSIONS OFF)

# -----------------------------------------------------------------------------
# Output Directory Defaults
# -----------------------------------------------------------------------------

# Organize outputs in standard directories
if(NOT CMAKE_RUNTIME_OUTPUT_DIRECTORY)
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()

if(NOT CMAKE_LIBRARY_OUTPUT_DIRECTORY)
    set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
endif()

if(NOT CMAKE_ARCHIVE_OUTPUT_DIRECTORY)
    set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
endif()

# -----------------------------------------------------------------------------
# Export Compile Commands
# -----------------------------------------------------------------------------

# Generate compile_commands.json for IDE/tooling support
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# -----------------------------------------------------------------------------
# Position Independent Code
# -----------------------------------------------------------------------------

# Enable PIC by default (required for shared libraries)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

message(STATUS "[Neutrino] Policies configured (CMake ${CMAKE_VERSION})")
