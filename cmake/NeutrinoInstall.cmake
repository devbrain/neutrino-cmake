# =============================================================================
# NeutrinoInstall.cmake
# =============================================================================
# Installation helpers for the Neutrino ecosystem.
# Provides consistent package configuration and installation across components.
# =============================================================================

include_guard(GLOBAL)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# -----------------------------------------------------------------------------
# Installation Functions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_install_headers(<target>
    [DIRECTORY <dir>]
    [DESTINATION <dest>]
    [PATTERN <pattern>...]
)

Install header files for a library target.

Arguments:
    target      - The library target
    DIRECTORY   - Source directory (default: ${PROJECT_SOURCE_DIR}/include)
    DESTINATION - Install destination (default: ${CMAKE_INSTALL_INCLUDEDIR})
    PATTERN     - File patterns to match (default: *.h *.hh *.hpp)
#]=============================================================================]
function(neutrino_install_headers TARGET)
    cmake_parse_arguments(ARG
        ""
        "DIRECTORY;DESTINATION"
        "PATTERN"
        ${ARGN}
    )

    if(NOT ARG_DIRECTORY)
        set(ARG_DIRECTORY "${PROJECT_SOURCE_DIR}/include")
    endif()

    if(NOT ARG_DESTINATION)
        set(ARG_DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    if(NOT ARG_PATTERN)
        set(ARG_PATTERN "*.h" "*.hh" "*.hpp")
    endif()

    # Build FILES_MATCHING arguments
    set(_files_matching "")
    foreach(_pattern ${ARG_PATTERN})
        list(APPEND _files_matching PATTERN "${_pattern}")
    endforeach()

    install(DIRECTORY "${ARG_DIRECTORY}/"
        DESTINATION "${ARG_DESTINATION}"
        FILES_MATCHING ${_files_matching}
    )
endfunction()

#[=============================================================================[
neutrino_install_library(<target>
    [NAMESPACE <ns>]
    [COMPATIBILITY <compat>]
    [DEPENDENCIES <deps>]
    [EXPORT_NAME <name>]
    [CONFIG_TEMPLATE <template>]
    [SKIP_EXPORT]
)

Install a library with package configuration files.

Arguments:
    target          - The library target
    NAMESPACE       - CMake namespace (default: neutrino::)
    COMPATIBILITY   - Version compatibility mode (default: SameMajorVersion)
    DEPENDENCIES    - find_dependency() calls for Config.cmake
    EXPORT_NAME     - Export name (default: ${target}Targets)
    CONFIG_TEMPLATE - Custom Config.cmake.in template
    SKIP_EXPORT     - Skip install(EXPORT), create IMPORTED target manually.
                      Use this when dependencies come from FetchContent.
#]=============================================================================]
function(neutrino_install_library TARGET)
    cmake_parse_arguments(ARG
        "SKIP_EXPORT"
        "NAMESPACE;COMPATIBILITY;EXPORT_NAME;CONFIG_TEMPLATE"
        "DEPENDENCIES"
        ${ARGN}
    )

    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE "neutrino::")
    endif()

    if(NOT ARG_COMPATIBILITY)
        set(ARG_COMPATIBILITY SameMajorVersion)
    endif()

    if(NOT ARG_EXPORT_NAME)
        set(ARG_EXPORT_NAME "${TARGET}Targets")
    endif()

    # Determine install directories
    set(_lib_dir "${CMAKE_INSTALL_LIBDIR}")
    set(_include_dir "${CMAKE_INSTALL_INCLUDEDIR}")
    set(_cmake_dir "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}")

    # Get target type
    get_target_property(_type ${TARGET} TYPE)

    if(ARG_SKIP_EXPORT)
        # Install without EXPORT - for projects using FetchContent dependencies
        if(_type STREQUAL "INTERFACE_LIBRARY")
            install(TARGETS ${TARGET}
                INCLUDES DESTINATION "${_include_dir}"
            )
        else()
            install(TARGETS ${TARGET}
                RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
                LIBRARY DESTINATION "${_lib_dir}"
                ARCHIVE DESTINATION "${_lib_dir}"
                INCLUDES DESTINATION "${_include_dir}"
            )
        endif()

        # Generate config that creates IMPORTED target manually
        set(_config_content "@PACKAGE_INIT@\n\n")

        # Add dependencies
        if(ARG_DEPENDENCIES)
            string(APPEND _config_content "include(CMakeFindDependencyMacro)\n\n")
            foreach(_dep ${ARG_DEPENDENCIES})
                string(APPEND _config_content "${_dep}\n")
            endforeach()
            string(APPEND _config_content "\n")
        endif()

        # Create IMPORTED target
        string(APPEND _config_content "if(NOT TARGET ${ARG_NAMESPACE}${TARGET})\n")
        if(_type STREQUAL "INTERFACE_LIBRARY")
            string(APPEND _config_content "    add_library(${ARG_NAMESPACE}${TARGET} INTERFACE IMPORTED)\n")
            string(APPEND _config_content "    set_target_properties(${ARG_NAMESPACE}${TARGET} PROPERTIES\n")
            string(APPEND _config_content "        INTERFACE_INCLUDE_DIRECTORIES \"\${PACKAGE_PREFIX_DIR}/${_include_dir}\"\n")
            string(APPEND _config_content "    )\n")
        elseif(_type STREQUAL "STATIC_LIBRARY")
            string(APPEND _config_content "    add_library(${ARG_NAMESPACE}${TARGET} STATIC IMPORTED)\n")
            string(APPEND _config_content "    set_target_properties(${ARG_NAMESPACE}${TARGET} PROPERTIES\n")
            string(APPEND _config_content "        INTERFACE_INCLUDE_DIRECTORIES \"\${PACKAGE_PREFIX_DIR}/${_include_dir}\"\n")
            string(APPEND _config_content "        IMPORTED_LOCATION \"\${PACKAGE_PREFIX_DIR}/${_lib_dir}/\${CMAKE_STATIC_LIBRARY_PREFIX}${TARGET}\${CMAKE_STATIC_LIBRARY_SUFFIX}\"\n")
            string(APPEND _config_content "    )\n")
        else()
            string(APPEND _config_content "    add_library(${ARG_NAMESPACE}${TARGET} SHARED IMPORTED)\n")
            string(APPEND _config_content "    set_target_properties(${ARG_NAMESPACE}${TARGET} PROPERTIES\n")
            string(APPEND _config_content "        INTERFACE_INCLUDE_DIRECTORIES \"\${PACKAGE_PREFIX_DIR}/${_include_dir}\"\n")
            string(APPEND _config_content "        IMPORTED_LOCATION \"\${PACKAGE_PREFIX_DIR}/${_lib_dir}/\${CMAKE_SHARED_LIBRARY_PREFIX}${TARGET}\${CMAKE_SHARED_LIBRARY_SUFFIX}\"\n")
            string(APPEND _config_content "    )\n")
        endif()
        string(APPEND _config_content "endif()\n")

        string(APPEND _config_content "\ncheck_required_components(${TARGET})\n")

        # Write config template
        file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "${_config_content}")

        configure_package_config_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in"
            "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake"
            INSTALL_DESTINATION "${_cmake_dir}"
        )
    else()
        # Standard install with EXPORT
        if(_type STREQUAL "INTERFACE_LIBRARY")
            install(TARGETS ${TARGET}
                EXPORT ${ARG_EXPORT_NAME}
                INCLUDES DESTINATION "${_include_dir}"
            )
        else()
            install(TARGETS ${TARGET}
                EXPORT ${ARG_EXPORT_NAME}
                RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
                LIBRARY DESTINATION "${_lib_dir}"
                ARCHIVE DESTINATION "${_lib_dir}"
                INCLUDES DESTINATION "${_include_dir}"
            )
        endif()

        # Install export file
        install(EXPORT ${ARG_EXPORT_NAME}
            FILE ${ARG_EXPORT_NAME}.cmake
            NAMESPACE ${ARG_NAMESPACE}
            DESTINATION "${_cmake_dir}"
        )

        # Generate and install package config files
        if(ARG_CONFIG_TEMPLATE)
            # Use provided template
            configure_package_config_file(
                "${ARG_CONFIG_TEMPLATE}"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake"
                INSTALL_DESTINATION "${_cmake_dir}"
            )
        else()
            # Generate config file content
            set(_config_content "@PACKAGE_INIT@\n\n")

            # Add dependencies
            if(ARG_DEPENDENCIES)
                string(APPEND _config_content "include(CMakeFindDependencyMacro)\n\n")
                foreach(_dep ${ARG_DEPENDENCIES})
                    string(APPEND _config_content "${_dep}\n")
                endforeach()
                string(APPEND _config_content "\n")
            endif()

            string(APPEND _config_content "include(\"\${CMAKE_CURRENT_LIST_DIR}/${ARG_EXPORT_NAME}.cmake\")\n")
            string(APPEND _config_content "\ncheck_required_components(${TARGET})\n")

            # Write temporary config template
            file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in" "${_config_content}")

            configure_package_config_file(
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake.in"
                "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake"
                INSTALL_DESTINATION "${_cmake_dir}"
            )
        endif()
    endif()

    # Generate version file
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}ConfigVersion.cmake"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY ${ARG_COMPATIBILITY}
    )

    # Install config files
    install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}Config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}ConfigVersion.cmake"
        DESTINATION "${_cmake_dir}"
    )
