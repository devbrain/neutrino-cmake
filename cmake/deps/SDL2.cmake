# =============================================================================
# SDL2.cmake - Simple DirectMedia Layer 2
# =============================================================================
# Target: SDL2::SDL2
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_SDL2_VERSION "2.30.0" CACHE STRING "SDL2 version")

function(neutrino_fetch_SDL2)
    if(TARGET SDL2::SDL2)
        message(STATUS "[Neutrino] SDL2 already available")
        return()
    endif()

    # First try to find system SDL2
    find_package(SDL2 QUIET CONFIG)
    if(TARGET SDL2::SDL2)
        message(STATUS "[Neutrino] Using system SDL2")
        return()
    endif()

    # Fallback: find using pkg-config or Find module
    find_package(SDL2 QUIET)
    if(SDL2_FOUND)
        message(STATUS "[Neutrino] Using system SDL2 (FindSDL2)")

        # Create modern target if not available
        if(NOT TARGET SDL2::SDL2)
            add_library(SDL2::SDL2 IMPORTED INTERFACE)
            set_target_properties(SDL2::SDL2 PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${SDL2_INCLUDE_DIRS}"
                INTERFACE_LINK_LIBRARIES "${SDL2_LIBRARIES}"
            )
        endif()
        return()
    endif()

    # Fetch from source
    message(STATUS "[Neutrino] Fetching SDL2 ${NEUTRINO_SDL2_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(SDL2
        GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
        GIT_TAG release-${NEUTRINO_SDL2_VERSION}
        GIT_SHALLOW TRUE
    )

    # SDL2 build options
    set(SDL_SHARED OFF CACHE BOOL "" FORCE)
    set(SDL_STATIC ON CACHE BOOL "" FORCE)
    set(SDL_TEST OFF CACHE BOOL "" FORCE)
    set(SDL2_DISABLE_INSTALL ON CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(SDL2)

    # Create alias if needed
    if(TARGET SDL2-static AND NOT TARGET SDL2::SDL2)
        add_library(SDL2::SDL2 ALIAS SDL2-static)
    endif()
endfunction()
