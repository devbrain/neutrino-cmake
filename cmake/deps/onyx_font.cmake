# =============================================================================
# onyx_font.cmake - Multi-format font loading and rendering library
# =============================================================================
# Target: neutrino::onyx_font
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_ONYX_FONT_VERSION "master" CACHE STRING "onyx_font version/tag")

function(neutrino_fetch_onyx_font)
    if(TARGET neutrino::onyx_font OR TARGET onyx_font)
        message(STATUS "[Neutrino] onyx_font already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching onyx_font...")

    include(FetchContent)

    FetchContent_Declare(onyx_font
        GIT_REPOSITORY https://github.com/devbrain/onyx_font.git
        GIT_TAG ${NEUTRINO_ONYX_FONT_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable onyx_font tests and examples when used as dependency
    set(NEUTRINO_ONYX_FONT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_ONYX_FONT_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(onyx_font)

    # Create neutrino:: alias if not already created
    if(TARGET onyx_font AND NOT TARGET neutrino::onyx_font)
        add_library(neutrino::onyx_font ALIAS onyx_font)
    endif()

    # Suppress warnings for onyx_font headers
    if(TARGET onyx_font)
        neutrino_suppress_warnings(onyx_font)
    endif()
endfunction()
