# mio

Memory-mapped I/O library.

## Target

`neutrino::mio`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/mio.cmake)
neutrino_fetch_mio()

target_link_libraries(mylib PRIVATE neutrino::mio)
```

## Version

```cmake
set(NEUTRINO_MIO_VERSION "master" CACHE STRING "")
```

## Notes

- Header-only library
- Cross-platform memory-mapped file access
- Part of the Neutrino ecosystem

## Example

```cpp
#include <mio/mmap.hpp>

void read_file(const std::string& path) {
    mio::mmap_source file(path);

    // Access file contents as memory
    const char* data = file.data();
    size_t size = file.size();

    // Process data...
}
```

## Links

- [mio GitHub](https://github.com/devbrain/mio)
