# =============================================================================
# GLEW.cmake - OpenGL Extension Wrangler Library
# =============================================================================
# Target: GLEW::GLEW
# =============================================================================
# GLEW is only needed on Windows and Linux, not on macOS (which uses native
# OpenGL extension loading).
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_GLEW_VERSION "2.2.0" CACHE STRING "GLEW version")

function(neutrino_fetch_GLEW)
    if(TARGET GLEW::GLEW OR TARGET GLEW::glew)
        message(STATUS "[Neutrino] GLEW already available")
        return()
    endif()

    # Skip GLEW on Apple platforms (not needed)
    if(APPLE)
        message(STATUS "[Neutrino] GLEW not needed on Apple platforms")
        # Create a stub interface target so dependent code can still link
        if(NOT TARGET GLEW::GLEW)
            add_library(glew_stub INTERFACE)
            add_library(GLEW::GLEW ALIAS glew_stub)
        endif()
        return()
    endif()

    # First try to find system GLEW
    find_package(GLEW QUIET CONFIG)
    if(TARGET GLEW::GLEW)
        message(STATUS "[Neutrino] Using system GLEW (config)")
        return()
    endif()

    # Try to find using Find module
    find_package(GLEW QUIET)
    if(GLEW_FOUND)
        message(STATUS "[Neutrino] Using system GLEW")
        # Create modern target if not available
        if(NOT TARGET GLEW::GLEW)
            add_library(GLEW::GLEW IMPORTED INTERFACE)
            set_target_properties(GLEW::GLEW PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${GLEW_INCLUDE_DIRS}"
                INTERFACE_LINK_LIBRARIES "${GLEW_LIBRARIES}"
            )
        endif()
        return()
    endif()

    # Fetch from source
    message(STATUS "[Neutrino] Fetching GLEW ${NEUTRINO_GLEW_VERSION}...")

    include(FetchContent)

    # GLEW has its CMake files in build/cmake subdirectory
    FetchContent_Declare(GLEW
        GIT_REPOSITORY https://github.com/nigels-com/glew.git
        GIT_TAG glew-${NEUTRINO_GLEW_VERSION}
        GIT_SHALLOW TRUE
        SOURCE_SUBDIR build/cmake
    )

    # GLEW build options - prefer static library
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
    set(glew-cmake_BUILD_SHARED OFF CACHE BOOL "" FORCE)
    set(ONLY_LIBS ON CACHE BOOL "" FORCE)
    set(glew-cmake_BUILD_STATIC ON CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(GLEW)

    # Create alias if needed (GLEW cmake creates libglew_static or glew_s)
    if(TARGET glew_s AND NOT TARGET GLEW::GLEW)
        add_library(GLEW::GLEW ALIAS glew_s)
    elseif(TARGET libglew_static AND NOT TARGET GLEW::GLEW)
        add_library(GLEW::GLEW ALIAS libglew_static)
    elseif(TARGET glew AND NOT TARGET GLEW::GLEW)
        add_library(GLEW::GLEW ALIAS glew)
    endif()

    # Suppress warnings for third-party library
    if(TARGET glew_s)
        neutrino_suppress_warnings(glew_s)
    elseif(TARGET libglew_static)
        neutrino_suppress_warnings(libglew_static)
    elseif(TARGET glew)
        neutrino_suppress_warnings(glew)
    endif()
endfunction()
