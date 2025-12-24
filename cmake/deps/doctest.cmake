# =============================================================================
# doctest.cmake - Lightweight C++ testing framework
# =============================================================================
# Target: doctest::doctest
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_DOCTEST_VERSION "2.4.11" CACHE STRING "doctest version")

function(neutrino_fetch_doctest)
    if(TARGET doctest::doctest)
        message(STATUS "[Neutrino] doctest already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching doctest ${NEUTRINO_DOCTEST_VERSION}...")

    include(FetchContent)

    # Disable doctest's own tests
    set(DOCTEST_NO_INSTALL ON CACHE BOOL "" FORCE)

    FetchContent_Declare(doctest
        GIT_REPOSITORY https://github.com/doctest/doctest.git
        GIT_TAG v${NEUTRINO_DOCTEST_VERSION}
        GIT_SHALLOW TRUE
        PATCH_COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../patches/patch_cmake_minimum.cmake
    )

    FetchContent_MakeAvailable(doctest)

    # Suppress warnings for doctest headers
    if(TARGET doctest)
        neutrino_suppress_warnings(doctest)
    endif()
endfunction()
