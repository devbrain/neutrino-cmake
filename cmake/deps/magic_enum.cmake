# =============================================================================
# magic_enum.cmake - Static reflection for C++ enums
# =============================================================================
# Target: magic_enum::magic_enum
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_MAGIC_ENUM_VERSION "0.9.8" CACHE STRING "magic_enum version")

function(neutrino_fetch_magic_enum)
    if(TARGET magic_enum::magic_enum)
        message(STATUS "[Neutrino] magic_enum already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching magic_enum ${NEUTRINO_MAGIC_ENUM_VERSION}...")

    include(FetchContent)
    FetchContent_Declare(magic_enum
        GIT_REPOSITORY https://github.com/Neargye/magic_enum.git
        GIT_TAG v${NEUTRINO_MAGIC_ENUM_VERSION}
        GIT_SHALLOW TRUE
    )

    set(MAGIC_ENUM_OPT_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    # Keep the dependency export available to installed consumers.
    set(MAGIC_ENUM_OPT_INSTALL ON CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(magic_enum)
endfunction()
