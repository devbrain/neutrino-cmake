# =============================================================================
# imgui.cmake - Dear ImGui with backend support
# =============================================================================
# Targets:
#   imgui::imgui           - Core ImGui library
#   imgui::backend_sdl2    - SDL2 platform backend
#   imgui::backend_sdl3    - SDL3 platform backend
#   imgui::backend_opengl3 - OpenGL3 renderer backend
#   imgui::backend_vulkan  - Vulkan renderer backend
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_IMGUI_VERSION "1.91.6" CACHE STRING "Dear ImGui version")

# Backend selection options
option(NEUTRINO_IMGUI_BACKEND_SDL2 "Include SDL2 platform backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_SDL3 "Include SDL3 platform backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_GLFW "Include GLFW platform backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_OPENGL3 "Include OpenGL3 renderer backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_VULKAN "Include Vulkan renderer backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_SDLRENDERER2 "Include SDL2 Renderer backend" OFF)
option(NEUTRINO_IMGUI_BACKEND_SDLRENDERER3 "Include SDL3 Renderer backend" OFF)

function(neutrino_fetch_imgui)
    if(TARGET imgui::imgui)
        message(STATUS "[Neutrino] imgui already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching Dear ImGui ${NEUTRINO_IMGUI_VERSION}...")

    include(FetchContent)

    FetchContent_Declare(imgui
        GIT_REPOSITORY https://github.com/ocornut/imgui.git
        GIT_TAG v${NEUTRINO_IMGUI_VERSION}
        GIT_SHALLOW TRUE
    )

    FetchContent_MakeAvailable(imgui)

    # Create core imgui library
    add_library(imgui STATIC
        ${imgui_SOURCE_DIR}/imgui.cpp
        ${imgui_SOURCE_DIR}/imgui_demo.cpp
        ${imgui_SOURCE_DIR}/imgui_draw.cpp
        ${imgui_SOURCE_DIR}/imgui_tables.cpp
        ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    )

    target_include_directories(imgui PUBLIC
        $<BUILD_INTERFACE:${imgui_SOURCE_DIR}>
    )

    add_library(imgui::imgui ALIAS imgui)

    # Suppress warnings for third-party imgui code
    neutrino_suppress_warnings(imgui)

    # SDL2 backend
    if(NEUTRINO_IMGUI_BACKEND_SDL2)
        add_library(imgui_backend_sdl2 STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdl2.cpp
        )
        target_include_directories(imgui_backend_sdl2 PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_sdl2 PUBLIC imgui SDL2::SDL2)
        add_library(imgui::backend_sdl2 ALIAS imgui_backend_sdl2)
        neutrino_suppress_warnings(imgui_backend_sdl2)
    endif()

    # SDL3 backend
    if(NEUTRINO_IMGUI_BACKEND_SDL3)
        add_library(imgui_backend_sdl3 STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdl3.cpp
        )
        target_include_directories(imgui_backend_sdl3 PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_sdl3 PUBLIC imgui SDL3::SDL3)
        add_library(imgui::backend_sdl3 ALIAS imgui_backend_sdl3)
        neutrino_suppress_warnings(imgui_backend_sdl3)
    endif()

    # OpenGL3 backend
    if(NEUTRINO_IMGUI_BACKEND_OPENGL3)
        add_library(imgui_backend_opengl3 STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_opengl3.cpp
        )
        target_include_directories(imgui_backend_opengl3 PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_opengl3 PUBLIC imgui)
        add_library(imgui::backend_opengl3 ALIAS imgui_backend_opengl3)
        neutrino_suppress_warnings(imgui_backend_opengl3)
    endif()

    # Vulkan backend
    if(NEUTRINO_IMGUI_BACKEND_VULKAN)
        find_package(Vulkan REQUIRED)
        add_library(imgui_backend_vulkan STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_vulkan.cpp
        )
        target_include_directories(imgui_backend_vulkan PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_vulkan PUBLIC imgui Vulkan::Vulkan)
        add_library(imgui::backend_vulkan ALIAS imgui_backend_vulkan)
        neutrino_suppress_warnings(imgui_backend_vulkan)
    endif()

    # SDL2 Renderer backend
    if(NEUTRINO_IMGUI_BACKEND_SDLRENDERER2)
        add_library(imgui_backend_sdlrenderer2 STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdlrenderer2.cpp
        )
        target_include_directories(imgui_backend_sdlrenderer2 PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_sdlrenderer2 PUBLIC imgui SDL2::SDL2)
        add_library(imgui::backend_sdlrenderer2 ALIAS imgui_backend_sdlrenderer2)
        neutrino_suppress_warnings(imgui_backend_sdlrenderer2)
    endif()

    # SDL3 Renderer backend
    if(NEUTRINO_IMGUI_BACKEND_SDLRENDERER3)
        add_library(imgui_backend_sdlrenderer3 STATIC
            ${imgui_SOURCE_DIR}/backends/imgui_impl_sdlrenderer3.cpp
        )
        target_include_directories(imgui_backend_sdlrenderer3 PUBLIC
            $<BUILD_INTERFACE:${imgui_SOURCE_DIR}/backends>
        )
        target_link_libraries(imgui_backend_sdlrenderer3 PUBLIC imgui SDL3::SDL3)
        add_library(imgui::backend_sdlrenderer3 ALIAS imgui_backend_sdlrenderer3)
        neutrino_suppress_warnings(imgui_backend_sdlrenderer3)
    endif()
endfunction()

# Convenience functions for common configurations

function(neutrino_fetch_imgui_sdl2_opengl3)
    set(NEUTRINO_IMGUI_BACKEND_SDL2 ON CACHE BOOL "" FORCE)
    set(NEUTRINO_IMGUI_BACKEND_OPENGL3 ON CACHE BOOL "" FORCE)
    neutrino_fetch_SDL2()
    neutrino_fetch_imgui()
endfunction()

function(neutrino_fetch_imgui_sdl3_opengl3)
    set(NEUTRINO_IMGUI_BACKEND_SDL3 ON CACHE BOOL "" FORCE)
    set(NEUTRINO_IMGUI_BACKEND_OPENGL3 ON CACHE BOOL "" FORCE)
    neutrino_fetch_SDL3()
    neutrino_fetch_imgui()
endfunction()

function(neutrino_fetch_imgui_sdl2_renderer)
    set(NEUTRINO_IMGUI_BACKEND_SDL2 ON CACHE BOOL "" FORCE)
    set(NEUTRINO_IMGUI_BACKEND_SDLRENDERER2 ON CACHE BOOL "" FORCE)
    neutrino_fetch_SDL2()
    neutrino_fetch_imgui()
endfunction()

function(neutrino_fetch_imgui_sdl3_renderer)
    set(NEUTRINO_IMGUI_BACKEND_SDL3 ON CACHE BOOL "" FORCE)
    set(NEUTRINO_IMGUI_BACKEND_SDLRENDERER3 ON CACHE BOOL "" FORCE)
    neutrino_fetch_SDL3()
    neutrino_fetch_imgui()
endfunction()
