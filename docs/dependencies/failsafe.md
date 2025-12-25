# failsafe

Error handling and logging library.

## Target

`neutrino::failsafe`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)
neutrino_fetch_failsafe()

target_link_libraries(mylib PUBLIC neutrino::failsafe)
```

## Version

```cmake
set(NEUTRINO_FAILSAFE_VERSION "master" CACHE STRING "")
```

## Notes

- Header-only library
- Provides exception macros, enforce assertions, and logging
- Part of the Neutrino ecosystem

## Example

```cpp
#include <failsafe/enforce.hh>
#include <failsafe/exception.hh>

void process_data(const std::vector<int>& data) {
    // Enforce preconditions
    ENFORCE(!data.empty(), "Data cannot be empty");

    // Throw with context
    if (data[0] < 0) {
        THROW_EX("Invalid data: first element is negative", data[0]);
    }
}
```

## Links

- [failsafe GitHub](https://github.com/devbrain/failsafe)
