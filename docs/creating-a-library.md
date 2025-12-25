# Creating a Neutrino Library

Guide for creating a new library that integrates with the Neutrino CMake ecosystem.

## Project Structure

```
mylib/
├── CMakeLists.txt
├── cmake/
│   └── mylib-config.cmake.in    # For install support
├── include/
│   └── mylib/
│       └── mylib.hpp
├── src/
│   └── mylib.cpp
└── test/
    └── test_mylib.cpp
```

## Root CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.20)
project(mylib VERSION 1.0.0 LANGUAGES CXX)

# Bootstrap neutrino-cmake
include(FetchContent)
FetchContent_Declare(neutrino-cmake
    GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
    GIT_TAG main
)
FetchContent_MakeAvailable(neutrino-cmake)
set(NEUTRINO_CMAKE_DIR "${neutrino-cmake_SOURCE_DIR}/cmake")

# Include core modules
include(${NEUTRINO_CMAKE_DIR}/NeutrinoOptions.cmake)
include(${NEUTRINO_CMAKE_DIR}/NeutrinoWarnings.cmake)
include(${NEUTRINO_CMAKE_DIR}/NeutrinoCompiler.cmake)

# Define options
neutrino_options(
    PREFIX MYLIB
    CXX_STANDARD 20
)

# Create library
add_library(mylib
    src/mylib.cpp
)

add_library(mylib::mylib ALIAS mylib)

target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Apply warnings
neutrino_target_set_warnings(mylib)

# Tests (optional)
if(MYLIB_BUILD_TESTS)
    enable_testing()
    add_subdirectory(test)
endif()
```

## Header-Only Library

For header-only libraries, use INTERFACE:

```cmake
add_library(mylib INTERFACE)
add_library(mylib::mylib ALIAS mylib)

target_include_directories(mylib
    INTERFACE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
```

## Adding Dependencies

```cmake
# Include dependency recipes
include(${NEUTRINO_CMAKE_DIR}/deps/expected.cmake)
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)

# Fetch them
neutrino_fetch_expected()
neutrino_fetch_failsafe()

# Link to your library
target_link_libraries(mylib
    PUBLIC
        tl::expected
    PRIVATE
        neutrino::failsafe
)
```

## Test Setup

### test/CMakeLists.txt

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
neutrino_fetch_doctest()

add_executable(test_mylib test_mylib.cpp)

target_link_libraries(test_mylib
    PRIVATE
        mylib::mylib
        doctest::doctest
)

add_test(NAME test_mylib COMMAND test_mylib)
```

### test/test_mylib.cpp

```cpp
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

#include <mylib/mylib.hpp>

TEST_CASE("basic test") {
    CHECK(true);
}
```

## Install Support

Add to root CMakeLists.txt:

```cmake
include(${NEUTRINO_CMAKE_DIR}/NeutrinoInstall.cmake)

neutrino_install_library(
    TARGET mylib
    NAMESPACE mylib
    EXPORT_NAME mylib
    VERSION ${PROJECT_VERSION}
)
```

## Standard Options

The `neutrino_options()` function creates these cache variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `${PREFIX}_BUILD_TESTS` | ON (standalone) | Build tests |
| `${PREFIX}_BUILD_EXAMPLES` | ON (standalone) | Build examples |
| `${PREFIX}_CXX_STANDARD` | 20 | C++ standard |
| `${PREFIX}_ENABLE_LTO` | OFF | Link-time optimization |
| `${PREFIX}_ENABLE_SANITIZERS` | OFF | Address/UB sanitizers |

## GitHub CI Integration

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        build_type: [Debug, Release]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Configure
        run: cmake -B build -DCMAKE_BUILD_TYPE=${{ matrix.build_type }}

      - name: Build
        run: cmake --build build --config ${{ matrix.build_type }}

      - name: Test
        run: ctest --test-dir build -C ${{ matrix.build_type }} --output-on-failure
```

## Creating a Dependency Recipe

To add your library as a neutrino-cmake dependency recipe, create `cmake/deps/mylib.cmake`:

```cmake
include_guard(GLOBAL)

set(NEUTRINO_MYLIB_VERSION "main" CACHE STRING "mylib version/tag")

function(neutrino_fetch_mylib)
    if(TARGET neutrino::mylib OR TARGET mylib::mylib)
        message(STATUS "[Neutrino] mylib already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching mylib...")

    include(FetchContent)

    FetchContent_Declare(mylib
        GIT_REPOSITORY https://github.com/devbrain/mylib.git
        GIT_TAG ${NEUTRINO_MYLIB_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable tests when used as dependency
    set(MYLIB_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(MYLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    FetchContent_MakeAvailable(mylib)

    # Create neutrino:: alias
    if(TARGET mylib AND NOT TARGET neutrino::mylib)
        add_library(neutrino::mylib ALIAS mylib)
    endif()
endfunction()
```
