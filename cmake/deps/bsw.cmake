# =============================================================================
# bsw.cmake - C++ utility library
# =============================================================================
# Target: bsw::bsw
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_BSW_VERSION "master" CACHE STRING "bsw version/tag")

function(neutrino_fetch_bsw)
    if(TARGET bsw::bsw OR TARGET bsw)
        message(STATUS "[Neutrino] bsw already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching bsw...")

    include(FetchContent)

    FetchContent_Declare(bsw
        GIT_REPOSITORY https://github.com/devbrain/lib_bsw.git
        GIT_TAG ${NEUTRINO_BSW_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable bsw tests when used as dependency
    set(NEUTRINO_BSW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_BSW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    # Disable warnings for dependency build
    set(NEUTRINO_WARNINGS_AS_ERRORS OFF)

    FetchContent_MakeAvailable(bsw)

    # Suppress warnings for bsw (third-party code)
    if(TARGET bsw)
        neutrino_suppress_warnings(bsw)
    endif()

    # Create bsw::bsw alias if not already created
    if(TARGET bsw AND NOT TARGET bsw::bsw)
        add_library(bsw::bsw ALIAS bsw)
    endif()
endfunction()
