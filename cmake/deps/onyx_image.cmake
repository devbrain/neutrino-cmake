# =============================================================================
# onyx_image.cmake - Multi-format image loading library
# =============================================================================
# Target: neutrino::onyx_image
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_ONYX_IMAGE_VERSION "master" CACHE STRING "onyx_image version/tag")

function(neutrino_fetch_onyx_image)
    if(TARGET neutrino::onyx_image OR TARGET onyx_image)
        message(STATUS "[Neutrino] onyx_image already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching onyx_image...")

    include(FetchContent)

    FetchContent_Declare(onyx_image
        GIT_REPOSITORY https://github.com/devbrain/onyx_image.git
        GIT_TAG ${NEUTRINO_ONYX_IMAGE_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable onyx_image tests and examples when used as dependency
    set(NEUTRINO_ONYX_IMAGE_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_ONYX_IMAGE_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(onyx_image)

    # Create neutrino:: alias if not already created
    if(TARGET onyx_image AND NOT TARGET neutrino::onyx_image)
        add_library(neutrino::onyx_image ALIAS onyx_image)
    endif()

    # Suppress warnings for onyx_image headers
    if(TARGET onyx_image)
        neutrino_suppress_warnings(onyx_image)
    endif()
endfunction()
