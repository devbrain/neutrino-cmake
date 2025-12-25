# =============================================================================
# datascript.cmake - Binary format parser generator
# =============================================================================
# Targets:
#   neutrino::datascript - The library
#   ds (executable)      - The code generator tool
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_DATASCRIPT_VERSION "master" CACHE STRING "datascript version/tag")

function(neutrino_fetch_datascript)
    if(TARGET neutrino::datascript OR TARGET ds)
        message(STATUS "[Neutrino] datascript already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching datascript...")

    include(FetchContent)

    FetchContent_Declare(datascript
        GIT_REPOSITORY https://github.com/devbrain/datascript.git
        GIT_TAG ${NEUTRINO_DATASCRIPT_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable datascript tests when used as dependency
    set(NEUTRINO_DATASCRIPT_BUILD_TESTS OFF CACHE BOOL "" FORCE)

    # Enable host tools (ds code generator) - required for code generation
    set(NEUTRINO_DATASCRIPT_BUILD_HOST_TOOLS ON CACHE BOOL "" FORCE)

    # Disable warnings for dependency build
    set(NEUTRINO_WARNINGS_AS_ERRORS OFF)

    FetchContent_MakeAvailable(datascript)

    # Create neutrino:: alias for the library if not already created
    if(TARGET datascript AND NOT TARGET neutrino::datascript)
        add_library(neutrino::datascript ALIAS datascript)
    endif()

    # Suppress warnings for datascript and ds tool
    if(TARGET datascript)
        neutrino_suppress_warnings(datascript)
    endif()
    if(TARGET ds)
        neutrino_suppress_warnings(ds)
    endif()
endfunction()

# Function to use datascript code generator
# This wraps datascript_generate() if available
function(neutrino_datascript_generate)
    cmake_parse_arguments(ARG
        ""
        "TARGET;OUTPUT_DIR"
        "SCHEMAS;IMPORT_DIRS;INCLUDE_DIRS"
        ${ARGN}
    )

    if(NOT COMMAND datascript_generate)
        message(FATAL_ERROR
            "[Neutrino] datascript_generate not available. "
            "Call neutrino_fetch_datascript() first."
        )
    endif()

    datascript_generate(
        TARGET ${ARG_TARGET}
        SCHEMAS ${ARG_SCHEMAS}
        OUTPUT_DIR ${ARG_OUTPUT_DIR}
        IMPORT_DIRS ${ARG_IMPORT_DIRS}
        INCLUDE_DIRS ${ARG_INCLUDE_DIRS}
        PRESERVE_PACKAGE_DIRS ON
    )
endfunction()
