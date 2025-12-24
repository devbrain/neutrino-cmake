# =============================================================================
# xsimd.cmake - SIMD abstraction library
# =============================================================================
# Target: xsimd::xsimd (or xsimd)
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_XSIMD_VERSION "12.1.1" CACHE STRING "xsimd version")

function(neutrino_fetch_xsimd)
    if(TARGET xsimd::xsimd OR TARGET xsimd)
        message(STATUS "[Neutrino] xsimd already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching xsimd ${NEUTRINO_XSIMD_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(xsimd
        GIT_REPOSITORY https://github.com/xtensor-stack/xsimd.git
        GIT_TAG ${NEUTRINO_XSIMD_VERSION}
        GIT_SHALLOW TRUE
    )

    FetchContent_MakeAvailable(xsimd)

    # Create namespaced alias if needed
    if(TARGET xsimd AND NOT TARGET xsimd::xsimd)
        add_library(xsimd::xsimd ALIAS xsimd)
    endif()
endfunction()
