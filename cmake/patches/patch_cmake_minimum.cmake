# =============================================================================
# patch_cmake_minimum.cmake
# =============================================================================
# Patches cmake_minimum_required to version 3.10...3.31 for CMake 4.x compatibility.
# Run as PATCH_COMMAND in FetchContent_Declare.
#
# By default it patches the top-level CMakeLists.txt. Pass
# -DPATCH_FILE=<path-relative-to-source-dir> to patch a file elsewhere -- e.g. a
# dependency whose build system lives in a subdirectory (zstd: build/cmake).
# =============================================================================

if(NOT DEFINED PATCH_FILE)
    set(PATCH_FILE "CMakeLists.txt")
endif()

file(READ "${PATCH_FILE}" _content)

# Handle the cmake_minimum_required patterns:
# 1. Simple:             cmake_minimum_required(VERSION 3.0)
# 2. Range:              cmake_minimum_required(VERSION 3.0...3.5)
# 3. With patch version: cmake_minimum_required(VERSION 3.0.0...3.5)
# 4. With FATAL_ERROR:   cmake_minimum_required(VERSION 3.5 FATAL_ERROR)
# The optional " FATAL_ERROR" is dropped -- redundant once a version range is given.

string(REGEX REPLACE
    "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+(\\.[0-9]+)?(\\.\\.\\.[0-9]+\\.[0-9]+(\\.[0-9]+)?)?( +FATAL_ERROR)?\\)"
    "cmake_minimum_required(VERSION 3.10...3.31)"
    _content "${_content}")
file(WRITE "${PATCH_FILE}" "${_content}")
