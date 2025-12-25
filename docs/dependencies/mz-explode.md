# mz-explode

MZ executable decompression library for DOS executables.

## Target

`neutrino::mzexplode`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/mz-explode.cmake)
neutrino_fetch_mzexplode()

target_link_libraries(mylib PRIVATE neutrino::mzexplode)
```

## Version

```cmake
set(NEUTRINO_MZEXPLODE_VERSION "master" CACHE STRING "")
```

## Notes

- Decompresses LZEXE, PKLITE, and other packed DOS executables
- Part of the Neutrino ecosystem
- Tests and tools disabled when used as dependency

## Links

- [mz-explode GitHub](https://github.com/devbrain/mz-explode)
