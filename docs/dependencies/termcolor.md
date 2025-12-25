# termcolor

Terminal color output library.

## Target

`termcolor::termcolor`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/termcolor.cmake)
neutrino_fetch_termcolor()

target_link_libraries(mylib PRIVATE termcolor::termcolor)
```

## Version

```cmake
set(NEUTRINO_TERMCOLOR_VERSION "2.1.0" CACHE STRING "")
```

## Notes

- Header-only library
- Downloads single header from GitHub

## Example

```cpp
#include <termcolor/termcolor.hpp>
#include <iostream>

int main() {
    std::cout << termcolor::red << "Error: " << termcolor::reset
              << "Something went wrong\n";
    std::cout << termcolor::green << "Success!" << termcolor::reset << "\n";
}
```

## Links

- [termcolor GitHub](https://github.com/ikalnytskyi/termcolor)
