# =============================================================================
# NeutrinoOptions.cmake
# =============================================================================
# Standardized option definitions for Neutrino ecosystem components.
#
# Naming convention: NEUTRINO_<COMPONENT>_<CATEGORY>_<OPTION>
#
# Categories:
#   BUILD_*     - What to build (tests, examples, docs, benchmarks)
#   ENABLE_*    - Feature toggles
#   USE_*       - Dependency selection
#   INSTALL     - Installation toggle
# =============================================================================

include_guard(GLOBAL)

include(CMakeDependentOption)

# -----------------------------------------------------------------------------
# Runtime Tools Availability
# -----------------------------------------------------------------------------

# Runtime tools (executables that run on target) are disabled for cross-compilation
set(NEUTRINO_RUNTIME_TOOLS_AVAILABLE ON)
if(NEUTRINO_CROSS_COMPILING)
    set(NEUTRINO_RUNTIME_TOOLS_AVAILABLE OFF)
endif()

# Host tools (code generators) are always available - they run on build machine
set(NEUTRINO_HOST_TOOLS_AVAILABLE ON)

# -----------------------------------------------------------------------------
# Standard Option Definitions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_define_options(<component_name>)

Define standard options for a neutrino component:
  - NEUTRINO_<COMP>_BUILD_TESTS      - Build tests (OFF when subproject)
  - NEUTRINO_<COMP>_BUILD_EXAMPLES   - Build examples (OFF when subproject)
  - NEUTRINO_<COMP>_BUILD_BENCHMARKS - Build benchmarks (OFF when subproject)
  - NEUTRINO_<COMP>_BUILD_DOCS       - Build documentation (OFF by default)
  - NEUTRINO_<COMP>_INSTALL          - Enable installation (ON when top-level)

All BUILD_* options are automatically disabled for Emscripten builds.
#]=============================================================================]
function(neutrino_define_options COMPONENT_NAME)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    # Detect if this project is top-level
    # Use CMAKE_CURRENT_SOURCE_DIR which is the directory where neutrino_define_options()
    # is called from (the consumer's CMakeLists.txt), not affected by FetchContent
    if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
        set(_is_top_level ON)
    else()
        set(_is_top_level OFF)
    endif()

    # Tests - ON only when top-level and not cross-compiling
    cmake_dependent_option(${PREFIX}_BUILD_TESTS
        "Build ${COMPONENT_NAME} tests"
        ON
        "_is_top_level;NEUTRINO_RUNTIME_TOOLS_AVAILABLE"
        OFF
    )

    # Examples - ON only when top-level and not cross-compiling
    cmake_dependent_option(${PREFIX}_BUILD_EXAMPLES
        "Build ${COMPONENT_NAME} examples"
        ON
        "_is_top_level;NEUTRINO_RUNTIME_TOOLS_AVAILABLE"
        OFF
    )

    # Benchmarks - OFF by default, requires top-level and not cross-compiling
    cmake_dependent_option(${PREFIX}_BUILD_BENCHMARKS
        "Build ${COMPONENT_NAME} benchmarks"
        OFF
        "_is_top_level;NEUTRINO_RUNTIME_TOOLS_AVAILABLE"
        OFF
    )

    # Documentation - always OFF by default
    option(${PREFIX}_BUILD_DOCS
        "Build ${COMPONENT_NAME} documentation"
        OFF
    )

    # Installation - ON when top-level
    cmake_dependent_option(${PREFIX}_INSTALL
        "Enable ${COMPONENT_NAME} installation"
        ON
        "_is_top_level"
        OFF
    )

    # Export to parent scope
    set(${PREFIX}_BUILD_TESTS ${${PREFIX}_BUILD_TESTS} PARENT_SCOPE)
    set(${PREFIX}_BUILD_EXAMPLES ${${PREFIX}_BUILD_EXAMPLES} PARENT_SCOPE)
    set(${PREFIX}_BUILD_BENCHMARKS ${${PREFIX}_BUILD_BENCHMARKS} PARENT_SCOPE)
    set(${PREFIX}_BUILD_DOCS ${${PREFIX}_BUILD_DOCS} PARENT_SCOPE)
    set(${PREFIX}_INSTALL ${${PREFIX}_INSTALL} PARENT_SCOPE)
endfunction()

#[=============================================================================[
neutrino_define_library_options(<component_name>)

Define options for a compiled (non-header-only) library.
Includes all standard options plus:
  - NEUTRINO_<COMP>_BUILD_SHARED - Build as shared library (OFF by default)
