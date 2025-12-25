# sdlpp

C++ wrapper library for SDL3.

## Target

`neutrino::sdlpp`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/sdlpp.cmake)
neutrino_fetch_sdlpp()

target_link_libraries(myapp PRIVATE neutrino::sdlpp)
```

## Version

```cmake
set(NEUTRINO_SDLPP_VERSION "main" CACHE STRING "")
```

## Notes

- Modern C++ interface for SDL3
- RAII wrappers for SDL resources
- Part of the Neutrino ecosystem
- Tests and examples disabled when used as dependency

## Links

- [lib_sdlpp GitHub](https://github.com/devbrain/lib_sdlpp)
