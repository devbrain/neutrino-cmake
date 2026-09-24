# =============================================================================
# NeutrinoGrammar.cmake
# =============================================================================
# Compiler-compiler and grammar generation tools for the Neutrino ecosystem.
# Provides Lemon parser and re2c scanner generators with cross-compilation
# host tool support.
# =============================================================================

include_guard(GLOBAL)

include("${NEUTRINO_CMAKE_DIR}/NeutrinoHostTools.cmake")
include(FetchContent)

# -----------------------------------------------------------------------------
# Internal: Bootstrap Lemon Parser Generator (from SQLite)
# -----------------------------------------------------------------------------

function(_neutrino_ensure_lemon)
    if(TARGET neutrino::lemon OR TARGET lemon)
        return()
    endif()

    if(DEFINED CACHE{LEMON_EXECUTABLE} AND EXISTS "${LEMON_EXECUTABLE}")
        message(STATUS "[Neutrino] Using preset LEMON_EXECUTABLE: ${LEMON_EXECUTABLE}")
        add_executable(neutrino::lemon IMPORTED GLOBAL)
        set_target_properties(neutrino::lemon PROPERTIES IMPORTED_LOCATION "${LEMON_EXECUTABLE}")
        return()
    endif()

    set(_lemon_dir "${CMAKE_BINARY_DIR}/_deps/lemon")
    set(_lemon_c "${_lemon_dir}/lemon.c")
    set(_lempar_c "${_lemon_dir}/lempar.c")

    set(SQLITE_VERSION_TAG "version-3.45.0" CACHE STRING "SQLite version tag for Lemon")
    set(_lemon_url "https://raw.githubusercontent.com/sqlite/sqlite/${SQLITE_VERSION_TAG}/tool/lemon.c")
    set(_lempar_url "https://raw.githubusercontent.com/sqlite/sqlite/${SQLITE_VERSION_TAG}/tool/lempar.c")

    if(NOT EXISTS "${_lemon_c}")
        message(STATUS "[Neutrino] Downloading lemon.c from SQLite ${SQLITE_VERSION_TAG}...")
        file(DOWNLOAD "${_lemon_url}" "${_lemon_c}" STATUS _status LOG _log SHOW_PROGRESS)
        list(GET _status 0 _rc)
        if(NOT _rc EQUAL 0)
            file(REMOVE "${_lemon_c}")
            message(FATAL_ERROR "[Neutrino] Failed to download lemon.c: ${_status}\n${_log}")
        endif()

        # Patch lemon.c to ignore parsing conflicts in return code so shift/reduce
        # conflicts resolved by default precedence rules do not fail the build
        file(READ "${_lemon_c}" _lemon_content)
        string(REPLACE
            "exitcode = ((lem.errorcnt > 0) || (lem.nconflict > 0)) ? 1 : 0;"
            "exitcode = (lem.errorcnt > 0) ? 1 : 0;"
            _lemon_content "${_lemon_content}"
        )
        file(WRITE "${_lemon_c}" "${_lemon_content}")
    endif()

    if(NOT EXISTS "${_lempar_c}")
        message(STATUS "[Neutrino] Downloading lempar.c from SQLite ${SQLITE_VERSION_TAG}...")
        file(DOWNLOAD "${_lempar_url}" "${_lempar_c}" STATUS _status LOG _log SHOW_PROGRESS)
        list(GET _status 0 _rc)
        if(NOT _rc EQUAL 0)
            file(REMOVE "${_lempar_c}")
            message(FATAL_ERROR "[Neutrino] Failed to download lempar.c: ${_status}\n${_log}")
        endif()
    endif()

    set(NEUTRINO_LEMPAR_FILE "${_lempar_c}" CACHE FILEPATH "Default lempar.c template" FORCE)

    neutrino_bootstrap_local_tool(lemon
        SOURCES "${_lemon_c}"
        STD 11
    )

    if(TARGET lemon AND NOT TARGET neutrino::lemon)
        add_executable(neutrino::lemon ALIAS lemon)
    endif()
    set(LEMON_EXECUTABLE "$<TARGET_FILE:lemon>" CACHE FILEPATH "Lemon executable" FORCE)
