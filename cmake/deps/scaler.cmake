# =============================================================================
# scaler.cmake - Image scaling library
# =============================================================================
# Target: neutrino::scaler
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_SCALER_VERSION "master" CACHE STRING "scaler version/tag")

function(neutrino_fetch_scaler)
    if(TARGET neutrino::scaler OR TARGET scaler::scaler)
        message(STATUS "[Neutrino] scaler already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching scaler...")

    include(FetchContent)

    FetchContent_Declare(scaler
        GIT_REPOSITORY https://github.com/devbrain/scaler.git
        GIT_TAG ${NEUTRINO_SCALER_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable scaler tests when used as dependency
    set(NEUTRINO_SCALER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_SCALER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(scaler)

    # Create neutrino:: alias if not already created
    if(TARGET scaler AND NOT TARGET neutrino::scaler)
        add_library(neutrino::scaler ALIAS scaler)
    endif()
endfunction()
