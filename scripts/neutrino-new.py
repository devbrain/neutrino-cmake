#!/usr/bin/env python3
"""
neutrino-new - Generate a new neutrino ecosystem project skeleton

Usage:
    neutrino-new <project_name> [options]

Examples:
    neutrino-new mylib --type=header-only --std=17
    neutrino-new myapp --type=executable --std=20
    neutrino-new mylib --type=compiled --with-tests --with-examples
"""

import argparse
import os
import sys
from pathlib import Path
from datetime import datetime

# =============================================================================
# Templates
# =============================================================================

TEMPLATES = {}

# -----------------------------------------------------------------------------
# CMakeLists.txt Templates
# -----------------------------------------------------------------------------

TEMPLATES["CMakeLists.txt.header_only"] = '''\
cmake_minimum_required(VERSION 3.20)

project({project_name}
    VERSION 0.1.0
    DESCRIPTION "{description}"
    LANGUAGES CXX
)

# ============================================================================
# Neutrino CMake Integration
# ============================================================================

include(FetchContent)

if(NOT DEFINED NEUTRINO_CMAKE_DIR)
    FetchContent_Declare(neutrino_cmake
        GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
        GIT_TAG master
        GIT_SHALLOW TRUE
    )
    FetchContent_MakeAvailable(neutrino_cmake)
    set(NEUTRINO_CMAKE_DIR "${{neutrino_cmake_SOURCE_DIR}}/cmake")
    list(APPEND CMAKE_MODULE_PATH "${{NEUTRINO_CMAKE_DIR}}")
endif()

include(NeutrinoInit)

# ============================================================================
# Options
# ============================================================================

neutrino_define_options({project_name})

# ============================================================================
# Dependencies
# ============================================================================
{dependencies}
# ============================================================================
# Library Target
# ============================================================================

add_library({project_name} INTERFACE)
add_library(neutrino::{project_name} ALIAS {project_name})

target_compile_features({project_name} INTERFACE cxx_std_{std})

target_include_directories({project_name} INTERFACE
    $<BUILD_INTERFACE:${{CMAKE_CURRENT_SOURCE_DIR}}/include>
    $<INSTALL_INTERFACE:${{CMAKE_INSTALL_INCLUDEDIR}}>
)
{link_libraries}
# ============================================================================
# Warnings (for tests/examples only - header-only libs don't compile)
# ============================================================================

# ============================================================================
# Tests
# ============================================================================

if(NEUTRINO_{project_name_upper}_BUILD_TESTS)
    include(${{NEUTRINO_CMAKE_DIR}}/deps/doctest.cmake)
    neutrino_fetch_doctest()

    enable_testing()
    add_subdirectory(test)
endif()

# ============================================================================
# Examples
# ============================================================================

if(NEUTRINO_{project_name_upper}_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# ============================================================================
# Installation
# ============================================================================

if(NEUTRINO_{project_name_upper}_INSTALL)
    include(NeutrinoInstall)

    neutrino_install_headers({project_name})
    neutrino_install_library({project_name}
        NAMESPACE neutrino::
        COMPATIBILITY SameMajorVersion
{install_dependencies}    )
endif()

# ============================================================================
# Summary
# ============================================================================

neutrino_is_top_level(_is_top_level)
if(_is_top_level)
    neutrino_print_options({project_name})
endif()
'''

