# NeutrinoOptions

Standardized option definitions for Neutrino ecosystem components.

## Naming Convention

All options follow the pattern:
```
NEUTRINO_<COMPONENT>_<CATEGORY>_<OPTION>
```

Categories:
- `BUILD_*` - What to build (tests, examples, docs, benchmarks)
- `ENABLE_*` - Feature toggles
- `USE_*` - Dependency selection
- `INSTALL` - Installation toggle

## Functions

### neutrino_define_options

Define standard options for any component:

```cmake
neutrino_define_options(mylib)
```

Creates these options:

| Option | Default (top-level) | Default (subproject) |
|--------|--------------------|--------------------|
| `NEUTRINO_MYLIB_BUILD_TESTS` | ON | OFF |
| `NEUTRINO_MYLIB_BUILD_EXAMPLES` | ON | OFF |
| `NEUTRINO_MYLIB_BUILD_BENCHMARKS` | OFF | OFF |
| `NEUTRINO_MYLIB_BUILD_DOCS` | OFF | OFF |
| `NEUTRINO_MYLIB_INSTALL` | ON | OFF |

All `BUILD_*` options are automatically OFF when cross-compiling.

### neutrino_define_library_options

For compiled (non-header-only) libraries. Includes all standard options plus:

```cmake
neutrino_define_library_options(mylib)
```

Additional option:

| Option | Default |
|--------|---------|
| `NEUTRINO_MYLIB_BUILD_SHARED` | OFF (or `BUILD_SHARED_LIBS` if set) |

### neutrino_define_host_tools_option

For projects with code generators that run on the build machine:

```cmake
neutrino_define_host_tools_option(datascript)
```

Creates:
- `NEUTRINO_DATASCRIPT_BUILD_HOST_TOOLS` - Always available, even when cross-compiling

### neutrino_define_runtime_tools_option

For tools that run on the target platform:

```cmake
neutrino_define_runtime_tools_option(mylib)
```

Creates:
- `NEUTRINO_MYLIB_BUILD_TOOLS` - Automatically OFF when cross-compiling

## Utility Functions

### neutrino_is_top_level

Check if the calling project is the top-level project:

```cmake
neutrino_is_top_level(IS_TOP)
if(IS_TOP)
    message(STATUS "Building as top-level project")
endif()
```

### neutrino_print_options

Print current option values:

```cmake
neutrino_print_options(mylib)
```

Output:
```
mylib configuration:
  Build tests:      ON
  Build examples:   ON
  Build benchmarks: OFF
  Build docs:       OFF
  Install:          ON
```

### neutrino_library_type

Get SHARED or STATIC based on options:

```cmake
neutrino_library_type(mylib LIB_TYPE)
add_library(mylib ${LIB_TYPE} src/mylib.cc)
```

## Variables

| Variable | Description |
|----------|-------------|
| `NEUTRINO_RUNTIME_TOOLS_AVAILABLE` | OFF when cross-compiling |
| `NEUTRINO_HOST_TOOLS_AVAILABLE` | Always ON |

## Example

```cmake
cmake_minimum_required(VERSION 3.20)
project(mylib VERSION 1.0.0 LANGUAGES CXX)

# ... neutrino-cmake setup ...

neutrino_define_library_options(mylib)
neutrino_print_options(mylib)

neutrino_library_type(mylib LIB_TYPE)
add_library(mylib ${LIB_TYPE} src/mylib.cc)

if(NEUTRINO_MYLIB_BUILD_TESTS)
    add_subdirectory(test)
endif()

if(NEUTRINO_MYLIB_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
```
