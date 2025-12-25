# NeutrinoSanitizers

Runtime sanitizer support for detecting memory errors, undefined behavior, data races, and more.

## Available Sanitizers

| Option | Description | Compilers |
|--------|-------------|-----------|
| `NEUTRINO_ENABLE_ASAN` | Address Sanitizer | GCC, Clang, MSVC 2019+ |
| `NEUTRINO_ENABLE_UBSAN` | Undefined Behavior Sanitizer | GCC, Clang |
| `NEUTRINO_ENABLE_TSAN` | Thread Sanitizer | GCC, Clang |
| `NEUTRINO_ENABLE_MSAN` | Memory Sanitizer | Clang only |

## Usage

### Command Line

```bash
# Enable ASan
cmake -B build -DNEUTRINO_ENABLE_ASAN=ON

# Enable ASan + UBSan (common combination)
cmake -B build -DNEUTRINO_ENABLE_ASAN=ON -DNEUTRINO_ENABLE_UBSAN=ON
```

### Per-Target

```cmake
add_executable(myapp main.cc)
neutrino_target_sanitizers(myapp)
```

### Global

Apply to all targets:

```cmake
neutrino_add_sanitizers_globally()
```

## Compatibility

### Incompatible Combinations

These sanitizers cannot be used together:
- ASan + TSan
- ASan + MSan
- TSan + MSan

CMake will error if incompatible sanitizers are enabled.

### Platform Support

| Platform | ASan | UBSan | TSan | MSan |
|----------|------|-------|------|------|
| Linux GCC | Yes | Yes | Yes | No |
| Linux Clang | Yes | Yes | Yes | Yes |
| macOS | Yes | Yes | Yes | No |
| Windows MSVC | Yes* | No | No | No |
| Windows clang-cl | Yes | Yes | Yes | No |
| Emscripten | No | No | No | No |

*MSVC 2019 16.8 or later required

## Variables

| Variable | Description |
|----------|-------------|
| `NEUTRINO_SANITIZERS_AVAILABLE` | ON if any sanitizer is supported |
| `NEUTRINO_MSAN_AVAILABLE` | ON if MSan is supported (Clang only) |
| `NEUTRINO_SANITIZER_COMPILE_FLAGS` | Compile flags for enabled sanitizers |
| `NEUTRINO_SANITIZER_LINK_FLAGS` | Link flags for enabled sanitizers |

## Tips

### Debug Builds

Sanitizers work best with debug builds:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug -DNEUTRINO_ENABLE_ASAN=ON
```

### CI Integration

Example GitHub Actions workflow:

```yaml
jobs:
  sanitizers:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        sanitizer: [ASAN, UBSAN, TSAN]
    steps:
      - uses: actions/checkout@v4
      - name: Configure
        run: cmake -B build -DNEUTRINO_ENABLE_${{ matrix.sanitizer }}=ON
      - name: Build
        run: cmake --build build
      - name: Test
        run: ctest --test-dir build
```

### Suppression Files

For ASan false positives, create a suppression file:

```bash
export ASAN_OPTIONS=suppressions=asan_suppressions.txt
```

## Example

```cmake
# Define options
neutrino_define_options(mylib)

# Create library
add_library(mylib src/mylib.cc)
neutrino_target_warnings(mylib)
neutrino_target_sanitizers(mylib)

# Tests with sanitizers
if(NEUTRINO_MYLIB_BUILD_TESTS)
    add_executable(mylib_test test/main.cc)
    target_link_libraries(mylib_test PRIVATE mylib)
    neutrino_target_sanitizers(mylib_test)
endif()
```
