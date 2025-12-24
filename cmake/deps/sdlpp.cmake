# =============================================================================
# sdlpp.cmake - C++ SDL3 wrapper library
# =============================================================================
# Target: neutrino::sdlpp
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_SDLPP_VERSION "main" CACHE STRING "lib_sdlpp version/tag")

function(neutrino_fetch_sdlpp)
    if(TARGET neutrino::sdlpp OR TARGET sdlpp::sdlpp)
        message(STATUS "[Neutrino] sdlpp already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching lib_sdlpp...")

    include(FetchContent)

    FetchContent_Declare(sdlpp
        GIT_REPOSITORY https://github.com/devbrain/lib_sdlpp.git
        GIT_TAG ${NEUTRINO_SDLPP_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable sdlpp tests and examples when used as dependency
    set(NEUTRINO_SDLPP_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_SDLPP_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(sdlpp)

    # Create neutrino:: alias if not already created
    if(TARGET sdlpp AND NOT TARGET neutrino::sdlpp)
        add_library(neutrino::sdlpp ALIAS sdlpp)
    endif()
endfunction()