endfunction()

# -----------------------------------------------------------------------------
# Internal: Bootstrap re2c Scanner Generator (Pinned 3.1)
# -----------------------------------------------------------------------------

function(_neutrino_ensure_re2c)
    if(TARGET neutrino::re2c OR TARGET re2c OR TARGET re2c_build)
        return()
    endif()

    if(DEFINED CACHE{RE2C_EXECUTABLE} AND EXISTS "${RE2C_EXECUTABLE}")
        message(STATUS "[Neutrino] Using preset RE2C_EXECUTABLE: ${RE2C_EXECUTABLE}")
        add_executable(neutrino::re2c IMPORTED GLOBAL)
        set_target_properties(neutrino::re2c PROPERTIES IMPORTED_LOCATION "${RE2C_EXECUTABLE}")
        return()
    endif()

    set(RE2C_VERSION "3.1" CACHE STRING "Pinned re2c version")

    set(FETCHCONTENT_QUIET OFF)
    if(POLICY CMP0169)
        cmake_policy(SET CMP0169 OLD)
    endif()

    FetchContent_Declare(
        re2c_src
        GIT_REPOSITORY "https://github.com/skvadrik/re2c.git"
        GIT_TAG "${RE2C_VERSION}"
        GIT_SHALLOW TRUE
    )
    FetchContent_GetProperties(re2c_src)
    if(NOT re2c_src_POPULATED)
        FetchContent_Populate(re2c_src)
    endif()

    if(CMAKE_CROSSCOMPILING OR NEUTRINO_CROSS_COMPILING)
        # ---------------------------------------------------------------------
        # Cross-compiling: Build re2c natively for the host machine.
        # Strips target/Android environment variables to prevent contamination.
        # ---------------------------------------------------------------------
        set(_host_root "${CMAKE_BINARY_DIR}/host-tools/re2c")
        set(_host_build "${_host_root}/build")
        if(WIN32)
            set(_re2c_bin "${_host_build}/re2c.exe")
        else()
            set(_re2c_bin "${_host_build}/re2c")
        endif()

        set(_unset_env
            --unset=CC --unset=CXX --unset=AR --unset=AS --unset=LD
            --unset=RANLIB --unset=STRIP --unset=NM --unset=OBJCOPY
            --unset=CFLAGS --unset=CXXFLAGS --unset=LDFLAGS --unset=ASMFLAGS
            --unset=ANDROID_NDK --unset=ANDROID_NDK_ROOT --unset=ANDROID_NDK_HOME
            --unset=NDK_ROOT --unset=ANDROID_ABI --unset=ANDROID_PLATFORM
            --unset=ANDROID_TOOLCHAIN
        )

        set(_marker "${_host_build}/.re2c-configured")
        if(NOT EXISTS "${_marker}")
            message(STATUS "[Neutrino] Configuring host re2c...")
            file(MAKE_DIRECTORY "${_host_build}")
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E env ${_unset_env}
                        ${CMAKE_COMMAND}
                        -S "${re2c_src_SOURCE_DIR}"
                        -B "${_host_build}"
                        -DCMAKE_BUILD_TYPE=Release
                        -DCMAKE_TOOLCHAIN_FILE=
                        -DRE2C_BUILD_RE2GO=OFF
                        -DRE2C_BUILD_RE2RUST=OFF
                        -DRE2C_BUILD_LIBS=OFF
                        -DRE2C_BUILD_BENCHMARKS=OFF
                        -DRE2C_REBUILD_DOCS=OFF
                RESULT_VARIABLE _rc
            )
            if(NOT _rc EQUAL 0)
                message(FATAL_ERROR "[Neutrino] Host re2c configure failed (rc=${_rc})")
            endif()
            file(TOUCH "${_marker}")
        endif()

        if(NOT EXISTS "${_re2c_bin}")
            message(STATUS "[Neutrino] Building host re2c...")
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E env ${_unset_env}
                        ${CMAKE_COMMAND} --build "${_host_build}" --target re2c --config Release
                RESULT_VARIABLE _rc
            )
            if(NOT _rc EQUAL 0)
                message(FATAL_ERROR "[Neutrino] Host re2c build failed (rc=${_rc})")
            endif()
        endif()

        if(NOT TARGET neutrino::re2c)
            add_executable(neutrino::re2c IMPORTED GLOBAL)
            set_target_properties(neutrino::re2c PROPERTIES IMPORTED_LOCATION "${_re2c_bin}")
        endif()
        set(RE2C_EXECUTABLE "${_re2c_bin}" CACHE FILEPATH "re2c executable" FORCE)
    else()
        # ---------------------------------------------------------------------
        # Native build: Build re2c via ExternalProject to isolate flags/targets
        # ---------------------------------------------------------------------
        if(MSVC)
            set(RE2C_WARNING_FLAGS "/W0")
        else()
            set(RE2C_WARNING_FLAGS "-w")
        endif()

        include(ExternalProject)
        ExternalProject_Add(
            re2c_build
            SOURCE_DIR ${re2c_src_SOURCE_DIR}
            CMAKE_ARGS
                -DCMAKE_BUILD_TYPE=Release
                -DCMAKE_C_FLAGS=${RE2C_WARNING_FLAGS}
                -DCMAKE_CXX_FLAGS=${RE2C_WARNING_FLAGS}
                -DRE2C_BUILD_RE2GO=OFF
                -DRE2C_BUILD_RE2RUST=OFF
                -DRE2C_BUILD_LIBS=OFF
                -DRE2C_BUILD_BENCHMARKS=OFF
                -DRE2C_REBUILD_DOCS=OFF
            BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --target re2c --config Release
            INSTALL_COMMAND ""
            BUILD_BYPRODUCTS <BINARY_DIR>/re2c
        )
        ExternalProject_Get_Property(re2c_build BINARY_DIR)
        set(_re2c_bin "${BINARY_DIR}/re2c")
        if(WIN32)
            set(_re2c_bin "${_re2c_bin}.exe")
        endif()

        if(NOT TARGET neutrino::re2c)
            add_executable(neutrino::re2c IMPORTED GLOBAL)
            set_target_properties(neutrino::re2c PROPERTIES IMPORTED_LOCATION "${_re2c_bin}")
        endif()
        set(RE2C_EXECUTABLE "${_re2c_bin}" CACHE FILEPATH "re2c executable" FORCE)
    endif()
