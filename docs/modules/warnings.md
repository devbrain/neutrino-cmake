# NeutrinoWarnings

Strict compiler warning flags for consistent, high-quality builds across MSVC, GCC, and Clang.

## Global Options

| Option | Default | Description |
|--------|---------|-------------|
| `NEUTRINO_WARNINGS_AS_ERRORS` | ON | Treat warnings as errors |

## Functions

### neutrino_target_warnings

Apply standard warning flags to a target:

```cmake
add_library(mylib src/mylib.cc)
neutrino_target_warnings(mylib)
```

With explicit visibility:

```cmake
neutrino_target_warnings(mylib PRIVATE)   # Compiled library
neutrino_target_warnings(mylib INTERFACE) # Header-only library
```

Visibility auto-detection:
- `INTERFACE` for interface libraries
- `PRIVATE` for compiled libraries

### neutrino_target_thread_safety

Enable Clang's thread safety analysis:

```cmake
neutrino_target_thread_safety(mylib)
```

Only affects Clang (not AppleClang). No effect on other compilers.

### neutrino_suppress_warnings

Suppress warnings for third-party code:

```cmake
neutrino_suppress_warnings(third_party_lib)
```

For interface libraries: marks includes as SYSTEM.
For compiled libraries: adds `-w` (GCC/Clang) or `/W0` (MSVC).

### neutrino_target_disable_specific_warnings

Disable specific warnings:

```cmake
neutrino_target_disable_specific_warnings(mylib
    4251        # MSVC: DLL interface warning
    sign-conversion  # GCC/Clang
)
```

MSVC warnings use numeric codes, GCC/Clang use names.

## Warning Flags

### MSVC

```
/W4                 Warning level 4 (very strict)
/permissive-        Strict standards conformance
/WX                 Warnings as errors (when enabled)
/w14242             Conversion with possible data loss
/w14263             Member function doesn't override base
/w14265             Non-virtual destructor with virtual functions
...and more
```

### GCC

```
-Wall -Wextra -Wpedantic
-Wshadow
-Wnon-virtual-dtor
-Wold-style-cast
-Wconversion
-Wsign-conversion
-Wduplicated-cond
-Wduplicated-branches
-Wlogical-op
-Wsuggest-override
-Werror (when enabled)
```

### Clang

```
-Wall -Wextra -Wpedantic
-Wshadow
-Wnon-virtual-dtor
-Wold-style-cast
-Wconversion
-Wsign-conversion
-Wmost
-Wno-c++98-compat
-Werror (when enabled)
```

## Variables

| Variable | Description |
|----------|-------------|
| `NEUTRINO_WARNINGS_MSVC` | MSVC warning flags list |
| `NEUTRINO_WARNINGS_GCC` | GCC warning flags list |
| `NEUTRINO_WARNINGS_CLANG` | Clang warning flags list |

## Example

```cmake
add_library(mylib src/mylib.cc)

# Apply strict warnings
neutrino_target_warnings(mylib)

# Enable thread safety analysis (Clang only)
neutrino_target_thread_safety(mylib)

# Disable specific warnings if needed
neutrino_target_disable_specific_warnings(mylib
    4251  # MSVC DLL export
)
```

## Disabling Warnings as Errors

For development or legacy code:

```bash
cmake -B build -DNEUTRINO_WARNINGS_AS_ERRORS=OFF
```
