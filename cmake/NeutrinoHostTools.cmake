# =============================================================================
# NeutrinoHostTools.cmake
# =============================================================================
# Cross-compilation support for host tools (code generators).
#
# When cross-compiling (e.g., for Emscripten), code generators like datascript
# still need to run on the host machine. This module provides infrastructure
# for building such tools natively even when the main build is cross-compiled.
# =============================================================================

include_guard(GLOBAL)

include(ExternalProject)

# -----------------------------------------------------------------------------
# Host Tools Directory
# -----------------------------------------------------------------------------

# Directory where host tools are built/found
if(NOT NEUTRINO_HOST_TOOLS_DIR)
    set(NEUTRINO_HOST_TOOLS_DIR "${CMAKE_BINARY_DIR}/host-tools")
endif()

# List of registered host tools
set(NEUTRINO_HOST_TOOLS "" CACHE INTERNAL "List of host tools")

# -----------------------------------------------------------------------------
# Host Tool Functions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_require_host_tool(<tool_name>
    [PACKAGE <package>]
    [TARGET <target>]
    [GIT_REPOSITORY <url>]
    [GIT_TAG <tag>]
    [CMAKE_ARGS <args>...]
)

Ensure a host tool is available for code generation.

When not cross-compiling, this simply finds or builds the tool normally.
When cross-compiling, this builds the tool natively using ExternalProject.

Arguments:
    tool_name       - Name of the tool executable
    PACKAGE         - Package name for find_package (default: tool_name)
    TARGET          - CMake target providing the tool (default: tool_name)
    GIT_REPOSITORY  - Git repository URL for the tool source
    GIT_TAG         - Git tag/branch to use
    CMAKE_ARGS      - Additional CMake arguments for building

After calling this function, the tool is available as:
    ${NEUTRINO_<TOOL_NAME>_EXECUTABLE}
#]=============================================================================]
function(neutrino_require_host_tool TOOL_NAME)
    cmake_parse_arguments(ARG
        ""
        "PACKAGE;TARGET;GIT_REPOSITORY;GIT_TAG"
        "CMAKE_ARGS"
        ${ARGN}
    )

    string(TOUPPER "${TOOL_NAME}" TOOL_UPPER)
    string(REPLACE "-" "_" TOOL_UPPER "${TOOL_UPPER}")

    if(NOT ARG_PACKAGE)
        set(ARG_PACKAGE "${TOOL_NAME}")
    endif()

    if(NOT ARG_TARGET)
        set(ARG_TARGET "${TOOL_NAME}")
    endif()

    # Check if already available
    if(DEFINED NEUTRINO_${TOOL_UPPER}_EXECUTABLE AND EXISTS "${NEUTRINO_${TOOL_UPPER}_EXECUTABLE}")
        message(STATUS "[Neutrino] Host tool ${TOOL_NAME}: ${NEUTRINO_${TOOL_UPPER}_EXECUTABLE}")
        return()
    endif()

    if(NOT NEUTRINO_CROSS_COMPILING)
        # Not cross-compiling: find or use the tool from the current build
        if(TARGET ${ARG_TARGET})
            # Tool is being built in this project
            set(NEUTRINO_${TOOL_UPPER}_EXECUTABLE "$<TARGET_FILE:${ARG_TARGET}>" CACHE INTERNAL "")
            message(STATUS "[Neutrino] Host tool ${TOOL_NAME}: using build target")
        else()
            # Try to find installed tool
            find_program(_tool_exe ${TOOL_NAME})
            if(_tool_exe)
                set(NEUTRINO_${TOOL_UPPER}_EXECUTABLE "${_tool_exe}" CACHE INTERNAL "")
                message(STATUS "[Neutrino] Host tool ${TOOL_NAME}: ${_tool_exe}")
            else()
                message(FATAL_ERROR
                    "[Neutrino] Host tool ${TOOL_NAME} not found. "
                    "Please install it or provide GIT_REPOSITORY to build from source."
                )
            endif()
        endif()
    else()
        # Cross-compiling: build the tool natively using ExternalProject
        if(NOT ARG_GIT_REPOSITORY)
            # Try to find pre-installed tool
            find_program(_tool_exe ${TOOL_NAME})
            if(_tool_exe)
                set(NEUTRINO_${TOOL_UPPER}_EXECUTABLE "${_tool_exe}" CACHE INTERNAL "")
                message(STATUS "[Neutrino] Host tool ${TOOL_NAME} (pre-installed): ${_tool_exe}")
                return()
            else()
                message(FATAL_ERROR
                    "[Neutrino] Cross-compiling but host tool ${TOOL_NAME} not found. "
                    "Either install it on the host system or provide GIT_REPOSITORY to build from source."
                )
            endif()
        endif()

        # Build directory for host tools
        set(_host_build_dir "${NEUTRINO_HOST_TOOLS_DIR}/${TOOL_NAME}")
        set(_host_install_dir "${NEUTRINO_HOST_TOOLS_DIR}/install")

        message(STATUS "[Neutrino] Building host tool ${TOOL_NAME} natively...")

        # Build the tool using ExternalProject
        ExternalProject_Add(${TOOL_NAME}_host
            GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
            GIT_TAG ${ARG_GIT_TAG}
            GIT_SHALLOW TRUE
            PREFIX "${_host_build_dir}"
            CMAKE_ARGS
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_INSTALL_PREFIX=${_host_install_dir}
                ${ARG_CMAKE_ARGS}
            BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
            INSTALL_COMMAND ${CMAKE_COMMAND} --install <BINARY_DIR> --config Release
            BUILD_BYPRODUCTS "${_host_install_dir}/bin/${TOOL_NAME}"
        )

        # Set executable path
        if(WIN32)
            set(_exe_suffix ".exe")
        else()
            set(_exe_suffix "")
        endif()

        set(NEUTRINO_${TOOL_UPPER}_EXECUTABLE
            "${_host_install_dir}/bin/${TOOL_NAME}${_exe_suffix}"
            CACHE INTERNAL ""
        )

        # Register as host tool
        list(APPEND NEUTRINO_HOST_TOOLS ${TOOL_NAME}_host)
        set(NEUTRINO_HOST_TOOLS "${NEUTRINO_HOST_TOOLS}" CACHE INTERNAL "")
    endif()
