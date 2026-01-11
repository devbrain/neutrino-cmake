# =============================================================================
# musac.cmake - Music/Audio library
# =============================================================================
# Target: neutrino::musac
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_MUSAC_VERSION "master" CACHE STRING "musac version/tag")

function(neutrino_fetch_musac)
    if(TARGET neutrino::musac OR TARGET musac)
        message(STATUS "[Neutrino] musac already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching musac...")

    include(FetchContent)

    FetchContent_Declare(musac
        GIT_REPOSITORY https://github.com/devbrain/musac.git
        GIT_TAG ${NEUTRINO_MUSAC_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable musac tests and examples when used as dependency
    set(NEUTRINO_MUSAC_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_MUSAC_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    # Use SDL3 backend by default, disable SDL2
    set(MUSAC_USE_SDL3 ON CACHE BOOL "" FORCE)
    set(MUSAC_USE_SDL2 OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(musac)

    # Create neutrino:: alias if not already created
    if(TARGET musac AND NOT TARGET neutrino::musac)
        add_library(neutrino::musac ALIAS musac)
    endif()

    # Suppress warnings for musac headers
    if(TARGET musac)
        neutrino_suppress_warnings(musac)
    endif()
endfunction()
