# =============================================================================
# libiff.cmake - IFF file format library
# =============================================================================
# Target: neutrino::iff
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_LIBIFF_VERSION "master" CACHE STRING "libiff version/tag")

function(neutrino_fetch_libiff)
    if(TARGET neutrino::iff OR TARGET iff::iff)
        message(STATUS "[Neutrino] libiff already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching libiff...")

    include(FetchContent)

    FetchContent_Declare(libiff
        GIT_REPOSITORY https://github.com/devbrain/libiff.git
        GIT_TAG ${NEUTRINO_LIBIFF_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable libiff tests when used as dependency
    set(NEUTRINO_IFF_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_IFF_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(libiff)

    # Create neutrino:: alias if not already created
    if(TARGET iff AND NOT TARGET neutrino::iff)
        add_library(neutrino::iff ALIAS iff)
    endif()
endfunction()
