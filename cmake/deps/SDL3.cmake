# =============================================================================
# SDL3.cmake - Simple DirectMedia Layer 3
# =============================================================================
# Target: SDL3::SDL3
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_SDL3_VERSION "3.4.0" CACHE STRING "SDL3 version")

function(neutrino_fetch_SDL3)
    cmake_parse_arguments(NEUTRINO_SDL3 "SHARED;STATIC" "" "" ${ARGN})
    set(options SHARED STATIC)
    cmake_parse_arguments(NEUTRINO_SDL3 "" "" "${options}" ${ARGN})

    if(TARGET SDL3::SDL3)
        message(STATUS "[Neutrino] SDL3 already available")
        return()
    endif()

    # First try to find system SDL3
    find_package(SDL3 QUIET CONFIG)
    if(TARGET SDL3::SDL3)
        message(STATUS "[Neutrino] Using system SDL3")
        return()
    endif()

    # Fetch from source
    message(STATUS "[Neutrino] Fetching SDL3 ${NEUTRINO_SDL3_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(SDL3
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-${NEUTRINO_SDL3_VERSION}
        GIT_SHALLOW TRUE
    )

    # SDL3 build options
    if(NEUTRINO_SDL3_SHARED AND NEUTRINO_SDL3_STATIC)
        message(FATAL_ERROR "neutrino_fetch_SDL3: SHARED and STATIC are mutually exclusive.")
    endif()

    if(NEUTRINO_SDL3_SHARED)
        set(SDL_SHARED ON CACHE BOOL "" FORCE)
        set(SDL_STATIC OFF CACHE BOOL "" FORCE)
    else()
        # Default to static unless explicitly requested otherwise.
        set(SDL_SHARED OFF CACHE BOOL "" FORCE)
        set(SDL_STATIC ON CACHE BOOL "" FORCE)
    endif()
    set(SDL_TEST OFF CACHE BOOL "" FORCE)
    set(SDL_INSTALL OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(SDL3)

    # Create alias if needed
    if(NEUTRINO_SDL3_SHARED)
        if(TARGET SDL3-shared AND NOT TARGET SDL3::SDL3)
            add_library(SDL3::SDL3 ALIAS SDL3-shared)
        endif()
    else()
        if(TARGET SDL3-static AND NOT TARGET SDL3::SDL3)
            add_library(SDL3::SDL3 ALIAS SDL3-static)
        endif()
    endif()

    # Suppress warnings for third-party library
    if(NEUTRINO_SDL3_SHARED AND TARGET SDL3-shared)
        neutrino_suppress_warnings(SDL3-shared)
    elseif(TARGET SDL3-static)
        neutrino_suppress_warnings(SDL3-static)
    endif()
endfunction()
