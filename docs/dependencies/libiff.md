# libiff

IFF file format library for parsing Interchange File Format files.

## Target

`neutrino::iff`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/libiff.cmake)
neutrino_fetch_libiff()

target_link_libraries(mylib PRIVATE neutrino::iff)
```

## Version

```cmake
set(NEUTRINO_LIBIFF_VERSION "master" CACHE STRING "")
```

## Notes

- Supports IFF, RIFF, and related formats
- Part of the Neutrino ecosystem
- Tests and examples disabled when used as dependency

## Example

```cpp
#include <iff/reader.hh>

void read_iff_file(const std::string& path) {
    iff::reader reader(path);

    for (const auto& chunk : reader) {
        // Process chunks...
    }
}
```

## Links

- [libiff GitHub](https://github.com/devbrain/libiff)
