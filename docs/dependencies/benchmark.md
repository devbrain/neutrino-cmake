# benchmark

Google Benchmark library.

## Target

`benchmark::benchmark`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/benchmark.cmake)
neutrino_fetch_benchmark()

add_executable(mybench bench/main.cc)
target_link_libraries(mybench PRIVATE benchmark::benchmark)
```

## Version

```cmake
set(NEUTRINO_BENCHMARK_VERSION "1.9.1" CACHE STRING "")
```

## Notes

- Compiled library
- Automatically built as static library
- Tests and documentation disabled

## Example

```cpp
#include <benchmark/benchmark.h>

static void BM_StringCreation(benchmark::State& state) {
    for (auto _ : state) {
        std::string s("hello");
        benchmark::DoNotOptimize(s);
    }
}
BENCHMARK(BM_StringCreation);

BENCHMARK_MAIN();
```

## Links

- [benchmark GitHub](https://github.com/google/benchmark)
