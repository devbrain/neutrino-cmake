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

    FetchContent_Declare(doctest
        GIT_REPOSITORY https://github.com/doctest/doctest.git
        GIT_TAG v${NEUTRINO_DOCTEST_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable doctest's own tests
    set(DOCTEST_NO_INSTALL ON CACHE BOOL "" FORCE)

    FetchContent_GetProperties(doctest)
    if(NOT doctest_POPULATED)
        FetchContent_Populate(doctest)

        # Patch cmake_minimum_required for CMake 4.x compatibility
        file(READ ${doctest_SOURCE_DIR}/CMakeLists.txt _doctest_cmake_content)
        string(REGEX REPLACE
            "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+\\)"
            "cmake_minimum_required(VERSION 3.5)"
            _doctest_cmake_content "${_doctest_cmake_content}")
        file(WRITE ${doctest_SOURCE_DIR}/CMakeLists.txt "${_doctest_cmake_content}")

        add_subdirectory(${doctest_SOURCE_DIR} ${doctest_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()

    # Suppress warnings for doctest headers
    if(TARGET doctest)
        neutrino_suppress_warnings(doctest)
    endif()
endfunction()
