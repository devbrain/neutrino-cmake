# =============================================================================
# NeutrinoOptions.cmake
# =============================================================================
# Standardized option definitions for Neutrino ecosystem components.
#
# Naming convention: NEUTRINO_<COMPONENT>_<CATEGORY>_<OPTION>
#
# Categories:
#   BUILD_*         - What to build (tests, examples, docs, benchmarks, shared)
#   ENABLE_*        - Feature toggles
#   USE_*           - Dependency selection
#   CODEC_*         - Codec selection (image / audio / animation codec families)
#   FORMAT_*        - Format-parser selection (e.g. mzexplode's PE/NE/MZ readers)
#   DECOMPRESSOR_*  - Decompressor selection (e.g. mzexplode's LZEXE/PKLITE)
#   INSTALL         - Installation toggle
#
# The CODEC/FORMAT/DECOMPRESSOR categories are used by component libraries
# (onyx_image, onyx_anim, musac, mz-explode) to let downstream consumers
# opt out of features they don't need, shrinking the linked binary.
#
# These categories follow a meta-flag pattern: each category exposes an
# `_ALL` variant that controls the default of every individual member.
# Consumers can bulk-disable then opt-in:
#
#   set(NEUTRINO_ONYX_IMAGE_CODEC_ALL OFF CACHE BOOL "" FORCE)
#   set(NEUTRINO_ONYX_IMAGE_CODEC_LBM ON  CACHE BOOL "" FORCE)
#   set(NEUTRINO_ONYX_IMAGE_CODEC_PCX ON  CACHE BOOL "" FORCE)
#
# Implementation lives in the `neutrino_option_group` / `neutrino_option`
# helpers below — see those docstrings for the API.
# =============================================================================

include_guard(GLOBAL)

include(CMakeDependentOption)

# -----------------------------------------------------------------------------
# Runtime Tools Availability
# -----------------------------------------------------------------------------

# Runtime tools (executables that run on target) are disabled for cross-compilation
# Use CACHE INTERNAL to make available across FetchContent boundaries
if(NOT DEFINED CACHE{NEUTRINO_RUNTIME_TOOLS_AVAILABLE})
    if(NEUTRINO_CROSS_COMPILING)
        set(NEUTRINO_RUNTIME_TOOLS_AVAILABLE OFF CACHE INTERNAL "Runtime tools available")
    else()
        set(NEUTRINO_RUNTIME_TOOLS_AVAILABLE ON CACHE INTERNAL "Runtime tools available")
    endif()
endif()

# Host tools (code generators) are always available - they run on build machine
if(NOT DEFINED CACHE{NEUTRINO_HOST_TOOLS_AVAILABLE})
    set(NEUTRINO_HOST_TOOLS_AVAILABLE ON CACHE INTERNAL "Host tools available")
endif()

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

# =============================================================================
# Generic option registration + summary system
# =============================================================================
#
# Adds the meta-flag-group pattern (CODEC/FORMAT/DECOMPRESSOR families) and
# a per-component summary printer that picks up every option declared via
# the new helpers — no need to hardcode each new flag in a printer.
#
# State is kept in GLOBAL properties keyed by component name:
#   NEUTRINO_OPTIONS_<COMP>           — list of option var names
#   NEUTRINO_OPTION_DESC_<VAR>        — description string
#   NEUTRINO_OPTION_GROUP_<VAR>       — group var name (or empty)
#   NEUTRINO_OPTION_DEFAULT_<VAR>     — original default (for diagnostics)
#   NEUTRINO_COMPONENTS               — list of registered component names
#
# These are configure-time only; they reset on each cmake reconfigure.
# =============================================================================

#[=============================================================================[
neutrino_option_group(<group_var> <description> <default>)

Declare a meta-flag that controls the default value of dependent options.
Creates a CACHE BOOL variable that consumers can set to bulk-enable or
bulk-disable a whole category.

Example:
    neutrino_option_group(NEUTRINO_ONYX_IMAGE_CODEC_ALL
        "Default state for all onyx_image codec selectors"
        ON)
    neutrino_option(NEUTRINO_ONYX_IMAGE_CODEC_LBM
        "Enable LBM (IFF) decoder"
        ${NEUTRINO_ONYX_IMAGE_CODEC_ALL}
        GROUP NEUTRINO_ONYX_IMAGE_CODEC_ALL)

A consumer can then bulk-disable + opt-in:
    set(NEUTRINO_ONYX_IMAGE_CODEC_ALL OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_ONYX_IMAGE_CODEC_LBM ON  CACHE BOOL "" FORCE)
#]=============================================================================]
function(neutrino_option_group GROUP_VAR DESCRIPTION DEFAULT)
    if(NOT GROUP_VAR MATCHES "^NEUTRINO_")
        message(FATAL_ERROR
            "neutrino_option_group: '${GROUP_VAR}' must start with NEUTRINO_")
    endif()
    if(NOT DEFAULT MATCHES "^(ON|OFF)$")
        message(FATAL_ERROR
            "neutrino_option_group: DEFAULT must be ON or OFF, got '${DEFAULT}'")
    endif()

    # Plain CACHE BOOL — consumers set via -D or set(... CACHE BOOL "" FORCE).
    # No registration needed; the printer derives group state by reading
    # whichever GROUP each option declares.
    set(${GROUP_VAR} ${DEFAULT} CACHE BOOL "${DESCRIPTION}")