TEMPLATES["CMakeLists.txt.compiled"] = '''\
cmake_minimum_required(VERSION 3.20)

project({project_name}
    VERSION 0.1.0
    DESCRIPTION "{description}"
    LANGUAGES CXX
)

# ============================================================================
# Neutrino CMake Integration
# ============================================================================

include(FetchContent)
include(GenerateExportHeader)

if(NOT DEFINED NEUTRINO_CMAKE_DIR)
    FetchContent_Declare(neutrino_cmake
        GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
        GIT_TAG master
        GIT_SHALLOW TRUE
    )
    FetchContent_MakeAvailable(neutrino_cmake)
    set(NEUTRINO_CMAKE_DIR "${{neutrino_cmake_SOURCE_DIR}}/cmake")
    list(APPEND CMAKE_MODULE_PATH "${{NEUTRINO_CMAKE_DIR}}")
endif()

include(NeutrinoInit)

# ============================================================================
# Options
# ============================================================================

neutrino_define_library_options({project_name})

# ============================================================================
# Dependencies
# ============================================================================
{dependencies}
# ============================================================================
# Library Target
# ============================================================================

neutrino_library_type({project_name} _lib_type)

add_library({project_name} ${{_lib_type}}
    src/{project_name}.cpp
)
add_library(neutrino::{project_name} ALIAS {project_name})

target_compile_features({project_name} PUBLIC cxx_std_{std})

target_include_directories({project_name}
    PUBLIC
        $<BUILD_INTERFACE:${{CMAKE_CURRENT_SOURCE_DIR}}/include>
        $<BUILD_INTERFACE:${{CMAKE_CURRENT_BINARY_DIR}}/include>
        $<INSTALL_INTERFACE:${{CMAKE_INSTALL_INCLUDEDIR}}>
)
{link_libraries}
# Generate export header
generate_export_header({project_name}
    BASE_NAME {project_name}
    EXPORT_FILE_NAME ${{CMAKE_CURRENT_BINARY_DIR}}/include/{project_name}/{project_name}_export.h
)

# ============================================================================
# Compiler Warnings
# ============================================================================

neutrino_target_warnings({project_name})
neutrino_target_sanitizers({project_name})

# ============================================================================
# Tests
# ============================================================================

if(NEUTRINO_{project_name_upper}_BUILD_TESTS)
    include(${{NEUTRINO_CMAKE_DIR}}/deps/doctest.cmake)
    neutrino_fetch_doctest()

    enable_testing()
    add_subdirectory(test)
endif()

# ============================================================================
# Examples
# ============================================================================

if(NEUTRINO_{project_name_upper}_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

# ============================================================================
# Installation
# ============================================================================

if(NEUTRINO_{project_name_upper}_INSTALL)
    include(NeutrinoInstall)

    neutrino_install_headers({project_name})

    # Install generated export header
    install(FILES
        ${{CMAKE_CURRENT_BINARY_DIR}}/include/{project_name}/{project_name}_export.h
        DESTINATION ${{CMAKE_INSTALL_INCLUDEDIR}}/{project_name}
    )

    neutrino_install_library({project_name}
        NAMESPACE neutrino::
        COMPATIBILITY SameMajorVersion
{install_dependencies}    )
endif()

# ============================================================================
# Summary
# ============================================================================

neutrino_is_top_level(_is_top_level)
if(_is_top_level)
    neutrino_print_options({project_name})
endif()
'''

TEMPLATES["CMakeLists.txt.executable"] = '''\
cmake_minimum_required(VERSION 3.20)

project({project_name}
    VERSION 0.1.0
    DESCRIPTION "{description}"
    LANGUAGES CXX
)

# ============================================================================
# Neutrino CMake Integration
# ============================================================================

include(FetchContent)

if(NOT DEFINED NEUTRINO_CMAKE_DIR)
    FetchContent_Declare(neutrino_cmake
        GIT_REPOSITORY https://github.com/devbrain/neutrino-cmake.git
        GIT_TAG master
        GIT_SHALLOW TRUE
    )
    FetchContent_MakeAvailable(neutrino_cmake)
    set(NEUTRINO_CMAKE_DIR "${{neutrino_cmake_SOURCE_DIR}}/cmake")
    list(APPEND CMAKE_MODULE_PATH "${{NEUTRINO_CMAKE_DIR}}")
endif()

include(NeutrinoInit)

# ============================================================================
# Dependencies
# ============================================================================
{dependencies}
# ============================================================================
# Executable Target
# ============================================================================

add_executable({project_name}
    src/main.cpp
)

target_compile_features({project_name} PRIVATE cxx_std_{std})
{link_libraries}
# ============================================================================
# Compiler Warnings
# ============================================================================

neutrino_target_warnings({project_name})
neutrino_target_sanitizers({project_name})

# ============================================================================
# Installation
# ============================================================================

include(GNUInstallDirs)

install(TARGETS {project_name}
    RUNTIME DESTINATION ${{CMAKE_INSTALL_BINDIR}}
)
'''

