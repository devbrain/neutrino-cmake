# =============================================================================
# NeutrinoSanitizers.cmake
# =============================================================================
# Runtime sanitizer support for the Neutrino ecosystem.
# Provides easy integration of ASan, UBSan, TSan, and MSan.
# =============================================================================

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# Sanitizer Availability Detection
# -----------------------------------------------------------------------------

# Sanitizers are not available on all platforms
set(NEUTRINO_SANITIZERS_AVAILABLE ON)

if(NEUTRINO_COMPILER_IS_MSVC)
    # MSVC has limited sanitizer support (ASan only, and only recent versions)
    if(MSVC_VERSION LESS 1928)  # VS 2019 16.8+
        set(NEUTRINO_SANITIZERS_AVAILABLE OFF)
    endif()
elseif(NEUTRINO_PLATFORM_EMSCRIPTEN)
    # Emscripten has limited sanitizer support
    set(NEUTRINO_SANITIZERS_AVAILABLE OFF)
endif()

# MSan is only available with Clang (not AppleClang)
set(NEUTRINO_MSAN_AVAILABLE OFF)
if(NEUTRINO_COMPILER_IS_CLANG AND NOT NEUTRINO_COMPILER_IS_APPLECLANG)
    set(NEUTRINO_MSAN_AVAILABLE ON)
endif()

# -----------------------------------------------------------------------------
# Sanitizer Options
# -----------------------------------------------------------------------------

cmake_dependent_option(NEUTRINO_ENABLE_ASAN
    "Enable Address Sanitizer (ASan)"
    OFF
    "NEUTRINO_SANITIZERS_AVAILABLE"
    OFF
)

cmake_dependent_option(NEUTRINO_ENABLE_UBSAN
    "Enable Undefined Behavior Sanitizer (UBSan)"
    OFF
    "NEUTRINO_SANITIZERS_AVAILABLE;NOT NEUTRINO_COMPILER_IS_MSVC"
    OFF
)

cmake_dependent_option(NEUTRINO_ENABLE_TSAN
    "Enable Thread Sanitizer (TSan)"
    OFF
    "NEUTRINO_SANITIZERS_AVAILABLE;NOT NEUTRINO_COMPILER_IS_MSVC"
    OFF
)

cmake_dependent_option(NEUTRINO_ENABLE_MSAN
    "Enable Memory Sanitizer (MSan) - Clang only"
    OFF
    "NEUTRINO_MSAN_AVAILABLE"
    OFF
)

# -----------------------------------------------------------------------------
# Sanitizer Conflict Detection
# -----------------------------------------------------------------------------

# ASan and TSan are incompatible
if(NEUTRINO_ENABLE_ASAN AND NEUTRINO_ENABLE_TSAN)
    message(FATAL_ERROR
        "[Neutrino] ASan and TSan cannot be enabled simultaneously. "
        "Please choose one or the other."
    )
endif()

# ASan and MSan are incompatible
if(NEUTRINO_ENABLE_ASAN AND NEUTRINO_ENABLE_MSAN)
    message(FATAL_ERROR
        "[Neutrino] ASan and MSan cannot be enabled simultaneously. "
        "Please choose one or the other."
    )
endif()

# TSan and MSan are incompatible
if(NEUTRINO_ENABLE_TSAN AND NEUTRINO_ENABLE_MSAN)
    message(FATAL_ERROR
        "[Neutrino] TSan and MSan cannot be enabled simultaneously. "
        "Please choose one or the other."
    )
endif()

# -----------------------------------------------------------------------------
# Sanitizer Flags
# -----------------------------------------------------------------------------

set(NEUTRINO_SANITIZER_COMPILE_FLAGS "")
set(NEUTRINO_SANITIZER_LINK_FLAGS "")

if(NEUTRINO_COMPILER_IS_MSVC)
    # MSVC sanitizer flags
    if(NEUTRINO_ENABLE_ASAN)
        list(APPEND NEUTRINO_SANITIZER_COMPILE_FLAGS /fsanitize=address)
        # MSVC ASan doesn't need special link flags
    endif()