#]=============================================================================]
function(neutrino_define_library_options COMPONENT_NAME)
    # First, define standard options
    neutrino_define_options(${COMPONENT_NAME})

    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    # Shared library option - respects BUILD_SHARED_LIBS if set
    if(DEFINED BUILD_SHARED_LIBS)
        set(_default_shared ${BUILD_SHARED_LIBS})
    else()
        set(_default_shared OFF)
    endif()

    option(${PREFIX}_BUILD_SHARED
        "Build ${COMPONENT_NAME} as shared library"
        ${_default_shared}
    )

    # Export to parent scope (including the standard options)
    set(${PREFIX}_BUILD_TESTS ${${PREFIX}_BUILD_TESTS} PARENT_SCOPE)
    set(${PREFIX}_BUILD_EXAMPLES ${${PREFIX}_BUILD_EXAMPLES} PARENT_SCOPE)
    set(${PREFIX}_BUILD_BENCHMARKS ${${PREFIX}_BUILD_BENCHMARKS} PARENT_SCOPE)
    set(${PREFIX}_BUILD_DOCS ${${PREFIX}_BUILD_DOCS} PARENT_SCOPE)
    set(${PREFIX}_INSTALL ${${PREFIX}_INSTALL} PARENT_SCOPE)
    set(${PREFIX}_BUILD_SHARED ${${PREFIX}_BUILD_SHARED} PARENT_SCOPE)
endfunction()

#[=============================================================================[
neutrino_define_host_tools_option(<component_name>)

Define option for host tools (code generators that run on build machine).
These are always available, even when cross-compiling.
  - NEUTRINO_<COMP>_BUILD_HOST_TOOLS - Build host tools (ON when top-level)
#]=============================================================================]
function(neutrino_define_host_tools_option COMPONENT_NAME)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    # Detect if this project is top-level
    if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
        set(_is_top_level ON)
    else()
        set(_is_top_level OFF)
    endif()

    cmake_dependent_option(${PREFIX}_BUILD_HOST_TOOLS
        "Build ${COMPONENT_NAME} host tools (code generators)"
        ON
        "_is_top_level"
        OFF
    )

    set(${PREFIX}_BUILD_HOST_TOOLS ${${PREFIX}_BUILD_HOST_TOOLS} PARENT_SCOPE)
endfunction()

#[=============================================================================[
neutrino_define_runtime_tools_option(<component_name>)

Define option for runtime tools (executables that run on target platform).
Automatically disabled for cross-compilation.
  - NEUTRINO_<COMP>_BUILD_TOOLS - Build runtime tools
#]=============================================================================]
function(neutrino_define_runtime_tools_option COMPONENT_NAME)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    # Detect if this project is top-level
    if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
        set(_is_top_level ON)
    else()
        set(_is_top_level OFF)
    endif()

    cmake_dependent_option(${PREFIX}_BUILD_TOOLS
        "Build ${COMPONENT_NAME} tools"
        ON
        "_is_top_level;NEUTRINO_RUNTIME_TOOLS_AVAILABLE"
        OFF
    )

    set(${PREFIX}_BUILD_TOOLS ${${PREFIX}_BUILD_TOOLS} PARENT_SCOPE)
endfunction()

#[=============================================================================[
neutrino_is_top_level(<output_var>)

Check if the calling project is the top-level project.
Sets <output_var> to ON or OFF in parent scope.
#]=============================================================================]
function(neutrino_is_top_level OUTPUT_VAR)
    if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
        set(${OUTPUT_VAR} ON PARENT_SCOPE)
    else()
        set(${OUTPUT_VAR} OFF PARENT_SCOPE)
    endif()
endfunction()

#[=============================================================================[
neutrino_print_options(<component_name>)

Print the current option values for a component.
#]=============================================================================]
function(neutrino_print_options COMPONENT_NAME)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    message(STATUS "")
    message(STATUS "${COMPONENT_NAME} configuration:")

    if(DEFINED ${PREFIX}_BUILD_TESTS)
        message(STATUS "  Build tests:      ${${PREFIX}_BUILD_TESTS}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_EXAMPLES)
        message(STATUS "  Build examples:   ${${PREFIX}_BUILD_EXAMPLES}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_BENCHMARKS)
        message(STATUS "  Build benchmarks: ${${PREFIX}_BUILD_BENCHMARKS}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_DOCS)
        message(STATUS "  Build docs:       ${${PREFIX}_BUILD_DOCS}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_SHARED)
        message(STATUS "  Build shared:     ${${PREFIX}_BUILD_SHARED}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_HOST_TOOLS)
        message(STATUS "  Build host tools: ${${PREFIX}_BUILD_HOST_TOOLS}")
    endif()
    if(DEFINED ${PREFIX}_BUILD_TOOLS)
        message(STATUS "  Build tools:      ${${PREFIX}_BUILD_TOOLS}")
    endif()
    if(DEFINED ${PREFIX}_INSTALL)
        message(STATUS "  Install:          ${${PREFIX}_INSTALL}")
    endif()

    message(STATUS "")
endfunction()

#[=============================================================================[
neutrino_library_type(<component_name> <output_var>)

Returns SHARED or STATIC based on the component's BUILD_SHARED option.
#]=============================================================================]
function(neutrino_library_type COMPONENT_NAME OUTPUT_VAR)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")
    set(PREFIX "NEUTRINO_${COMP_UPPER}")

    if(${PREFIX}_BUILD_SHARED)
        set(${OUTPUT_VAR} SHARED PARENT_SCOPE)
    else()
        set(${OUTPUT_VAR} STATIC PARENT_SCOPE)
    endif()
endfunction()
