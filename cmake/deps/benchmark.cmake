# =============================================================================
# benchmark.cmake - Google Benchmark library
# =============================================================================
# Target: benchmark::benchmark
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_BENCHMARK_VERSION "1.8.3" CACHE STRING "Google Benchmark version")

function(neutrino_fetch_benchmark)
    if(TARGET benchmark::benchmark)
        message(STATUS "[Neutrino] benchmark already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching Google Benchmark ${NEUTRINO_BENCHMARK_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(benchmark
        GIT_REPOSITORY https://github.com/google/benchmark.git
        GIT_TAG v${NEUTRINO_BENCHMARK_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable benchmark tests
    set(BENCHMARK_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_GTEST_TESTS OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(benchmark)
endfunction()