# -----------------------------------------------------------------------------
# Source File Templates
# -----------------------------------------------------------------------------

TEMPLATES["header.hpp"] = '''\
#ifndef {guard}
#define {guard}

{export_include}
namespace {namespace} {{

// Your code here

}} // namespace {namespace}

#endif // {guard}
'''

TEMPLATES["source.cpp"] = '''\
#include <{project_name}/{project_name}.{ext}>

namespace {namespace} {{

// Your implementation here

}} // namespace {namespace}
'''

TEMPLATES["main.cpp"] = '''\
#include <iostream>

int main(int argc, char* argv[]) {{
    std::cout << "{project_name} v0.1.0" << std::endl;
    return 0;
}}
'''

# -----------------------------------------------------------------------------
# Test Templates
# -----------------------------------------------------------------------------

TEMPLATES["test/CMakeLists.txt"] = '''\
add_executable({project_name}_tests
    test_main.cpp
    test_{project_name}.cpp
)

target_link_libraries({project_name}_tests PRIVATE
    {target_link}
    doctest::doctest
)

neutrino_target_warnings({project_name}_tests)
neutrino_target_sanitizers({project_name}_tests)

include(CTest)
add_test(NAME {project_name}_tests COMMAND {project_name}_tests)
'''

TEMPLATES["test/test_main.cpp"] = '''\
#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>
'''

TEMPLATES["test/test_project.cpp"] = '''\
#include <doctest/doctest.h>
#include <{project_name}/{project_name}.{ext}>

TEST_CASE("{project_name} basic test") {{
    CHECK(true);
}}
'''

# -----------------------------------------------------------------------------
# Example Templates
# -----------------------------------------------------------------------------

TEMPLATES["examples/CMakeLists.txt"] = '''\
add_executable({project_name}_example
    example.cpp
)

target_link_libraries({project_name}_example PRIVATE
    {target_link}
)

neutrino_target_warnings({project_name}_example)
'''

TEMPLATES["examples/example.cpp"] = '''\
#include <{project_name}/{project_name}.{ext}>
#include <iostream>

int main() {{
    std::cout << "{project_name} example" << std::endl;
    return 0;
}}
'''

# -----------------------------------------------------------------------------
# Config Templates
# -----------------------------------------------------------------------------

TEMPLATES[".gitignore"] = '''\
# Build directories
build/
cmake-build-*/
out/

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# Compiled files
*.o
*.obj
*.a
*.lib
*.so
*.dylib
*.dll
*.exe

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json
CTestTestfile.cmake
Testing/
install_manifest.txt

# Package managers
vcpkg_installed/
conan/
'''

