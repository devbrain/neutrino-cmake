# SDL2

Simple DirectMedia Layer 2.

## Target

`SDL2::SDL2`

## Usage

```cmake
include(${NEUTRINO_CMAKE_DIR}/deps/SDL2.cmake)
neutrino_fetch_SDL2()

target_link_libraries(myapp PRIVATE SDL2::SDL2)
```

### Static/Shared Selection

```cmake
neutrino_fetch_SDL2(STATIC)  # Force static linking
neutrino_fetch_SDL2(SHARED)  # Force shared linking
```

## Version

```cmake
set(NEUTRINO_SDL2_VERSION "2.30.0" CACHE STRING "")
```

## Notes

- Tries system package first via find_package
- Falls back to FetchContent if not found
- Built as static library by default
- Patches cmake_minimum_required for CMake 4.x compatibility

## Example

```cpp
#include <SDL2/SDL.h>

int main(int argc, char* argv[]) {
    SDL_Init(SDL_INIT_VIDEO);

    SDL_Window* window = SDL_CreateWindow(
        "Hello SDL2",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        800, 600,
        SDL_WINDOW_SHOWN
    );

    SDL_Delay(3000);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
```

## Links

- [SDL2 GitHub](https://github.com/libsdl-org/SDL/tree/SDL2)
- [SDL2 Documentation](https://wiki.libsdl.org/)
