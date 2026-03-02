# =============================================================================
# cpptrace.cmake - Stack trace library
# =============================================================================
# Target: cpptrace::cpptrace
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_CPPTRACE_VERSION "v0.6.1" CACHE STRING "cpptrace version/tag")

function(neutrino_fetch_cpptrace)
    if(TARGET cpptrace::cpptrace)
        message(STATUS "[Neutrino] cpptrace already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching cpptrace ${NEUTRINO_CPPTRACE_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(cpptrace
        GIT_REPOSITORY https://github.com/jeremy-rifkin/cpptrace.git
        GIT_TAG ${NEUTRINO_CPPTRACE_VERSION}
        GIT_SHALLOW TRUE
        OVERRIDE_FIND_PACKAGE
    )

    # Use addr2line backend to avoid heavy libdwarf/zstd dependency chain
    set(CPPTRACE_GET_SYMBOLS_WITH_ADDR2LINE ON CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(cpptrace)

    if(TARGET cpptrace)
        neutrino_suppress_warnings(cpptrace)
    endif()
endfunction()