TEMPLATES[".clang-format"] = '''\
---
Language: Cpp
BasedOnStyle: Google
IndentWidth: 4
TabWidth: 4
UseTab: Never
ColumnLimit: 120
AccessModifierOffset: -4
AlignAfterOpenBracket: Align
AlignConsecutiveAssignments: false
AlignConsecutiveDeclarations: false
AlignEscapedNewlines: Left
AlignOperands: true
AlignTrailingComments: true
AllowAllParametersOfDeclarationOnNextLine: true
AllowShortBlocksOnASingleLine: false
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: false
AllowShortLoopsOnASingleLine: false
AlwaysBreakAfterReturnType: None
AlwaysBreakBeforeMultilineStrings: false
AlwaysBreakTemplateDeclarations: Yes
BinPackArguments: true
BinPackParameters: true
BreakBeforeBinaryOperators: None
BreakBeforeBraces: Attach
BreakBeforeTernaryOperators: true
BreakConstructorInitializers: BeforeColon
BreakStringLiterals: true
CommentPragmas: '^ IWYU pragma:'
CompactNamespaces: false
ConstructorInitializerAllOnOneLineOrOnePerLine: true
ConstructorInitializerIndentWidth: 4
ContinuationIndentWidth: 4
Cpp11BracedListStyle: true
DerivePointerAlignment: false
DisableFormat: false
FixNamespaceComments: true
IncludeBlocks: Preserve
IndentCaseLabels: true
IndentPPDirectives: None
IndentWrappedFunctionNames: false
KeepEmptyLinesAtTheStartOfBlocks: false
MaxEmptyLinesToKeep: 1
NamespaceIndentation: None
PointerAlignment: Left
ReflowComments: true
SortIncludes: true
SortUsingDeclarations: true
SpaceAfterCStyleCast: false
SpaceAfterTemplateKeyword: false
SpaceBeforeAssignmentOperators: true
SpaceBeforeParens: ControlStatements
SpaceInEmptyParentheses: false
SpacesBeforeTrailingComments: 2
SpacesInAngles: false
SpacesInContainerLiterals: true
SpacesInCStyleCastParentheses: false
SpacesInParentheses: false
SpacesInSquareBrackets: false
Standard: c++{std}
'''

TEMPLATES["README.md"] = '''\
# {project_name}

{description}

## Requirements

- CMake 3.20+
- C++{std} compiler

## Building

```bash
cmake -B build
cmake --build build
```

## Testing

```bash
cmake -B build -DNEUTRINO_{project_name_upper}_BUILD_TESTS=ON
cmake --build build
ctest --test-dir build
```

## Installation

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build
cmake --install build
```

## Usage

### FetchContent

```cmake
include(FetchContent)
FetchContent_Declare({project_name}
    GIT_REPOSITORY https://github.com/devbrain/{project_name}.git
    GIT_TAG main
)
FetchContent_MakeAvailable({project_name})

target_link_libraries(your_target PRIVATE neutrino::{project_name})
```

### find_package

```cmake
find_package({project_name} REQUIRED CONFIG)
target_link_libraries(your_target PRIVATE neutrino::{project_name})
```

## License

MIT License - see LICENSE file for details.
'''

TEMPLATES["docs/NEUTRINO_CMAKE.md"] = '''\
# Neutrino CMake Integration Guide

This document explains how to use **neutrino-cmake** in this project.

## What is neutrino-cmake?

neutrino-cmake is a centralized CMake tooling repository for the Neutrino C++ ecosystem. It provides:

- **Standardized build options** - Consistent option naming across all projects
- **Compiler warnings** - Pre-configured strict warning flags for MSVC, GCC, and Clang
- **Sanitizers** - Easy integration of ASan, UBSan, TSan, MSan
- **Dependency management** - Ready-to-use fetch recipes for common dependencies
- **Installation helpers** - Consistent package configuration file generation

## Available Options

This project defines the following CMake options:

| Option | Default | Description |
|--------|---------|-------------|
| `NEUTRINO_{project_name_upper}_BUILD_TESTS` | ON (top-level) | Build unit tests |
| `NEUTRINO_{project_name_upper}_BUILD_EXAMPLES` | ON (top-level) | Build examples |
| `NEUTRINO_{project_name_upper}_BUILD_BENCHMARKS` | OFF | Build benchmarks |
| `NEUTRINO_{project_name_upper}_INSTALL` | ON (top-level) | Enable installation |

## Configuration Examples

### Development Build

```bash
cmake -B build \\
    -DNEUTRINO_{project_name_upper}_BUILD_TESTS=ON \\
    -DNEUTRINO_{project_name_upper}_BUILD_EXAMPLES=ON \\
    -DNEUTRINO_ENABLE_ASAN=ON \\
    -DNEUTRINO_ENABLE_UBSAN=ON

cmake --build build
ctest --test-dir build
```

### Release Build

```bash
cmake -B build \\
    -DCMAKE_BUILD_TYPE=Release \\
    -DCMAKE_INSTALL_PREFIX=/usr/local

cmake --build build
cmake --install build
```

## Adding Dependencies

To add a neutrino ecosystem dependency:

```cmake
include(${{NEUTRINO_CMAKE_DIR}}/deps/failsafe.cmake)
neutrino_fetch_failsafe()

target_link_libraries({project_name} PUBLIC neutrino::failsafe)
```

Available dependencies: failsafe, euler, mio, libiff, scaler, mz-explode, datascript, sdlpp, SDL2, SDL3, imgui, doctest, benchmark, and more.

## Further Reading

- [neutrino-cmake repository](https://github.com/devbrain/neutrino-cmake)
- [CMake FetchContent documentation](https://cmake.org/cmake/help/latest/module/FetchContent.html)
'''

