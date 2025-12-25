# expected

std::expected backport for C++11/14/17.

## Target

`tl::expected`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/expected.cmake)
neutrino_fetch_expected()

target_link_libraries(mylib PRIVATE tl::expected)
```

## Version

```cmake
set(NEUTRINO_EXPECTED_VERSION "1.1.0" CACHE STRING "")
```

## Notes

- Header-only library
- Provides `tl::expected<T, E>` for error handling
- Similar to C++23 `std::expected`

## Example

```cpp
#include <tl/expected.hpp>

tl::expected<int, std::string> parse_int(const std::string& s) {
    try {
        return std::stoi(s);
    } catch (...) {
        return tl::unexpected("Invalid integer: " + s);
    }
}

auto result = parse_int("42");
if (result) {
    std::cout << "Value: " << *result << "\n";
} else {
    std::cout << "Error: " << result.error() << "\n";
}
```

## Links

- [expected GitHub](https://github.com/TartanLlama/expected)
