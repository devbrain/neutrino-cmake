# euler

Line rasterization library using Bresenham's algorithm.

## Target

`neutrino::euler`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/euler.cmake)
neutrino_fetch_euler()

target_link_libraries(mylib PRIVATE neutrino::euler)
```

## Version

```cmake
set(NEUTRINO_EULER_VERSION "master" CACHE STRING "")
```

## Notes

- Header-only library
- Provides integer line rasterization
- Optional SIMD acceleration via xsimd
- Part of the Neutrino ecosystem

## Example

```cpp
#include <euler/line.hh>

void draw_line(int x0, int y0, int x1, int y1) {
    euler::line(x0, y0, x1, y1, [](int x, int y) {
        set_pixel(x, y);
    });
}
```

## Links

- [euler GitHub](https://github.com/devbrain/euler)
