# =============================================================================
# utf8cpp.cmake - UTF-8 string handling library
# =============================================================================
# Target: utf8cpp::utf8cpp (or utf8::cpp)
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_UTF8CPP_VERSION "4.0.5" CACHE STRING "utf8cpp version")

function(neutrino_fetch_utf8cpp)
    if(TARGET utf8cpp::utf8cpp OR TARGET utf8::cpp)
        message(STATUS "[Neutrino] utf8cpp already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching utf8cpp ${NEUTRINO_UTF8CPP_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(utf8cpp
        GIT_REPOSITORY https://github.com/nemtrif/utfcpp.git
        GIT_TAG v${NEUTRINO_UTF8CPP_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable tests
    set(UTF8_TESTS OFF CACHE BOOL "" FORCE)
    set(UTF8_SAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(utf8cpp)

    # Create consistent alias if needed
    if(TARGET utf8::cpp AND NOT TARGET utf8cpp::utf8cpp)
        add_library(utf8cpp::utf8cpp ALIAS utf8cpp)
    endif()
endfunction()
