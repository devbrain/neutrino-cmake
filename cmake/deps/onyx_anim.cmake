# =============================================================================
# onyx_anim.cmake - Animation and video codec library (FLC, Smacker, Bink1,
#                   Amiga ANIM, CDXL, Atari SEQ, Deluxe Paint ANM, YAFA)
# =============================================================================
# Targets:
#   neutrino::onyx_anim_sdk     - abstract decoder interface, registry,
#                                  convert_surface, frame_clock, probe
#   neutrino::onyx_anim_codecs  - all supported codecs + register_all_codecs
#   neutrino::onyx_anim_player  - engine-facing tick-per-frame player +
#                                  cpu_surface helper (depends on musac)
# =============================================================================

include_guard(GLOBAL)

set(NEUTRINO_ONYX_ANIM_VERSION "master" CACHE STRING "onyx_anim version/tag")

function(neutrino_fetch_onyx_anim)
    if(TARGET neutrino::onyx_anim_sdk OR TARGET onyx_anim_sdk)
        message(STATUS "[Neutrino] onyx_anim already available")
        return()
    endif()

    message(STATUS "[Neutrino] Fetching onyx_anim...")

    include(FetchContent)

    FetchContent_Declare(onyx_anim
        GIT_REPOSITORY https://github.com/devbrain/onyx_anim.git
        GIT_TAG ${NEUTRINO_ONYX_ANIM_VERSION}
        GIT_SHALLOW TRUE
    )

    # Disable onyx_anim tests and examples when used as dependency.
    set(NEUTRINO_ONYX_ANIM_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
    set(NEUTRINO_ONYX_ANIM_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)

    # onyx_anim transitively pulls in onyx_image and musac via its own
    # neutrino_fetch_* calls — no need to fetch them here. SDL3 follows
    # transitively from musac.
    FetchContent_MakeAvailable(onyx_anim)

    # Create neutrino:: aliases if onyx_anim's CMakeLists hasn't already
    # (it does, as of master, but keep this defensive in case a consumer
    # pins to an older tag).
    foreach(_lib onyx_anim_sdk onyx_anim_codecs onyx_anim_player)
        if(TARGET ${_lib} AND NOT TARGET neutrino::${_lib})
            add_library(neutrino::${_lib} ALIAS ${_lib})
        endif()
    endforeach()

    # Suppress warnings for onyx_anim headers when they're consumed via
    # FetchContent — the consumer's warning-as-error policy shouldn't
    # gate us on third-party-style headers.
    foreach(_lib onyx_anim_sdk onyx_anim_codecs onyx_anim_player)
        if(TARGET ${_lib})
            neutrino_suppress_warnings(${_lib})
        endif()
    endforeach()
endfunction()
