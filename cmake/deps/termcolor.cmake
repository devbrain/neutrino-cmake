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

    # Download just the header file
    FetchContent_Declare(termcolor
        URL https://raw.githubusercontent.com/ikalnytskyi/termcolor/v${NEUTRINO_TERMCOLOR_VERSION}/include/termcolor/termcolor.hpp
        DOWNLOAD_NO_EXTRACT TRUE
    )

    FetchContent_MakeAvailable(termcolor)

    # Create include directory structure: termcolor/termcolor.hpp
    set(_termcolor_include_dir "${termcolor_SOURCE_DIR}/termcolor")
    if(NOT EXISTS "${_termcolor_include_dir}/termcolor.hpp")
        file(MAKE_DIRECTORY "${_termcolor_include_dir}")
        file(COPY_FILE "${termcolor_SOURCE_DIR}/termcolor.hpp" "${_termcolor_include_dir}/termcolor.hpp")
    endif()

    # Create interface library
    add_library(termcolor INTERFACE)
    add_library(termcolor::termcolor ALIAS termcolor)
    target_include_directories(termcolor INTERFACE "${termcolor_SOURCE_DIR}")
endfunction()
