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

    # Download just the header file from releases
    FetchContent_Declare(doctest
        URL https://github.com/doctest/doctest/releases/download/v${NEUTRINO_DOCTEST_VERSION}/doctest.h
        DOWNLOAD_NO_EXTRACT TRUE
    )

    FetchContent_MakeAvailable(doctest)

    # Create include directory structure: doctest/doctest.h
    set(_doctest_include_dir "${doctest_SOURCE_DIR}/doctest")
    if(NOT EXISTS "${_doctest_include_dir}/doctest.h")
        file(MAKE_DIRECTORY "${_doctest_include_dir}")
        file(COPY_FILE "${doctest_SOURCE_DIR}/doctest.h" "${_doctest_include_dir}/doctest.h")
    endif()

    # Create interface library
    add_library(doctest INTERFACE)
    add_library(doctest::doctest ALIAS doctest)
    target_include_directories(doctest INTERFACE "${doctest_SOURCE_DIR}")
endfunction()
