# =============================================================================
# neutrino-cmake - CMake Tooling for the Neutrino Ecosystem
# =============================================================================
# This CMakeLists.txt is for testing the neutrino-cmake modules themselves.
# It is NOT required for consumers - they just include NeutrinoInit.cmake.
# =============================================================================

cmake_minimum_required(VERSION 3.20)

project(neutrino-cmake
    VERSION 1.0.0
    DESCRIPTION "CMake tooling for the Neutrino C++ ecosystem"
    LANGUAGES CXX
)

# Add our cmake directory to the module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Include the init module (this tests that all modules load correctly)
include(NeutrinoInit)

# =============================================================================
# Self-Tests
# =============================================================================

option(NEUTRINO_CMAKE_BUILD_TESTS "Build neutrino-cmake tests" ${PROJECT_IS_TOP_LEVEL})

if(NEUTRINO_CMAKE_BUILD_TESTS)
    enable_testing()

    # -------------------------------------------------------------------------
    # Test 1: Verify all modules are included
    # -------------------------------------------------------------------------
    add_test(
        NAME "modules_loaded"
        COMMAND ${CMAKE_COMMAND} -E echo "All modules loaded successfully"
    )

    # -------------------------------------------------------------------------
    # Test 2: Test project generation script
    # -------------------------------------------------------------------------
    set(_test_project_dir "${CMAKE_BINARY_DIR}/test-generated-project")

    add_test(
        NAME "generator_creates_project"
        COMMAND ${CMAKE_COMMAND} -E rm -rf "${_test_project_dir}"
    )

    add_test(
        NAME "generator_runs"
        COMMAND python3 "${CMAKE_CURRENT_SOURCE_DIR}/scripts/neutrino-new.py"
            test-lib
            --type=header-only
            --std=20
            --output="${CMAKE_BINARY_DIR}"
            --force
    )
    set_tests_properties(generator_runs PROPERTIES
        DEPENDS generator_creates_project
    )

    add_test(
        NAME "generator_output_exists"
        COMMAND ${CMAKE_COMMAND} -E cat "${_test_project_dir}/CMakeLists.txt"
    )
    set_tests_properties(generator_output_exists PROPERTIES
        DEPENDS generator_runs
    )

    # -------------------------------------------------------------------------
    # Test 3: Generated project configures
    # -------------------------------------------------------------------------
    add_test(
        NAME "generated_project_configures"
        COMMAND ${CMAKE_COMMAND}
            -S "${_test_project_dir}"
            -B "${_test_project_dir}/build"
            -DNEUTRINO_TEST_LIB_BUILD_TESTS=OFF
            -DNEUTRINO_TEST_LIB_BUILD_EXAMPLES=OFF
    )
    set_tests_properties(generated_project_configures PROPERTIES
        DEPENDS generator_output_exists
    )

    # -------------------------------------------------------------------------
    # Test 4: Test dependency fetching (doctest as example)
    # -------------------------------------------------------------------------
    add_test(
        NAME "fetch_doctest"
        COMMAND ${CMAKE_COMMAND}
            -DNEUTRINO_CMAKE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/cmake
            -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/tests/test_fetch_doctest.cmake"
    )

    # Create test script for doctest fetching
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/tests/test_fetch_doctest.cmake" [[
cmake_minimum_required(VERSION 3.20)

list(APPEND CMAKE_MODULE_PATH "${NEUTRINO_CMAKE_DIR}")
include(NeutrinoInit)
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)

neutrino_fetch_doctest()

if(NOT TARGET doctest::doctest)
    message(FATAL_ERROR "doctest::doctest target not created")
endif()

message(STATUS "doctest fetch test PASSED")
]])

endif()

# =============================================================================
# Installation
# =============================================================================

option(NEUTRINO_CMAKE_INSTALL "Install neutrino-cmake modules" ${PROJECT_IS_TOP_LEVEL})

if(NEUTRINO_CMAKE_INSTALL)
    include(GNUInstallDirs)

    # Install cmake modules
    install(
        DIRECTORY cmake/
        DESTINATION "${CMAKE_INSTALL_DATADIR}/cmake/neutrino-cmake"
        FILES_MATCHING
            PATTERN "*.cmake"
    )

    # Install scripts
    install(
        PROGRAMS scripts/neutrino-new.py
        DESTINATION "${CMAKE_INSTALL_BINDIR}"
        RENAME neutrino-new
    )

    # Install templates
    install(
        DIRECTORY templates/
        DESTINATION "${CMAKE_INSTALL_DATADIR}/neutrino-cmake/templates"
        FILES_MATCHING
            PATTERN "*.in"
            PATTERN "*.cmake"
    )
endif()

# =============================================================================
# Summary
# =============================================================================

message(STATUS "")
message(STATUS "neutrino-cmake ${PROJECT_VERSION} Configuration:")
message(STATUS "  Build tests:  ${NEUTRINO_CMAKE_BUILD_TESTS}")
message(STATUS "  Install:      ${NEUTRINO_CMAKE_INSTALL}")
message(STATUS "")
message(STATUS "Modules available at: ${NEUTRINO_CMAKE_DIR}")
message(STATUS "")