TEMPLATES["LICENSE"] = '''\
MIT License

Copyright (c) {year} {author}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'''

TEMPLATES[".github/workflows/ci.yml"] = '''\
name: CI

on:
  push:
    branches: [ "master", "main" ]
  pull_request:
    branches: [ "master", "main" ]

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          # Linux GCC
          - os: ubuntu-latest
            compiler: gcc
            version: 13

          # Linux Clang
          - os: ubuntu-latest
            compiler: clang
            version: 18

          # macOS
          - os: macos-latest
            compiler: apple-clang

          # Windows MSVC
          - os: windows-latest
            compiler: msvc

    runs-on: ${{{{ matrix.os }}}}
    name: ${{{{ matrix.os }}}} - ${{{{ matrix.compiler }}}}${{{{ matrix.version && format(' {{0}}', matrix.version) || '' }}}}

    steps:
      - uses: actions/checkout@v4

      - name: Install compiler (Linux GCC)
        if: runner.os == 'Linux' && matrix.compiler == 'gcc'
        run: |
          sudo apt-get update
          sudo apt-get install -y g++-${{{{ matrix.version }}}}
          echo "CC=gcc-${{{{ matrix.version }}}}" >> $GITHUB_ENV
          echo "CXX=g++-${{{{ matrix.version }}}}" >> $GITHUB_ENV

      - name: Install compiler (Linux Clang)
        if: runner.os == 'Linux' && matrix.compiler == 'clang'
        run: |
          sudo apt-get update
          sudo apt-get install -y lsb-release wget software-properties-common gnupg
          wget https://apt.llvm.org/llvm.sh
          chmod +x llvm.sh
          sudo bash ./llvm.sh "${{{{ matrix.version }}}}" all
          echo "CC=clang-${{{{ matrix.version }}}}" >> $GITHUB_ENV
          echo "CXX=clang++-${{{{ matrix.version }}}}" >> $GITHUB_ENV

      - name: Configure CMake (Unix)
        if: runner.os != 'Windows'
        run: |
          cmake -B build \\
            -DCMAKE_BUILD_TYPE=Release \\
            -DNEUTRINO_{project_name_upper}_BUILD_TESTS=ON

      - name: Configure CMake (Windows)
        if: runner.os == 'Windows'
        run: |
          cmake -B build `
            -DCMAKE_BUILD_TYPE=Release `
            -DNEUTRINO_{project_name_upper}_BUILD_TESTS=ON

      - name: Build
        run: cmake --build build --config Release

      - name: Run tests
        run: ctest --test-dir build --build-config Release --output-on-failure
'''

# =============================================================================
# Helper Functions
# =============================================================================

def normalize_dep_name(dep: str) -> str:
    """Convert dependency name to valid CMake identifier (remove hyphens)."""
    return dep.replace("-", "")


def create_directory(path: Path):
    """Create directory if it doesn't exist."""
    path.mkdir(parents=True, exist_ok=True)
    print(f"  Created: {path}/")


