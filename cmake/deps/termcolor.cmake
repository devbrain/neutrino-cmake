# =============================================================================
# termcolor.cmake - Terminal color output library
# =============================================================================
# Target: termcolor::termcolor
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_TERMCOLOR_VERSION "2.1.0" CACHE STRING "termcolor version")

function(neutrino_fetch_termcolor)
    if(TARGET termcolor::termcolor)
        message(STATUS "[Neutrino] termcolor already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching termcolor ${NEUTRINO_TERMCOLOR_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(termcolor
        GIT_REPOSITORY https://github.com/ikalnytskyi/termcolor.git
        GIT_TAG v${NEUTRINO_TERMCOLOR_VERSION}
        GIT_SHALLOW TRUE
    )

    FetchContent_MakeAvailable(termcolor)
endfunction()
