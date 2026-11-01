# magic_enum

Header-only enum reflection for C++17 and later.

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/magic_enum.cmake)
neutrino_fetch_magic_enum()

target_link_libraries(mylib PRIVATE magic_enum::magic_enum)
```

The recipe reuses an existing `magic_enum::magic_enum` target. Otherwise it fetches
the pinned release, disables upstream tests and examples, and enables installation
of the headers and CMake package for exported consumers.

## Version

```cmake
set(NEUTRINO_MAGIC_ENUM_VERSION "0.9.8" CACHE STRING "")
```

## Failsafe Integration

Failsafe's enum formatting is optional and defaults to OFF. Set
`NEUTRINO_FAILSAFE_USE_MAGIC_ENUM=ON` before adding Failsafe to enable enum names in
messages, enforcement errors, exceptions, and logs. Failsafe then fetches and links
this dependency automatically. Values without a reflected name use their underlying
integer; the default reflection range is -128 to 127.

## Links

- [magic_enum](https://github.com/Neargye/magic_enum)
- [Reflection range and limitations](https://github.com/Neargye/magic_enum/blob/v0.9.8/doc/limitations.md)
