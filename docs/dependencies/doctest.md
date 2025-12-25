# doctest

Lightweight C++ testing framework.

## Target

`doctest::doctest`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/doctest.cmake)
neutrino_fetch_doctest()

add_executable(mytest test/main.cc)
target_link_libraries(mytest PRIVATE doctest::doctest)
```

## Version

```cmake
set(NEUTRINO_DOCTEST_VERSION "2.4.11" CACHE STRING "")
```

## Notes

- Header-only library
- Downloads single header from GitHub releases
- No CMakeLists.txt processing required

## Example Test

```cpp
#include <doctest/doctest.h>

TEST_CASE("example test") {
    CHECK(1 + 1 == 2);
}
```

## Links

- [doctest GitHub](https://github.com/doctest/doctest)
- [Documentation](https://github.com/doctest/doctest/blob/master/doc/markdown/readme.md)
