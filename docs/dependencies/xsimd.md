# xsimd

SIMD abstraction library.

## Target

`xsimd::xsimd`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/xsimd.cmake)
neutrino_fetch_xsimd()

target_link_libraries(mylib PRIVATE xsimd::xsimd)
```

## Version

```cmake
set(NEUTRINO_XSIMD_VERSION "13.0.0" CACHE STRING "")
```

## Notes

- Header-only library
- Provides portable SIMD operations (SSE, AVX, NEON, etc.)
- Automatic architecture detection

## Example

```cpp
#include <xsimd/xsimd.hpp>

namespace xs = xsimd;

void add_arrays(float* a, const float* b, size_t n) {
    using batch = xs::batch<float>;
    size_t vec_size = batch::size;

    size_t i = 0;
    for (; i + vec_size <= n; i += vec_size) {
        auto va = xs::load_unaligned(a + i);
        auto vb = xs::load_unaligned(b + i);
        xs::store_unaligned(a + i, va + vb);
    }

    // Handle remainder
    for (; i < n; ++i) {
        a[i] += b[i];
    }
}
```

## Links

- [xsimd GitHub](https://github.com/xtensor-stack/xsimd)