else()
    # GCC/Clang sanitizer flags
    if(NEUTRINO_ENABLE_ASAN)
        list(APPEND NEUTRINO_SANITIZER_COMPILE_FLAGS
            -fsanitize=address
            -fno-omit-frame-pointer
        )
        list(APPEND NEUTRINO_SANITIZER_LINK_FLAGS -fsanitize=address)
    endif()

    if(NEUTRINO_ENABLE_UBSAN)
        list(APPEND NEUTRINO_SANITIZER_COMPILE_FLAGS
            -fsanitize=undefined
            -fno-omit-frame-pointer
        )
        list(APPEND NEUTRINO_SANITIZER_LINK_FLAGS -fsanitize=undefined)
    endif()

    if(NEUTRINO_ENABLE_TSAN)
        list(APPEND NEUTRINO_SANITIZER_COMPILE_FLAGS
            -fsanitize=thread
            -fno-omit-frame-pointer
        )
        list(APPEND NEUTRINO_SANITIZER_LINK_FLAGS -fsanitize=thread)
    endif()

    if(NEUTRINO_ENABLE_MSAN)
        list(APPEND NEUTRINO_SANITIZER_COMPILE_FLAGS
            -fsanitize=memory
            -fno-omit-frame-pointer
            -fsanitize-memory-track-origins=2
        )
        list(APPEND NEUTRINO_SANITIZER_LINK_FLAGS -fsanitize=memory)
    endif()
endif()

# -----------------------------------------------------------------------------
# Sanitizer Application Functions
# -----------------------------------------------------------------------------

#[=============================================================================[
neutrino_target_sanitizers(<target>)

Apply enabled sanitizers to a target.
Only applies to compiled (non-INTERFACE) libraries.
#]=============================================================================]
function(neutrino_target_sanitizers TARGET)
    # Skip if no sanitizers enabled
    if(NOT NEUTRINO_SANITIZER_COMPILE_FLAGS)
        return()
    endif()

    # Skip interface libraries
    get_target_property(_type ${TARGET} TYPE)
    if(_type STREQUAL "INTERFACE_LIBRARY")
        return()
    endif()

    target_compile_options(${TARGET} PRIVATE ${NEUTRINO_SANITIZER_COMPILE_FLAGS})
    target_link_options(${TARGET} PRIVATE ${NEUTRINO_SANITIZER_LINK_FLAGS})
endfunction()

#[=============================================================================[
neutrino_add_sanitizers_globally()

Apply enabled sanitizers to all targets in the current directory and below.
Call this at the top of your CMakeLists.txt to apply sanitizers globally.
#]=============================================================================]
function(neutrino_add_sanitizers_globally)
    if(NEUTRINO_SANITIZER_COMPILE_FLAGS)
        add_compile_options(${NEUTRINO_SANITIZER_COMPILE_FLAGS})
        add_link_options(${NEUTRINO_SANITIZER_LINK_FLAGS})
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Status Output
# -----------------------------------------------------------------------------

set(_sanitizers_enabled "")
if(NEUTRINO_ENABLE_ASAN)
    list(APPEND _sanitizers_enabled "ASan")
endif()
if(NEUTRINO_ENABLE_UBSAN)
    list(APPEND _sanitizers_enabled "UBSan")
endif()
if(NEUTRINO_ENABLE_TSAN)
    list(APPEND _sanitizers_enabled "TSan")
endif()
if(NEUTRINO_ENABLE_MSAN)
    list(APPEND _sanitizers_enabled "MSan")
endif()

if(_sanitizers_enabled)
    list(JOIN _sanitizers_enabled ", " _sanitizers_str)
    message(STATUS "[Neutrino] Sanitizers enabled: ${_sanitizers_str}")
endif()
unset(_sanitizers_enabled)