endfunction()

#[=============================================================================[
neutrino_option(<var_name> <description> <default> [GROUP <group_var>])

Declare a single option, registering it for the per-component summary
printer (neutrino_print_summary).

The var name must follow the NEUTRINO_<COMP>_<CATEGORY>_<NAME> convention.
The component name is extracted from positions 2..(N-2) of the underscore
split, so any name shape works as long as the NEUTRINO_ prefix is present.

If GROUP is given, the option's effective default is the *current value*
of that group variable — not the literal <default>. This makes meta-flag
bulk-set/individual-override behavior work:

    set(NEUTRINO_X_CODEC_ALL OFF CACHE BOOL "" FORCE)   # parent script
    neutrino_option_group(NEUTRINO_X_CODEC_ALL "..." ON) # in component
    neutrino_option(NEUTRINO_X_CODEC_LBM "..." ON
                    GROUP NEUTRINO_X_CODEC_ALL)
    # → NEUTRINO_X_CODEC_LBM defaults to OFF (the parent's group value),
    #   regardless of the literal `ON` written in this declaration.

The literal default is still useful as documentation of "the upstream
recommendation" — it shows up in `neutrino_print_summary` annotations
when the actual value differs.
#]=============================================================================]
function(neutrino_option VAR_NAME DESCRIPTION DEFAULT)
    cmake_parse_arguments(_NO "" "GROUP" "" ${ARGN})

    if(NOT VAR_NAME MATCHES "^NEUTRINO_([A-Z0-9_]+)$")
        message(FATAL_ERROR
            "neutrino_option: '${VAR_NAME}' must match NEUTRINO_<COMP>_<CATEGORY>_<NAME>")
    endif()
    if(NOT DEFAULT MATCHES "^(ON|OFF)$")
        message(FATAL_ERROR
            "neutrino_option: DEFAULT for '${VAR_NAME}' must be ON or OFF, got '${DEFAULT}'")
    endif()

    # Effective default: group value (if grouped) else literal default.
    set(_effective_default "${DEFAULT}")
    if(_NO_GROUP)
        if(NOT DEFINED ${_NO_GROUP})
            message(FATAL_ERROR
                "neutrino_option: GROUP '${_NO_GROUP}' for '${VAR_NAME}' "
                "is not defined. Call neutrino_option_group(...) before "
                "any option that references it.")
        endif()
        if(${_NO_GROUP})
            set(_effective_default ON)
        else()
            set(_effective_default OFF)
        endif()
    endif()

    # Declare the cache var (no-op if user already set it via -D / FORCE).
    set(${VAR_NAME} ${_effective_default} CACHE BOOL "${DESCRIPTION}")

    # Extract component name + category by splitting around the first
    # known-category token in the name. Each known category is matched
    # as a complete underscore-delimited segment of the var name.
    #
    # We can't simply assume single-token NAME (parts[-1]) because
    # codec axes like AMIGA_ANIM / ATARI_SEQ contain underscores
    # themselves. Likewise we can't assume single-token COMP, because
    # some components are multi-word (ONYX_ANIM, ONYX_IMAGE, ...).
    #
    # The category enumerates the legal grouping verbs documented in
    # this file's header. Order matters for the regex match: longer
    # categories first so e.g. DECOMPRESSOR matches before any prefix.
    set(_known_categories
        DECOMPRESSOR BUILD ENABLE USE INSTALL CODEC FORMAT)

    string(REGEX REPLACE "^NEUTRINO_" "" _stripped "${VAR_NAME}")
    set(_comp_name "")
    set(_matched_category "")
    foreach(_cat IN LISTS _known_categories)
        # _COMP1_COMP2_..._CAT_NAME1_NAME2_...  — anchor on _CAT_.
        if(_stripped MATCHES "^([A-Z0-9_]+)_${_cat}_[A-Z0-9_]+$")
            set(_comp_name "${CMAKE_MATCH_1}")
            set(_matched_category "${_cat}")
            break()
        endif()
    endforeach()

    if(NOT _matched_category)
        message(FATAL_ERROR
            "neutrino_option: '${VAR_NAME}' does not contain a known "
            "category token (BUILD/ENABLE/USE/CODEC/FORMAT/DECOMPRESSOR/INSTALL). "
            "See NeutrinoOptions.cmake header for the naming convention.")
    endif()

    # Register globally for the summary printer.
    set_property(GLOBAL APPEND PROPERTY NEUTRINO_OPTIONS_${_comp_name} "${VAR_NAME}")
    set_property(GLOBAL PROPERTY NEUTRINO_OPTION_DESC_${VAR_NAME} "${DESCRIPTION}")
    set_property(GLOBAL PROPERTY NEUTRINO_OPTION_GROUP_${VAR_NAME} "${_NO_GROUP}")
    set_property(GLOBAL PROPERTY NEUTRINO_OPTION_DEFAULT_${VAR_NAME} "${DEFAULT}")

    # Add the component to the registry if not already there.
    get_property(_components GLOBAL PROPERTY NEUTRINO_COMPONENTS)
    if(NOT _comp_name IN_LIST _components)
        set_property(GLOBAL APPEND PROPERTY NEUTRINO_COMPONENTS "${_comp_name}")
    endif()
