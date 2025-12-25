# scaler

Image scaling library with pixel art algorithms.

## Target

`neutrino::scaler`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/scaler.cmake)
neutrino_fetch_scaler()

target_link_libraries(mylib PRIVATE neutrino::scaler)
```

## Version

```cmake
set(NEUTRINO_SCALER_VERSION "main" CACHE STRING "")
```

## Notes

- Implements various scaling algorithms (Scale2x, HQx, etc.)
- Part of the Neutrino ecosystem
- Tests and examples disabled when used as dependency

## Links

- [scaler GitHub](https://github.com/devbrain/scaler)
