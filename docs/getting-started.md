# Getting Started with neutrino-cmake

This guide walks you through integrating neutrino-cmake into your C++ project.

## Prerequisites

- CMake 3.20 or higher
- A C++17 or C++20 compatible compiler

## Basic Integration

Add neutrino-cmake to your project using FetchContent:

```cmake
cmake_minimum_required(VERSION 3.20)
project(myproject VERSION 1.0.0 LANGUAGES CXX)

# Fetch neutrino-cmake
include(FetchContent)
FetchContent_Declare(neutrino_cmake
    GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
    GIT_TAG master
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(neutrino_cmake)

# Add to module path and initialize
list(APPEND CMAKE_MODULE_PATH "${neutrino_cmake_SOURCE_DIR}/cmake")
include(NeutrinoInit)
```

## Creating a Header-Only Library

```cmake
# Define standard options
neutrino_define_options(mylib)

# Print configuration
neutrino_print_options(mylib)

# Create the library
add_library(mylib INTERFACE)
add_library(neutrino::mylib ALIAS mylib)

target_include_directories(mylib INTERFACE
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_compile_features(mylib INTERFACE cxx_std_17)

# Apply warning flags
neutrino_target_warnings(mylib)
```

## Creating a Compiled Library

```cmake
# Define options including BUILD_SHARED
neutrino_define_library_options(mylib)

# Determine library type
neutrino_library_type(mylib LIB_TYPE)

# Create the library
add_library(mylib ${LIB_TYPE}
    src/mylib.cc
)
add_library(neutrino::mylib ALIAS mylib)

target_include_directories(mylib PUBLIC
    $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_compile_features(mylib PUBLIC cxx_std_17)

# Apply warning flags and sanitizers
neutrino_target_warnings(mylib)
neutrino_target_sanitizers(mylib)
```

## Adding Tests

```cmake
if(NEUTRINO_MYLIB_BUILD_TESTS)
    include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
    neutrino_fetch_doctest()

    add_executable(mylib_test test/main.cc)
    target_link_libraries(mylib_test PRIVATE mylib doctest::doctest)

    enable_testing()
    add_test(NAME mylib_test COMMAND mylib_test)
endif()
```

## Adding Dependencies

Use neutrino-cmake's dependency recipes:

```cmake
# Fetch a dependency
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)
neutrino_fetch_failsafe()

# Link to your target
target_link_libraries(mylib PUBLIC neutrino::failsafe)
```

## Installation

```cmake
if(NEUTRINO_MYLIB_INSTALL)
    neutrino_install_headers(mylib)
    neutrino_install_library(mylib
        NAMESPACE neutrino::
        DEPENDENCIES "find_dependency(failsafe)"
    )
endif()
```

## Build Commands

```bash
# Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build

# Test
ctest --test-dir build

# Install
cmake --install build --prefix /usr/local
```

## Next Steps

- [Options Module](modules/options.md) - Standardized build options
- [Warnings Module](modules/warnings.md) - Compiler warning configuration
- [Dependencies](dependencies/README.md) - Available dependency recipes
- [Creating a Library](creating-a-library.md) - Complete library template
