# =============================================================================
# NeutrinoWarnings.cmake
# =============================================================================
# Strict compiler warning flags for the Neutrino ecosystem.
# Provides consistent, high-quality warning configurations across
# MSVC, GCC, and Clang compilers.
# =============================================================================

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# Global Warning Option
# -----------------------------------------------------------------------------

option(NEUTRINO_WARNINGS_AS_ERRORS
    "Treat compiler warnings as errors"
    ON
)

# -----------------------------------------------------------------------------
# Warning Flag Definitions
# -----------------------------------------------------------------------------

# MSVC warnings
set(NEUTRINO_WARNINGS_MSVC
    /W4                 # Warning level 4 (very strict)
    /permissive-        # Strict standards conformance
    /w14242             # 'identifier': conversion, possible loss of data
    /w14254             # 'operator': conversion, possible loss of data
    /w14263             # Member function does not override base class virtual
    /w14265             # Class has virtual functions, but destructor is not virtual
    /w14287             # 'operator': unsigned/negative constant mismatch
    /we4289             # Nonstandard extension: loop control variable used outside loop
    /w14296             # 'operator': expression is always 'boolean_value'
    /w14311             # 'variable': pointer truncation
    /w14545             # Expression before comma evaluates to function missing argument list
    /w14546             # Function call before comma missing argument list
    /w14547             # 'operator': operator before comma has no effect
    /w14549             # 'operator': operator before comma has no effect
    /w14555             # Expression has no effect
    /w14619             # Pragma warning: no warning number 'number'
    /w14640             # Thread unsafe static member initialization
    /w14826             # Conversion is sign-extended
    /w14905             # Wide string literal cast to 'LPSTR'
    /w14906             # String literal cast to 'LPWSTR'
    /w14928             # Illegal copy-initialization
    /wd4251             # Disable DLL interface warning for STL types
)

# Add /WX if warnings as errors is enabled
if(NEUTRINO_WARNINGS_AS_ERRORS)
    list(APPEND NEUTRINO_WARNINGS_MSVC /WX)
endif()

# GCC and Clang common warnings
set(NEUTRINO_WARNINGS_GNU_CLANG
    -Wall                       # Enable most warnings
    -Wextra                     # Enable extra warnings
    -Wpedantic                  # Strict ISO C++ compliance
    -Wshadow                    # Warn when variable shadows another
    -Wnon-virtual-dtor          # Non-virtual destructor in class with virtual functions
    -Wold-style-cast            # Warn on C-style casts
    -Wcast-align                # Potential alignment issues
    -Wunused                    # Unused entities
    -Woverloaded-virtual        # Function hides virtual from base class
    -Wconversion                # Implicit conversions that may alter value
    -Wsign-conversion           # Sign conversions
    # -Wnull-dereference - Disabled: generates false positives with GCC 13+ STL code
    -Wdouble-promotion          # Float implicitly promoted to double
    -Wformat=2                  # Format string issues
    -Wimplicit-fallthrough      # Fallthrough in switch without annotation
    -Wmisleading-indentation    # Indentation implies blocks that don't exist
)

# Add -Werror if warnings as errors is enabled
if(NEUTRINO_WARNINGS_AS_ERRORS)
    list(APPEND NEUTRINO_WARNINGS_GNU_CLANG -Werror)
endif()

# GCC-specific warnings
set(NEUTRINO_WARNINGS_GCC
    ${NEUTRINO_WARNINGS_GNU_CLANG}
    -Wduplicated-cond           # Duplicated conditions in if-else chains
    -Wduplicated-branches       # Duplicated branches in if-else chains
    -Wlogical-op                # Suspicious uses of logical operators
    -Wuseless-cast              # Useless casts
    -Wsuggest-override          # Suggest override for virtual functions
)

# Clang-specific warnings
set(NEUTRINO_WARNINGS_CLANG
    ${NEUTRINO_WARNINGS_GNU_CLANG}
    -Wmost                      # Enable most warnings
    -Wno-c++98-compat           # Don't warn about C++98 incompatibility
    -Wno-c++98-compat-pedantic  # Don't warn about C++98 incompatibility (pedantic)
)

