# =============================================================================
# SDL3.cmake - Simple DirectMedia Layer 3
# =============================================================================
# Target: SDL3::SDL3
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_SDL3_VERSION "3.1.6" CACHE STRING "SDL3 version")

function(neutrino_fetch_SDL3)
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
        GIT_TAG preview-${NEUTRINO_SDL3_VERSION}
        GIT_SHALLOW TRUE
    )

    # SDL3 build options
    set(SDL_SHARED OFF CACHE BOOL "" FORCE)
    set(SDL_STATIC ON CACHE BOOL "" FORCE)
    set(SDL_TEST OFF CACHE BOOL "" FORCE)
    set(SDL_INSTALL OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(SDL3)

    # Create alias if needed
    if(TARGET SDL3-static AND NOT TARGET SDL3::SDL3)
        add_library(SDL3::SDL3 ALIAS SDL3-static)
    endif()
endfunction()
