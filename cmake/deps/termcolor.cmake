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

    FetchContent_GetProperties(termcolor)
    if(NOT termcolor_POPULATED)
        FetchContent_Populate(termcolor)

        # Patch cmake_minimum_required for CMake 4.x compatibility
        file(READ ${termcolor_SOURCE_DIR}/CMakeLists.txt _termcolor_cmake_content)
        string(REGEX REPLACE
            "cmake_minimum_required\\(VERSION [0-9]+\\.[0-9]+\\)"
            "cmake_minimum_required(VERSION 3.5)"
            _termcolor_cmake_content "${_termcolor_cmake_content}")
        file(WRITE ${termcolor_SOURCE_DIR}/CMakeLists.txt "${_termcolor_cmake_content}")

        add_subdirectory(${termcolor_SOURCE_DIR} ${termcolor_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()
endfunction()