# Clang with thread safety analysis
set(NEUTRINO_WARNINGS_CLANG_THREAD_SAFETY
    -Wthread-safety             # Thread safety analysis
)

# -----------------------------------------------------------------------------
# Warning Application Functions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_target_warnings(<target> [PRIVATE|PUBLIC|INTERFACE])

Apply standard Neutrino warning flags to a target.
Visibility defaults to PRIVATE for compiled libraries, INTERFACE for header-only.
#]=============================================================================]
function(neutrino_target_warnings TARGET)
    # Parse visibility argument
    set(_visibility "")
    if(ARGC GREATER 1)
        set(_visibility ${ARGV1})
    endif()

    # Auto-detect visibility if not specified
    if(NOT _visibility)
        get_target_property(_type ${TARGET} TYPE)
        if(_type STREQUAL "INTERFACE_LIBRARY")
            set(_visibility INTERFACE)
        else()
            set(_visibility PRIVATE)
        endif()
    endif()

    # Apply compiler-specific warnings
    if(NEUTRINO_COMPILER_IS_MSVC)
        target_compile_options(${TARGET} ${_visibility} ${NEUTRINO_WARNINGS_MSVC})
    elseif(NEUTRINO_COMPILER_IS_GCC)
        target_compile_options(${TARGET} ${_visibility} ${NEUTRINO_WARNINGS_GCC})
    elseif(NEUTRINO_COMPILER_IS_CLANG)
        target_compile_options(${TARGET} ${_visibility} ${NEUTRINO_WARNINGS_CLANG})
    endif()
endfunction()

#[=============================================================================[
neutrino_target_thread_safety(<target>)

Enable Clang's thread safety analysis for a target.
Has no effect on non-Clang compilers.
#]=============================================================================]
function(neutrino_target_thread_safety TARGET)
    if(NEUTRINO_COMPILER_IS_CLANG AND NOT NEUTRINO_COMPILER_IS_APPLECLANG)
        get_target_property(_type ${TARGET} TYPE)
        if(_type STREQUAL "INTERFACE_LIBRARY")
            target_compile_options(${TARGET} INTERFACE ${NEUTRINO_WARNINGS_CLANG_THREAD_SAFETY})
        else()
            target_compile_options(${TARGET} PRIVATE ${NEUTRINO_WARNINGS_CLANG_THREAD_SAFETY})
        endif()
    endif()
endfunction()

#[=============================================================================[
neutrino_suppress_warnings(<target>)

Suppress warnings for a target (useful for third-party code).
Makes the target a SYSTEM include to suppress warnings in headers.
#]=============================================================================]
function(neutrino_suppress_warnings TARGET)
    get_target_property(_type ${TARGET} TYPE)

    if(_type STREQUAL "INTERFACE_LIBRARY")
        # For interface libraries, mark include dirs as SYSTEM
        get_target_property(_includes ${TARGET} INTERFACE_INCLUDE_DIRECTORIES)
        if(_includes)
            set_target_properties(${TARGET} PROPERTIES
                INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_includes}"
            )
        endif()
    else()
        # For compiled libraries, disable warnings
        if(NEUTRINO_COMPILER_IS_MSVC)
            target_compile_options(${TARGET} PRIVATE /W0)
        else()
            target_compile_options(${TARGET} PRIVATE -w)
        endif()
    endif()
endfunction()

#[=============================================================================[
neutrino_target_disable_specific_warnings(<target> <warning>...)

Disable specific warnings for a target.

Example:
    neutrino_target_disable_specific_warnings(mylib
        4251  # MSVC: DLL interface warning
        sign-conversion  # GCC/Clang
    )
#]=============================================================================]
function(neutrino_target_disable_specific_warnings TARGET)
    foreach(_warning ${ARGN})
        if(NEUTRINO_COMPILER_IS_MSVC)
            # MSVC uses /wdXXXX format
            if(_warning MATCHES "^[0-9]+$")
                target_compile_options(${TARGET} PRIVATE /wd${_warning})
            endif()
        else()
            # GCC/Clang use -Wno-<warning> format
            if(NOT _warning MATCHES "^[0-9]+$")
                target_compile_options(${TARGET} PRIVATE -Wno-${_warning})
            endif()
        endif()
    endforeach()
endfunction()
