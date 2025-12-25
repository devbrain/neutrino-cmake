# datascript

Binary format parser generator for C++.

## Targets

| Target | Description |
|--------|-------------|
| `neutrino::datascript` | Runtime library |
| `ds` | Code generator executable |

## Usage

### Basic

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/datascript.cmake)
neutrino_fetch_datascript()

target_link_libraries(mylib PRIVATE neutrino::datascript)
```

### Code Generation

```cmake
neutrino_datascript_generate(
    TARGET mylib
    SCHEMAS
        ${CMAKE_CURRENT_SOURCE_DIR}/schemas/format.ds
    OUTPUT_DIR ${CMAKE_CURRENT_BINARY_DIR}/generated
    IMPORT_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/schemas
)
```

## Version

```cmake
set(NEUTRINO_DATASCRIPT_VERSION "master" CACHE STRING "")
```

## Code Generation Parameters

| Parameter | Description |
|-----------|-------------|
| `TARGET` | Target to add generated sources to |
| `SCHEMAS` | List of .ds schema files |
| `OUTPUT_DIR` | Directory for generated code |
| `IMPORT_DIRS` | Directories for schema imports |
| `INCLUDE_DIRS` | Additional include directories |

## Notes

- Generates C++ parsers from schema definitions
- Part of the Neutrino ecosystem
- Tests disabled when used as dependency

## Links

- [datascript GitHub](https://github.com/devbrain/datascript)