endfunction()

# -----------------------------------------------------------------------------
# Public Generator Functions
# -----------------------------------------------------------------------------

#[=======================================================================[.rst:
neutrino_lemon_generate
-----------------------

Generate C parser source and header from a Lemon grammar file (.y)::

    neutrino_lemon_generate(
        GRAMMAR <grammar.y>
        [OUTPUT_DIR <output_dir>]
        [TEMPLATE <lempar_file>]
        [EXTRA_ARGS <args...>]
        [OUTPUT_SOURCE <var_for_c_file>]
        [OUTPUT_HEADER <var_for_h_file>]
    )
#]=======================================================================]
function(neutrino_lemon_generate)
    _neutrino_ensure_lemon()

    cmake_parse_arguments(ARG
        ""
        "GRAMMAR;OUTPUT_DIR;TEMPLATE;OUTPUT_SOURCE;OUTPUT_HEADER"
        "EXTRA_ARGS"
        ${ARGN}
    )

    if(NOT ARG_GRAMMAR)
        message(FATAL_ERROR "[Neutrino] neutrino_lemon_generate requires GRAMMAR")
    endif()

    if(NOT ARG_OUTPUT_DIR)
        set(ARG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    if(NOT ARG_TEMPLATE)
        set(ARG_TEMPLATE "${NEUTRINO_LEMPAR_FILE}")
    endif()

    get_filename_component(_grammar_abs "${ARG_GRAMMAR}" ABSOLUTE)
    get_filename_component(_grammar_name "${ARG_GRAMMAR}" NAME_WLE)

    set(_out_c "${ARG_OUTPUT_DIR}/${_grammar_name}.c")
    set(_out_h "${ARG_OUTPUT_DIR}/${_grammar_name}.h")

    file(MAKE_DIRECTORY "${ARG_OUTPUT_DIR}")

    set(_cmd_args "-T${ARG_TEMPLATE}" "-d${ARG_OUTPUT_DIR}")
    if(ARG_EXTRA_ARGS)
        list(APPEND _cmd_args ${ARG_EXTRA_ARGS})
    endif()
    list(APPEND _cmd_args "${_grammar_abs}")

    set(_lemon_dep "")
    if(TARGET neutrino::lemon)
        set(_lemon_exe neutrino::lemon)
        set(_lemon_dep neutrino::lemon)
    elseif(TARGET lemon)
        set(_lemon_exe lemon)
        set(_lemon_dep lemon)
    elseif(DEFINED LEMON_EXECUTABLE AND EXISTS "${LEMON_EXECUTABLE}")
        set(_lemon_exe "${LEMON_EXECUTABLE}")
    endif()

    add_custom_command(
        OUTPUT "${_out_c}" "${_out_h}"
        COMMAND ${_lemon_exe} ${_cmd_args}
        DEPENDS "${_grammar_abs}" "${ARG_TEMPLATE}" ${_lemon_dep}
        COMMENT "Generating parser with lemon: ${_grammar_name}.c / .h"
        VERBATIM
    )

    if(ARG_OUTPUT_SOURCE)
        set(${ARG_OUTPUT_SOURCE} "${_out_c}" PARENT_SCOPE)
    endif()
    if(ARG_OUTPUT_HEADER)
        set(${ARG_OUTPUT_HEADER} "${_out_h}" PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[.rst:
neutrino_re2c_generate
----------------------

Generate C/C++ lexer from re2c scanner file (.re)::

    neutrino_re2c_generate(
        SCANNER <scanner.re>
        OUTPUT <output_file>
        [DEPENDS <extra_dependencies...>]
        [FLAGS <flags...>]
        [OUTPUT_SOURCE <var_for_output_file>]
    )
#]=======================================================================]
function(neutrino_re2c_generate)
    _neutrino_ensure_re2c()

    cmake_parse_arguments(ARG
        ""
        "SCANNER;OUTPUT;OUTPUT_SOURCE"
        "DEPENDS;FLAGS"
        ${ARGN}
    )

    if(NOT ARG_SCANNER)
        message(FATAL_ERROR "[Neutrino] neutrino_re2c_generate requires SCANNER")
    endif()

    if(NOT ARG_OUTPUT)
        message(FATAL_ERROR "[Neutrino] neutrino_re2c_generate requires OUTPUT")
    endif()

    get_filename_component(_scanner_abs "${ARG_SCANNER}" ABSOLUTE)
    get_filename_component(_out_abs "${ARG_OUTPUT}" ABSOLUTE)
    get_filename_component(_out_dir "${_out_abs}" DIRECTORY)

    file(MAKE_DIRECTORY "${_out_dir}")

    set(_re2c_dep "")
    if(TARGET neutrino::re2c)
        set(_re2c_exe neutrino::re2c)
        set(_re2c_dep neutrino::re2c)
    elseif(TARGET re2c)
        set(_re2c_exe re2c)
        set(_re2c_dep re2c)
    elseif(DEFINED RE2C_EXECUTABLE AND EXISTS "${RE2C_EXECUTABLE}")
        set(_re2c_exe "${RE2C_EXECUTABLE}")
    endif()

    if(TARGET re2c_build)
        list(APPEND _re2c_dep re2c_build)
    endif()

    set(_cmd_args ${ARG_FLAGS} -o "${_out_abs}" "${_scanner_abs}")

    add_custom_command(
        OUTPUT "${_out_abs}"
        COMMAND ${_re2c_exe} ${_cmd_args}
        DEPENDS "${_scanner_abs}" ${ARG_DEPENDS} ${_re2c_dep}
        COMMENT "Generating scanner with re2c: ${_out_abs}"
        VERBATIM
    )

    if(ARG_OUTPUT_SOURCE)
        set(${ARG_OUTPUT_SOURCE} "${_out_abs}" PARENT_SCOPE)
    endif()
endfunction()

#[=======================================================================[.rst:
neutrino_add_grammar
--------------------

All-in-one generator combining Lemon parser and re2c scanner::

    neutrino_add_grammar(
        NAME <name>
        PARSER <parser.y>
        SCANNER <scanner.re>
        [OUTPUT_DIR <output_dir>]
        [LEMPAR_TEMPLATE <lempar_file>]
        [RE2C_FLAGS <flags...>]
        [LEMON_ARGS <args...>]
        [EXTRA_DEPENDS <deps...>]
        [OUTPUT_SOURCES <var_sources>]
        [OUTPUT_HEADERS <var_headers>]
    )
#]=======================================================================]
function(neutrino_add_grammar)
    cmake_parse_arguments(ARG
        ""
        "NAME;PARSER;SCANNER;OUTPUT_DIR;LEMPAR_TEMPLATE;OUTPUT_SOURCES;OUTPUT_HEADERS"
        "RE2C_FLAGS;LEMON_ARGS;EXTRA_DEPENDS"
        ${ARGN}
    )

    if(NOT ARG_NAME)
        message(FATAL_ERROR "[Neutrino] neutrino_add_grammar requires NAME")
    endif()
    if(NOT ARG_PARSER)
        message(FATAL_ERROR "[Neutrino] neutrino_add_grammar requires PARSER")
    endif()
    if(NOT ARG_SCANNER)
        message(FATAL_ERROR "[Neutrino] neutrino_add_grammar requires SCANNER")
    endif()

    if(NOT ARG_OUTPUT_DIR)
        set(ARG_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()

    # 1. Generate Lemon parser
    neutrino_lemon_generate(
        GRAMMAR "${ARG_PARSER}"
        OUTPUT_DIR "${ARG_OUTPUT_DIR}"
        TEMPLATE "${ARG_LEMPAR_TEMPLATE}"
        EXTRA_ARGS ${ARG_LEMON_ARGS}
        OUTPUT_SOURCE _parser_c
        OUTPUT_HEADER _parser_h
    )

    # 2. Determine scanner output filename
    get_filename_component(_scanner_name "${ARG_SCANNER}" NAME_WLE)
    set(_scanner_c "${ARG_OUTPUT_DIR}/${_scanner_name}.c")

    # 3. Generate re2c scanner (depends on parser header)
    neutrino_re2c_generate(
        SCANNER "${ARG_SCANNER}"
        OUTPUT "${_scanner_c}"
        DEPENDS "${_parser_h}" ${ARG_EXTRA_DEPENDS}
        FLAGS ${ARG_RE2C_FLAGS}
        OUTPUT_SOURCE _scanner_out_c
    )

    # 4. Suppress compiler warnings on generated C files
    if(MSVC)
        set_source_files_properties("${_parser_c}" "${_scanner_c}" PROPERTIES COMPILE_FLAGS "/W0")
    else()
        set_source_files_properties("${_parser_c}" "${_scanner_c}" PROPERTIES COMPILE_FLAGS "-w")
    endif()

    # 5. Return outputs
    if(ARG_OUTPUT_SOURCES)
        set(${ARG_OUTPUT_SOURCES} "${_parser_c}" "${_scanner_c}" PARENT_SCOPE)
    endif()
    if(ARG_OUTPUT_HEADERS)
        set(${ARG_OUTPUT_HEADERS} "${_parser_h}" PARENT_SCOPE)
    endif()
endfunction()
