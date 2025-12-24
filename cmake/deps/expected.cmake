# =============================================================================
# expected.cmake - std::expected backport (tl::expected)
# =============================================================================
# Target: tl::expected
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_EXPECTED_VERSION "1.1.0" CACHE STRING "tl::expected version")

function(neutrino_fetch_expected)
    if(TARGET tl::expected)
        message(STATUS "[Neutrino] tl::expected already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching tl::expected ${NEUTRINO_EXPECTED_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(expected
        GIT_REPOSITORY https://github.com/TartanLlama/expected.git
        GIT_TAG v${NEUTRINO_EXPECTED_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable tests and examples
    set(EXPECTED_BUILD_TESTS OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(expected)
endfunction()
