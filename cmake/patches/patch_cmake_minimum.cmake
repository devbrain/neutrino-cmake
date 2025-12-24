# =============================================================================
# patch_cmake_minimum.cmake
# =============================================================================
# Patches cmake_minimum_required to version 3.5 for CMake 4.x compatibility.
# This script is run as PATCH_COMMAND in FetchContent_Declare.
# =============================================================================

file(READ CMakeLists.txt _content)
string(REGEX REPLACE
    "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+(\\.[0-9]+)?\\)"
    "cmake_minimum_required(VERSION 3.5)"
    _content "${_content}")
file(WRITE CMakeLists.txt "${_content}")
