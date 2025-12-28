cmake_minimum_required(VERSION 3.20)

list(APPEND CMAKE_MODULE_PATH "${NEUTRINO_CMAKE_DIR}")
include(NeutrinoInit)
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)

neutrino_fetch_doctest()

if(NOT TARGET doctest::doctest)
    message(FATAL_ERROR "doctest::doctest target not created")
endif()

message(STATUS "doctest fetch test PASSED")