def write_file(path: Path, content: str):
    """Write content to file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    print(f"  Created: {path}")


def generate_project(args):
    """Generate project skeleton."""
    project_name = args.name
    project_name_upper = project_name.upper().replace("-", "_").replace(" ", "_")
    project_type = args.type
    std = args.std
    description = args.description or f"A neutrino ecosystem {project_type} library"
    author = args.author or "devbrain"

    root = Path(args.output) / project_name

    if root.exists() and not args.force:
        print(f"Error: Directory '{root}' already exists. Use --force to overwrite.")
        sys.exit(1)

    print(f"\nGenerating {project_type} project: {project_name}")
    print(f"  Location: {root}")
    print(f"  C++ Standard: C++{std}")
    print()

    # Determine header extension
    header_ext = "hpp" if std >= 11 else "h"

    # Build dependencies section
    deps_section = ""
    link_section = ""
    install_deps = ""

    if args.deps:
        deps_section = "\n"
        for dep in args.deps:
            # Recipe file uses original name (e.g., mz-explode.cmake)
            # Function/target names use normalized name without hyphens (e.g., mzexplode)
            norm_dep = normalize_dep_name(dep)
            deps_section += f"include(${{NEUTRINO_CMAKE_DIR}}/deps/{dep}.cmake)\n"
            deps_section += f"neutrino_fetch_{norm_dep}()\n\n"

        link_section = "\ntarget_link_libraries({} {}\n".format(
            project_name,
            "INTERFACE" if project_type == "header-only" else "PUBLIC"
        )
        for dep in args.deps:
            norm_dep = normalize_dep_name(dep)
            link_section += f"    neutrino::{norm_dep}\n"
        link_section += ")\n"

        install_deps = "        DEPENDENCIES\n"
        for dep in args.deps:
            install_deps += f'            "find_dependency({dep} REQUIRED)"\n'

    # Select template
    if project_type == "header-only":
        template_key = "CMakeLists.txt.header_only"
    elif project_type == "compiled":
        template_key = "CMakeLists.txt.compiled"
    else:
        template_key = "CMakeLists.txt.executable"

    # Format CMakeLists.txt
    cmake_content = TEMPLATES[template_key].format(
        project_name=project_name,
        project_name_upper=project_name_upper,
        description=description,
        std=std,
        dependencies=deps_section,
        link_libraries=link_section.format(project_name) if link_section else "",
        install_dependencies=install_deps,
    )

    # Create directories
    create_directory(root)

    if project_type != "executable":
        create_directory(root / "include" / project_name)

    create_directory(root / "src")
    create_directory(root / "docs")

    if args.with_tests and project_type != "executable":
        create_directory(root / "test")

    if args.with_examples and project_type != "executable":
        create_directory(root / "examples")

    # Write files
    write_file(root / "CMakeLists.txt", cmake_content)

    # Header file
    guard = f"{project_name_upper}_{project_name_upper}_{header_ext.upper()}_"
    export_include = ""
    if project_type == "compiled":
        export_include = f'#include <{project_name}/{project_name}_export.h>\n'

    if project_type != "executable":
        header_content = TEMPLATES["header.hpp"].format(
            guard=guard,
            namespace=project_name.replace("-", "_"),
            export_include=export_include,
        )
        write_file(
            root / "include" / project_name / f"{project_name}.{header_ext}",
            header_content
        )

    # Source file
    if project_type == "compiled":
        source_content = TEMPLATES["source.cpp"].format(
            project_name=project_name,
            namespace=project_name.replace("-", "_"),
            ext=header_ext,
        )
        write_file(root / "src" / f"{project_name}.cpp", source_content)
    elif project_type == "executable":
        main_content = TEMPLATES["main.cpp"].format(project_name=project_name)
        write_file(root / "src" / "main.cpp", main_content)

    # Test files
    if args.with_tests and project_type != "executable":
        target_link = f"neutrino::{project_name}" if project_type == "header-only" else project_name

        test_cmake = TEMPLATES["test/CMakeLists.txt"].format(
            project_name=project_name,
            target_link=target_link,
        )
        write_file(root / "test" / "CMakeLists.txt", test_cmake)

        write_file(root / "test" / "test_main.cpp", TEMPLATES["test/test_main.cpp"])

        test_content = TEMPLATES["test/test_project.cpp"].format(
            project_name=project_name,
            ext=header_ext,
        )
        write_file(root / "test" / f"test_{project_name}.cpp", test_content)

    # Example files
    if args.with_examples and project_type != "executable":
        target_link = f"neutrino::{project_name}" if project_type == "header-only" else project_name

        example_cmake = TEMPLATES["examples/CMakeLists.txt"].format(
            project_name=project_name,
            target_link=target_link,
        )
        write_file(root / "examples" / "CMakeLists.txt", example_cmake)

        example_content = TEMPLATES["examples/example.cpp"].format(
            project_name=project_name,
            ext=header_ext,
        )
        write_file(root / "examples" / "example.cpp", example_content)

    # Additional files
    write_file(root / ".gitignore", TEMPLATES[".gitignore"])

    clang_format = TEMPLATES[".clang-format"].format(std=std)
    write_file(root / ".clang-format", clang_format)

    readme = TEMPLATES["README.md"].format(
        project_name=project_name,
        project_name_upper=project_name_upper,
        description=description,
        std=std,
    )
    write_file(root / "README.md", readme)

    # Documentation
    neutrino_guide = TEMPLATES["docs/NEUTRINO_CMAKE.md"].format(
        project_name=project_name,
        project_name_upper=project_name_upper,
    )
    write_file(root / "docs" / "NEUTRINO_CMAKE.md", neutrino_guide)

    # License
    license_content = TEMPLATES["LICENSE"].format(
        year=datetime.now().year,
        author=author,
    )
    write_file(root / "LICENSE", license_content)

    # CI workflow (for library projects with tests)
    if args.with_tests and project_type != "executable":
        ci_content = TEMPLATES[".github/workflows/ci.yml"].format(
            project_name_upper=project_name_upper,
        )
        write_file(root / ".github" / "workflows" / "ci.yml", ci_content)

    print()
    print(f"Project '{project_name}' created successfully!")
    print()
    print("Next steps:")
    print(f"  cd {root}")
    print("  cmake -B build")
    print("  cmake --build build")


def main():
    parser = argparse.ArgumentParser(
        description="Generate a new neutrino ecosystem project",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s mylib --type=header-only --std=17
  %(prog)s mylib --type=compiled --std=20 --with-tests --with-examples
  %(prog)s myapp --type=executable --std=20
  %(prog)s mylib --type=header-only --deps failsafe euler
        """
    )

    parser.add_argument("name", help="Project name")

    parser.add_argument(
        "--type", "-t",
        choices=["header-only", "compiled", "executable"],
        default="header-only",
        help="Project type (default: header-only)"
    )

    parser.add_argument(
        "--std", "-s",
        type=int,
        choices=[11, 14, 17, 20, 23],
        default=20,
        help="C++ standard (default: 20)"
    )

    parser.add_argument(
        "--description", "-d",
        help="Project description"
    )

    parser.add_argument(
        "--author", "-a",
        help="Author name for LICENSE (default: devbrain)"
    )

    parser.add_argument(
        "--output", "-o",
        default=".",
        help="Output directory (default: current directory)"
    )

    parser.add_argument(
        "--with-tests",
        action="store_true",
        default=True,
        help="Include test directory (default: yes)"
    )

    parser.add_argument(
        "--no-tests",
        action="store_false",
        dest="with_tests",
        help="Don't include test directory"
    )

    parser.add_argument(
        "--with-examples",
        action="store_true",
        default=True,
        help="Include examples directory (default: yes)"
    )

    parser.add_argument(
        "--no-examples",
        action="store_false",
        dest="with_examples",
        help="Don't include examples directory"
    )

    parser.add_argument(
        "--deps",
        nargs="+",
        help="Dependencies to include (e.g., failsafe euler)"
    )

    parser.add_argument(
        "--force", "-f",
        action="store_true",
        help="Overwrite existing directory"
    )

    args = parser.parse_args()
    generate_project(args)


if __name__ == "__main__":
    main()
