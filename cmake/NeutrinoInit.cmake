# =============================================================================
# NeutrinoInit.cmake
# =============================================================================
# Entry point for the Neutrino CMake ecosystem.
#
# Include this module once at the start of your CMakeLists.txt to get access
# to all Neutrino CMake functionality.
#
# Usage:
#     include(FetchContent)
#
#     FetchContent_Declare(neutrino_cmake
#         GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
#         GIT_TAG master
#     )
#     FetchContent_MakeAvailable(neutrino_cmake)
#
#     list(APPEND CMAKE_MODULE_PATH "${neutrino_cmake_SOURCE_DIR}/cmake")
#     include(NeutrinoInit)
#
# Or if neutrino-cmake is installed:
#     list(APPEND CMAKE_MODULE_PATH "/path/to/neutrino-cmake/cmake")
#     include(NeutrinoInit)
# =============================================================================

include_guard(GLOBAL)

# Get the directory containing this file
get_filename_component(NEUTRINO_CMAKE_DIR "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

# Store for use by dependency recipes
set(NEUTRINO_CMAKE_DIR "${NEUTRINO_CMAKE_DIR}" CACHE INTERNAL
    "Path to neutrino-cmake modules"
)

# Version of neutrino-cmake
set(NEUTRINO_CMAKE_VERSION "1.0.0")

# -----------------------------------------------------------------------------
# Include Core Modules
# -----------------------------------------------------------------------------

# Order matters here - some modules depend on others

# 1. Policies - must be first
include("${NEUTRINO_CMAKE_DIR}/NeutrinoPolicies.cmake")

# 2. Compiler detection - used by many other modules
include("${NEUTRINO_CMAKE_DIR}/NeutrinoCompiler.cmake")

# 3. Options - depends on compiler (for cross-compile detection)
include("${NEUTRINO_CMAKE_DIR}/NeutrinoOptions.cmake")

# 4. Warnings - depends on compiler detection
include("${NEUTRINO_CMAKE_DIR}/NeutrinoWarnings.cmake")

# 5. Sanitizers - depends on compiler detection
include("${NEUTRINO_CMAKE_DIR}/NeutrinoSanitizers.cmake")

# 6. Host tools - for cross-compilation support
include("${NEUTRINO_CMAKE_DIR}/NeutrinoHostTools.cmake")

# 7. Installation helpers
include("${NEUTRINO_CMAKE_DIR}/NeutrinoInstall.cmake")

# -----------------------------------------------------------------------------
# FetchContent Configuration
# -----------------------------------------------------------------------------

include(FetchContent)

# Make FetchContent output less verbose by default
if(NOT DEFINED FETCHCONTENT_QUIET)
    set(FETCHCONTENT_QUIET ON)
endif()

# -----------------------------------------------------------------------------
# Status Banner
# -----------------------------------------------------------------------------

message(STATUS "")
message(STATUS "=== Neutrino CMake ${NEUTRINO_CMAKE_VERSION} ===")
message(STATUS "")