endfunction()

#[=============================================================================[
neutrino_install_package_files(<target>
    [DESTINATION <dest>]
    [FILES <file>...]
)

Install additional package files (e.g., custom Find modules).

Arguments:
    target      - The package name
    DESTINATION - Install destination (default: ${CMAKE_INSTALL_LIBDIR}/cmake/${target})
    FILES       - Files to install
#]=============================================================================]
function(neutrino_install_package_files TARGET)
    cmake_parse_arguments(ARG
        ""
        "DESTINATION"
        "FILES"
        ${ARGN}
    )

    if(NOT ARG_DESTINATION)
        set(ARG_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${TARGET}")
    endif()

    if(ARG_FILES)
        install(FILES ${ARG_FILES}
            DESTINATION "${ARG_DESTINATION}"
        )
    endif()
endfunction()

#[=============================================================================[
neutrino_export_for_build_tree(<target>
    [NAMESPACE <ns>]
    [EXPORT_NAME <name>]
)

Export target for use directly from the build tree (without installation).
Useful for development and FetchContent consumers.

Arguments:
    target      - The library target
    NAMESPACE   - CMake namespace (default: neutrino::)
    EXPORT_NAME - Export name (default: ${target}Targets)
#]=============================================================================]
function(neutrino_export_for_build_tree TARGET)
    cmake_parse_arguments(ARG
        ""
        "NAMESPACE;EXPORT_NAME"
        ""
        ${ARGN}
    )

    if(NOT ARG_NAMESPACE)
        set(ARG_NAMESPACE "neutrino::")
    endif()

    if(NOT ARG_EXPORT_NAME)
        set(ARG_EXPORT_NAME "${TARGET}Targets")
    endif()

    export(TARGETS ${TARGET}
        NAMESPACE ${ARG_NAMESPACE}
        FILE "${CMAKE_CURRENT_BINARY_DIR}/${ARG_EXPORT_NAME}.cmake"
    )

    # Register package in user package registry for find_package to discover
    export(PACKAGE ${TARGET})
endfunction()
