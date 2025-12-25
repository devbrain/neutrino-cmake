# utf8cpp

UTF-8 string handling library.

## Target

`utf8cpp::utf8cpp`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/utf8cpp.cmake)
neutrino_fetch_utf8cpp()

target_link_libraries(mylib PRIVATE utf8cpp::utf8cpp)
```

## Version

```cmake
set(NEUTRINO_UTF8CPP_VERSION "4.0.5" CACHE STRING "")
```

## Notes

- Header-only library
- Provides UTF-8 validation, iteration, and conversion

## Example

```cpp
#include <utf8.h>
#include <string>

std::string input = "Hello, 世界!";

// Check if valid UTF-8
bool valid = utf8::is_valid(input.begin(), input.end());

// Iterate over code points
auto it = input.begin();
while (it != input.end()) {
    uint32_t cp = utf8::next(it, input.end());
    // process code point
}
```

## Links

- [utf8cpp GitHub](https://github.com/nemtrif/utfcpp)
