# =============================================================================
# euler.cmake - Line rasterization library
# =============================================================================
# Target: neutrino::euler
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_EULER_VERSION "main" CACHE STRING "euler version/tag")

function(neutrino_fetch_euler)
    if(TARGET neutrino::euler OR TARGET euler::euler)
        message(STATUS "[Neutrino] euler already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching euler...")

    include(FetchContent)

    FetchContent_Declare(euler
        GIT_REPOSITORY https://github.com/devbrain/euler.git
        GIT_TAG ${NEUTRINO_EULER_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable euler tests and examples when used as dependency
    set(NEUTRINO_EULER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_EULER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_EULER_BUILD_BENCHMARKS OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(euler)

    # Create neutrino:: alias if not already created
    if(TARGET euler AND NOT TARGET neutrino::euler)
        add_library(neutrino::euler ALIAS euler)
    endif()
endfunction()