endfunction()

#[=============================================================================[
neutrino_print_summary(<component_name>)

Print every option registered for <component_name> via neutrino_option,
grouped by category (BUILD/ENABLE/USE/CODEC/FORMAT/DECOMPRESSOR/...). For
codec-like categories with many members, members are condensed into a
single ON/OFF list rather than one line per option.

Designed to coexist with the legacy neutrino_print_options (which prints
the hardcoded set of standard options). Calling both is fine — they
cover disjoint axes.
#]=============================================================================]
function(neutrino_print_summary COMPONENT_NAME)
    string(TOUPPER "${COMPONENT_NAME}" COMP_UPPER)
    string(REPLACE "-" "_" COMP_UPPER "${COMP_UPPER}")

    get_property(_opts GLOBAL PROPERTY NEUTRINO_OPTIONS_${COMP_UPPER})
    if(NOT _opts)
        return()
    endif()

    # Bucket options by category. Category is matched against the
    # known-category list rather than positionally — codec NAMEs like
    # ATARI_SEQ / AMIGA_ANIM contain underscores and would otherwise
    # confuse a positional parse (ATARI would be misread as the
    # category).
    set(_known_categories
        DECOMPRESSOR BUILD ENABLE USE INSTALL CODEC FORMAT)
    set(_categories "")
    foreach(_opt ${_opts})
        string(REGEX REPLACE "^NEUTRINO_${COMP_UPPER}_" "" _suffix "${_opt}")
        set(_matched "")
        foreach(_cat IN LISTS _known_categories)
            if(_suffix MATCHES "^${_cat}_[A-Z0-9_]+$")
                set(_matched "${_cat}")
                break()
            endif()
        endforeach()
        if(NOT _matched)
            # Fall back so we never lose an option from the summary.
            set(_matched "MISC")
        endif()
        list(APPEND _cat_${_matched}_opts "${_opt}")
        if(NOT _matched IN_LIST _categories)
            list(APPEND _categories ${_matched})
        endif()
    endforeach()

    message(STATUS "")
    message(STATUS "─── neutrino:${COMPONENT_NAME} ─────────────────────────────")

    # Order categories: standard ones first, then everything else.
    set(_ordered_cats BUILD USE ENABLE CODEC FORMAT DECOMPRESSOR)
    set(_seen_cats "")
    foreach(_cat ${_ordered_cats})
        if(_cat IN_LIST _categories)
            _neutrino_print_category("${COMPONENT_NAME}" "${_cat}" "${_cat_${_cat}_opts}")
            list(APPEND _seen_cats ${_cat})
        endif()
    endforeach()
    foreach(_cat ${_categories})
        if(NOT _cat IN_LIST _seen_cats)
            _neutrino_print_category("${COMPONENT_NAME}" "${_cat}" "${_cat_${_cat}_opts}")
        endif()
    endforeach()

    message(STATUS "─────────────────────────────────────────────────────────────")
    message(STATUS "")
endfunction()

# Internal: print one category block. "Bulk" categories (CODEC, FORMAT,
# DECOMPRESSOR) get a compact ON/OFF roster; others get one line per
# option with the description.
function(_neutrino_print_category COMPONENT_NAME CATEGORY OPTS)
    list(LENGTH OPTS _n)

    # Pick the right format: bulk-categories print roster, others verbose.
    set(_bulk_categories CODEC FORMAT DECOMPRESSOR)
    if(CATEGORY IN_LIST _bulk_categories)
        # Roster mode: ON: ...  OFF: ...
        set(_on_names "")
        set(_off_names "")
        set(_on_count 0)
        foreach(_opt ${OPTS})
            string(REGEX REPLACE ".*_${CATEGORY}_" "" _short "${_opt}")
            if(${${_opt}})
                list(APPEND _on_names "${_short}")
                math(EXPR _on_count "${_on_count} + 1")
            else()
                list(APPEND _off_names "${_short}")
            endif()
        endforeach()
        message(STATUS "  ${CATEGORY}S (${_on_count}/${_n} on):")
        if(_on_names)
            string(REPLACE ";" " " _on_str "${_on_names}")
            message(STATUS "    ON:  ${_on_str}")
        endif()
        if(_off_names)
            string(REPLACE ";" " " _off_str "${_off_names}")
            message(STATUS "    OFF: ${_off_str}")
        endif()
    else()
        # Verbose mode: one line per option.
        foreach(_opt ${OPTS})
            string(REGEX REPLACE "^NEUTRINO_[A-Z0-9_]+_${CATEGORY}_" "" _short "${_opt}")
            if(${${_opt}})
                set(_val "ON")
            else()
                set(_val "OFF")
            endif()
            message(STATUS "  ${CATEGORY}_${_short}: ${_val}")
        endforeach()
    endif()
endfunction()