endfunction()

#[=============================================================================[
neutrino_add_host_tool_dependency(<target> <tool_name>)

Add dependency on a host tool to a target.
Ensures the host tool is built before the target.
#]=============================================================================]
function(neutrino_add_host_tool_dependency TARGET TOOL_NAME)
    if(TARGET ${TOOL_NAME}_host)
        add_dependencies(${TARGET} ${TOOL_NAME}_host)
    endif()
endfunction()

#[=============================================================================[
neutrino_run_host_tool(<tool_name>
    OUTPUT <output>
    [DEPENDS <depends>...]
    [ARGS <args>...]
    [WORKING_DIRECTORY <dir>]
    [COMMENT <comment>]
)

Run a host tool as a custom command to generate files.

Arguments:
    tool_name           - Name of the tool (must be registered with neutrino_require_host_tool)
    OUTPUT              - Output file(s) generated by the tool
    DEPENDS             - Input files the command depends on
    ARGS                - Arguments to pass to the tool
    WORKING_DIRECTORY   - Working directory for the command
    COMMENT             - Comment to display during build
#]=============================================================================]
function(neutrino_run_host_tool TOOL_NAME)
    cmake_parse_arguments(ARG
        ""
        "WORKING_DIRECTORY;COMMENT"
        "OUTPUT;DEPENDS;ARGS"
        ${ARGN}
    )

    string(TOUPPER "${TOOL_NAME}" TOOL_UPPER)
    string(REPLACE "-" "_" TOOL_UPPER "${TOOL_UPPER}")

    if(NOT DEFINED NEUTRINO_${TOOL_UPPER}_EXECUTABLE)
        message(FATAL_ERROR
            "[Neutrino] Host tool ${TOOL_NAME} not registered. "
            "Call neutrino_require_host_tool(${TOOL_NAME} ...) first."
        )
    endif()

    if(NOT ARG_OUTPUT)
        message(FATAL_ERROR "[Neutrino] neutrino_run_host_tool requires OUTPUT argument")
    endif()

    set(_cmd ${NEUTRINO_${TOOL_UPPER}_EXECUTABLE} ${ARG_ARGS})

    set(_depends ${ARG_DEPENDS})
    if(TARGET ${TOOL_NAME}_host)
        list(APPEND _depends ${TOOL_NAME}_host)
    endif()

    set(_opts "")
    if(ARG_WORKING_DIRECTORY)
        list(APPEND _opts WORKING_DIRECTORY "${ARG_WORKING_DIRECTORY}")
    endif()
    if(ARG_COMMENT)
        list(APPEND _opts COMMENT "${ARG_COMMENT}")
    else()
        list(APPEND _opts COMMENT "Running ${TOOL_NAME}...")
    endif()

    add_custom_command(
        OUTPUT ${ARG_OUTPUT}
        COMMAND ${_cmd}
        DEPENDS ${_depends}
        ${_opts}
        VERBATIM
    )
endfunction()
