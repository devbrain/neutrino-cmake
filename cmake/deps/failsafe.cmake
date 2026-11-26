# =============================================================================
# failsafe.cmake - Error handling library
# =============================================================================
# Target: neutrino::failsafe
# =============================================================================

include_guard(GLOBAL)

# failsafe 1.1.0: variadic enforcement, enum type/value fallback, optional enum names,
# enforcement on std::optional, std::unique_ptr and std::shared_ptr, thread-safe backend
# swaps, scoped_log_capture for tests, and type names under a clangd that emulates GCC.
set(NEUTRINO_FAILSAFE_VERSION "26d72ece9a54d7529eb7e6281f2d808c90e5be63" CACHE STRING "failsafe version/tag")

function(neutrino_fetch_failsafe)
    if(TARGET neutrino::failsafe OR TARGET failsafe)
        message(STATUS "[Neutrino] failsafe already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching failsafe...")

    include(FetchContent)

    FetchContent_Declare(failsafe
        GIT_REPOSITORY https://github.com/devbrain/failsafe.git
        GIT_TAG ${NEUTRINO_FAILSAFE_VERSION}
        # Commit pins must remain fetchable after the upstream branch advances.
        GIT_SHALLOW FALSE
    )

    # Disable failsafe tests and examples when used as dependency
    set(NEUTRINO_FAILSAFE_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_FAILSAFE_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(failsafe)

    # Create neutrino:: alias if not already created
    if(TARGET failsafe AND NOT TARGET neutrino::failsafe)
        add_library(neutrino::failsafe ALIAS failsafe)
    endif()

    # Suppress warnings for failsafe headers
    if(TARGET failsafe)
        neutrino_suppress_warnings(failsafe)
    endif()
endfunction()
