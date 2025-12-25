# =============================================================================
# mz-explode.cmake - MZ executable decompression library
# =============================================================================
# Target: neutrino::mzexplode
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_MZEXPLODE_VERSION "master" CACHE STRING "mz-explode version/tag")

function(neutrino_fetch_mzexplode)
    if(TARGET neutrino::mzexplode OR TARGET mzexplode::libexe)
        message(STATUS "[Neutrino] mz-explode already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching mz-explode...")

    include(FetchContent)

    FetchContent_Declare(mzexplode
        GIT_REPOSITORY https://github.com/devbrain/mz-explode.git
        GIT_TAG ${NEUTRINO_MZEXPLODE_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable mz-explode tests and tools when used as dependency
    set(MZEXPLODE_BUILD_TESTING OFF CACHE BOOL "" FORCE)
    set(MZEXPLODE_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
    set(MZEXPLODE_BUILD_DOCS OFF CACHE BOOL "" FORCE)

    # Disable warnings for dependency build
    set(NEUTRINO_WARNINGS_AS_ERRORS OFF)

    FetchContent_MakeAvailable(mzexplode)

    # Suppress warnings for mzexplode (third-party code)
    if(TARGET libexe)
        neutrino_suppress_warnings(libexe)
    endif()

    # Create neutrino:: alias if not already created
    if(TARGET libexe AND NOT TARGET neutrino::mzexplode)
        add_library(neutrino::mzexplode ALIAS libexe)
    elseif(TARGET mzexplode::libexe AND NOT TARGET neutrino::mzexplode)
        add_library(neutrino::mzexplode ALIAS mzexplode::libexe)
    endif()
endfunction()
