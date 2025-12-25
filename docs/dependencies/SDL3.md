# SDL3

Simple DirectMedia Layer 3.

## Target

`SDL3::SDL3`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/SDL3.cmake)
neutrino_fetch_SDL3()

target_link_libraries(myapp PRIVATE SDL3::SDL3)
```

### Static/Shared Selection

```cmake
neutrino_fetch_SDL3(STATIC)  # Force static linking
neutrino_fetch_SDL3(SHARED)  # Force shared linking
```

## Version

```cmake
set(NEUTRINO_SDL3_VERSION "3.2.8" CACHE STRING "")
```

## Notes

- Tries system package first via find_package
- Falls back to FetchContent if not found
- Built as static library by default

## Example

```cpp
#include <SDL3/SDL.h>

int main(int argc, char* argv[]) {
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window* window = SDL_CreateWindow(
        "Hello SDL3",
        800, 600,
        SDL_WINDOW_RESIZABLE
    );

    SDL_Delay(3000);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

## Links

- [SDL3 GitHub](https://github.com/libsdl-org/SDL)
- [SDL3 Documentation](https://wiki.libsdl.org/SDL3)
