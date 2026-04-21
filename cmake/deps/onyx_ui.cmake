# =============================================================================
# onyx_ui.cmake - Modern C++20 backend-agnostic UI framework
# =============================================================================
# Target: neutrino::onyx_ui
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_ONYX_UI_VERSION "master" CACHE STRING "onyx_ui version/tag")

function(neutrino_fetch_onyx_ui)
    if(TARGET neutrino::onyxui OR TARGET onyxui)
        message(STATUS "[Neutrino] onyx_ui already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching onyx_ui...")

    include(FetchContent)

    FetchContent_Declare(onyx_ui
        GIT_REPOSITORY https://github.com/devbrain/onyx_ui.git
        GIT_TAG ${NEUTRINO_ONYX_UI_VERSION}
        GIT_SHALLOW TRUE
    )

    # Sensible defaults for dependency mode: tests, examples and
    # every backend off. These are `set(... CACHE ...)` WITHOUT FORCE,
    # so a caller who sets one of the cache vars ahead of the fetch
    # (typically with `set(VAR ON CACHE BOOL "" FORCE)`) overrides the
    # default — use that to opt into backends you actually need. For
    # example warlords does:
    #     set(NEUTRINO_ONYX_UI_BUILD_BACKEND_SDLPP ON CACHE BOOL "" FORCE)
    #     neutrino_fetch_onyx_ui()
    set(NEUTRINO_ONYX_UI_BUILD_TESTS         OFF CACHE BOOL "")
    set(NEUTRINO_ONYX_UI_BUILD_EXAMPLES      OFF CACHE BOOL "")
    set(NEUTRINO_ONYX_UI_BUILD_BACKEND_CONIO OFF CACHE BOOL "")
    set(NEUTRINO_ONYX_UI_BUILD_BACKEND_SDLPP OFF CACHE BOOL "")

    FetchContent_MakeAvailable(onyx_ui)

    # Create neutrino:: alias if not already created
    if(TARGET onyxui AND NOT TARGET neutrino::onyxui)
        add_library(neutrino::onyxui ALIAS onyxui)
    endif()
endfunction()
