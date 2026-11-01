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

The recipe pins a tested commit. Override it before including the recipe if needed:

```cmake
set(NEUTRINO_FAILSAFE_VERSION "master" CACHE STRING "")
```

## Enum and Type Names

Enum names are optional. Enable them before fetching Failsafe:

```cmake
set(NEUTRINO_FAILSAFE_USE_MAGIC_ENUM ON CACHE BOOL "")
include(${NEUTRINO_CMAKE_DIR}/deps/failsafe.cmake)
neutrino_fetch_failsafe()
```

This automatically adds [magic_enum](magic_enum.md) for enum formatting in
messages, enforcement errors, exceptions, and logs. The option defaults to OFF,
which formats enums as `(type_name:number)`, for example `(draw_style:0)`.

Compile-time type names need no option or extra dependency:

```cpp
#include <failsafe/type_name.hh>
static_assert(failsafe::type_name_v<int> == "int");
```

`failsafe::type_hash_v<T>` provides a CRC32 of the name. Names and hashes depend on
the compiler; hashes can collide and are not persistent type identifiers.

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
