# =============================================================================
# mio.cmake - Memory-mapped I/O library
# =============================================================================
# Target: neutrino::mio
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_MIO_VERSION "master" CACHE STRING "mio version/tag")

function(neutrino_fetch_mio)
    if(TARGET neutrino::mio OR TARGET mio::mio)
        message(STATUS "[Neutrino] mio already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching mio...")

    include(FetchContent)

    FetchContent_Declare(mio
        GIT_REPOSITORY https://github.com/devbrain/mio.git
        GIT_TAG ${NEUTRINO_MIO_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable mio tests when used as dependency
    set(NEUTRINO_MIO_BUILD_TESTS OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(mio)

    # Create neutrino:: alias if not already created
    if(TARGET mio AND NOT TARGET neutrino::mio)
        add_library(neutrino::mio ALIAS mio)
    endif()
endfunction()
