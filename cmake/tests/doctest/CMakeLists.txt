cmake_minimum_required(VERSION 3.20)
project(neutrino_doctest_fetch_test LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${NEUTRINO_CMAKE_DIR}")
include(NeutrinoInit)
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
neutrino_fetch_doctest()

if(NOT TARGET doctest::doctest)
    message(FATAL_ERROR "doctest::doctest target not created")
endif()
