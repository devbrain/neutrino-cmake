# =============================================================================
# patch_cmake_minimum.cmake
# =============================================================================
# Patches cmake_minimum_required to version 3.10...3.31 for CMake 4.x compatibility.
# This script is run as PATCH_COMMAND in FetchContent_Declare.
# =============================================================================

file(READ CMakeLists.txt _content)

# Handle various cmake_minimum_required patterns:
# 1. Simple: cmake_minimum_required(VERSION 3.0)
# 2. Range: cmake_minimum_required(VERSION 3.0...3.5)
# 3. With patch version: cmake_minimum_required(VERSION 3.0.0...3.5)

string(REGEX REPLACE
    "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+(\\.[0-9]+)?(\\.\\.\\.[0-9]+\\.[0-9]+(\\.[0-9]+)?)?\\)"
    "cmake_minimum_required(VERSION 3.10...3.31)"
    _content "${_content}")
file(WRITE CMakeLists.txt "${_content}")
