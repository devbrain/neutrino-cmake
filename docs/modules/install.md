# NeutrinoInstall

Installation helpers for package configuration and export.

## Functions

### neutrino_install_headers

Install header files:

```cmake
neutrino_install_headers(mylib)
```

Options:

| Argument | Default | Description |
|----------|---------|-------------|
| `DIRECTORY` | `${PROJECT_SOURCE_DIR}/include` | Source directory |
| `DESTINATION` | `${CMAKE_INSTALL_INCLUDEDIR}` | Install destination |
| `PATTERN` | `*.h *.hh *.hpp` | File patterns |

Example with custom directory:

```cmake
neutrino_install_headers(mylib
    DIRECTORY "${PROJECT_SOURCE_DIR}/src/include"
    PATTERN "*.hh"
)
```

### neutrino_install_library

Install library with package config files:

```cmake
neutrino_install_library(mylib)
```

Options:

| Argument | Default | Description |
|----------|---------|-------------|
| `NAMESPACE` | `neutrino::` | CMake namespace |
| `COMPATIBILITY` | `SameMajorVersion` | Version compatibility |
| `EXPORT_NAME` | `${target}Targets` | Export file name |
| `DEPENDENCIES` | (none) | find_dependency() calls |
| `CONFIG_TEMPLATE` | (auto-generated) | Custom Config.cmake.in |

Example with dependencies:

```cmake
neutrino_install_library(mylib
    NAMESPACE neutrino::
    DEPENDENCIES
        "find_dependency(failsafe)"
        "find_dependency(Threads)"
)
```

### neutrino_install_package_files

Install additional package files:

```cmake
neutrino_install_package_files(mylib
    FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/cmake/FindFoo.cmake"
)
```

### neutrino_export_for_build_tree

Export target for FetchContent consumers (no installation):

```cmake
neutrino_export_for_build_tree(mylib)
```

This allows the library to be used directly from the build tree without installing.

## Complete Installation Example

```cmake
if(NEUTRINO_MYLIB_INSTALL)
    include(GNUInstallDirs)

    # Install headers
    neutrino_install_headers(mylib)

    # Install library with config files
    neutrino_install_library(mylib
        NAMESPACE neutrino::
        COMPATIBILITY SameMajorVersion
        DEPENDENCIES
            "find_dependency(failsafe)"
    )
endif()

# Always export for build tree (FetchContent)
neutrino_export_for_build_tree(mylib)
```

## Generated Files

After installation, these files are created:

```
lib/
  cmake/
    mylib/
      mylibConfig.cmake
      mylibConfigVersion.cmake
      mylibTargets.cmake
```

## Consumer Usage

After installation:

```cmake
find_package(mylib REQUIRED)
target_link_libraries(app PRIVATE neutrino::mylib)
```

Via FetchContent:

```cmake
FetchContent_Declare(mylib
    GIT_REPOSITORY https://github.com/devbrain/mylib.git
    GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(mylib)
target_link_libraries(app PRIVATE neutrino::mylib)
```
