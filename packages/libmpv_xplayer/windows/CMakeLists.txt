# This file is a part of media_kit (https://github.com/media-kit/media-kit).
#
# Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
# All rights reserved.
# Use of this source code is governed by MIT license that can be found in the LICENSE file.

cmake_minimum_required(VERSION 3.14)

# media_kit_video decides whether to compile real video support at configure
# time. Fail clearly if a host has reordered the standard plugin list.
if(TARGET media_kit_video_plugin)
  message(FATAL_ERROR "Configure libmpv_xplayer before media_kit_video; otherwise video support is disabled.")
endif()

# This option is read by the other packages which are part of package:media_kit.
option(MEDIA_KIT_LIBS_AVAILABLE "package:media_kit libraries are available." ON)

set(PROJECT_NAME "libmpv_xplayer")
project(${PROJECT_NAME} LANGUAGES CXX)

# Deal with MSVC incompatiblity
add_compile_definitions(_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)

# ------------------------------------------------------------------------------
function(download_and_verify url sha256 locationForArchive)
  # Check if the archive exists.
  if(EXISTS "${locationForArchive}")
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

    # If SHA-256 doesn't match, delete the archive to download again.
    if(NOT sha256 STREQUAL ARCHIVE_SHA256)
      file(REMOVE "${locationForArchive}")
      message(STATUS "SHA-256 mismatch. File deleted.")
    endif()
  endif()

  # Download the archive if it doesn't exist.
  if(NOT EXISTS "${locationForArchive}")
    message(STATUS "Downloading archive from ${url}...")
    file(DOWNLOAD "${url}" "${locationForArchive}" TLS_VERIFY ON STATUS DOWNLOAD_STATUS)
    list(GET DOWNLOAD_STATUS 0 DOWNLOAD_CODE)
    if(NOT DOWNLOAD_CODE EQUAL 0)
      file(REMOVE "${locationForArchive}")
      message(FATAL_ERROR "Native library download failed: ${DOWNLOAD_STATUS}")
    endif()
    message(STATUS "Downloaded archive to ${locationForArchive}.")

    # Verify SHA-256 of the newly downloaded file.
    file(SHA256 "${locationForArchive}" ARCHIVE_SHA256)

    if(sha256 STREQUAL ARCHIVE_SHA256)
      message(STATUS "${locationForArchive} Verification successful.")
    else()
      message(FATAL_ERROR "${locationForArchive} Integrity check failed, please try to re-build project again.")
    endif()
  endif()
endfunction()

# libmpv archive containing the pre-built shared libraries & headers.
set(LIBMPV "mpv-dev-lgpl-x86_64-20261025-git-baa3e11d42.7z")

# Download URL & SHA-256 hash of the libmpv archive.
set(LIBMPV_URL "https://github.com/zhongfly/mpv-winbuild/releases/download/2026-10-25-baa3e11d42/mpv-dev-lgpl-x86_64-20261025-git-baa3e11d42.7z")
set(LIBMPV_SHA256 "89f170d8eb6594a3cd6ffbf75e7d412995aba0107f8297deb3c6ec026d67191a")

# Download location of the libmpv archive.
set(LIBMPV_ARCHIVE "${CMAKE_BINARY_DIR}/${LIBMPV}")
set(LIBMPV_SRC "${CMAKE_BINARY_DIR}/libmpv")

download_and_verify(
  ${LIBMPV_URL}
  ${LIBMPV_SHA256}
  ${LIBMPV_ARCHIVE}
)

# media_kit_video expects this exact libmpv directory and flat header layout.
# A digest stamp prevents reusing a previously extracted decoder-limited build.
set(LIBMPV_STAMP "${LIBMPV_SRC}/.xplayer-sha256")
set(LIBMPV_INSTALLED_SHA256 "")
if(EXISTS "${LIBMPV_STAMP}")
  file(READ "${LIBMPV_STAMP}" LIBMPV_INSTALLED_SHA256)
endif()
if(NOT LIBMPV_INSTALLED_SHA256 STREQUAL LIBMPV_SHA256)
  file(REMOVE_RECURSE "${LIBMPV_SRC}")
  file(MAKE_DIRECTORY "${LIBMPV_SRC}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xvf "${LIBMPV_ARCHIVE}"
    WORKING_DIRECTORY "${LIBMPV_SRC}"
    RESULT_VARIABLE LIBMPV_EXTRACT_RESULT
    OUTPUT_QUIET
  )
  if(NOT LIBMPV_EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "Cannot extract pinned libmpv archive")
  endif()
  file(COPY "${LIBMPV_SRC}/include/mpv/" DESTINATION "${LIBMPV_SRC}/flat-include")
  file(REMOVE_RECURSE "${LIBMPV_SRC}/include")
  file(RENAME "${LIBMPV_SRC}/flat-include" "${LIBMPV_SRC}/include")
  file(WRITE "${LIBMPV_STAMP}" "${LIBMPV_SHA256}")
endif()

# ------------------------------------------------------------------------------

# ANGLE archive containing the pre-built shared libraries & headers.
set(ANGLE "ANGLE.7z")

# Download URL & SHA-256 hash of the ANGLE archive.
set(ANGLE_URL "https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES/releases/download/v1.0.1/ANGLE.7z")
set(ANGLE_SHA256 "cc5911bb15d596fd5a2b362613ad35b7093b427117269a7359054a65746a5f9a")

# Download location of the ANGLE archive.
set(ANGLE_ARCHIVE "${CMAKE_BINARY_DIR}/${ANGLE}")
set(ANGLE_SRC "${CMAKE_BINARY_DIR}/ANGLE")

download_and_verify(
  ${ANGLE_URL}
  ${ANGLE_SHA256}
  ${ANGLE_ARCHIVE}
)

set(ANGLE_STAMP "${ANGLE_SRC}/.xplayer-sha256")
set(ANGLE_INSTALLED_SHA256 "")
if(EXISTS "${ANGLE_STAMP}")
  file(READ "${ANGLE_STAMP}" ANGLE_INSTALLED_SHA256)
endif()
if(NOT ANGLE_INSTALLED_SHA256 STREQUAL ANGLE_SHA256)
  file(REMOVE_RECURSE "${ANGLE_SRC}")
  file(MAKE_DIRECTORY "${ANGLE_SRC}")
  execute_process(
    COMMAND "${CMAKE_COMMAND}" -E tar xvf "${ANGLE_ARCHIVE}"
    WORKING_DIRECTORY "${ANGLE_SRC}"
    RESULT_VARIABLE ANGLE_EXTRACT_RESULT
    OUTPUT_QUIET
  )
  if(NOT ANGLE_EXTRACT_RESULT EQUAL 0)
    message(FATAL_ERROR "Cannot extract pinned ANGLE archive")
  endif()
  file(WRITE "${ANGLE_STAMP}" "${ANGLE_SHA256}")
endif()

# ------------------------------------------------------------------------------
set(PLUGIN_NAME "libmpv_xplayer_plugin")

add_library(
  ${PLUGIN_NAME} SHARED
  "include/libmpv_xplayer/libmpv_xplayer_plugin_c_api.h"
  "libmpv_xplayer_plugin_c_api.cpp"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(
  ${PLUGIN_NAME}
  PROPERTIES
  CXX_VISIBILITY_PRESET
  hidden
)
target_compile_definitions(
  ${PLUGIN_NAME}
  PRIVATE
  FLUTTER_PLUGIN_IMPL
)

target_include_directories(
  ${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(
  ${PLUGIN_NAME}
  PRIVATE
  flutter
  flutter_wrapper_plugin
)

set(
  libmpv_xplayer_bundled_libraries
  "${LIBMPV_SRC}/libmpv-2.dll"
  "${ANGLE_SRC}/d3dcompiler_47.dll"
  "${ANGLE_SRC}/libEGL.dll"
  "${ANGLE_SRC}/libGLESv2.dll"
  "${ANGLE_SRC}/vk_swiftshader.dll"
  "${ANGLE_SRC}/vulkan-1.dll"
  "${ANGLE_SRC}/zlib.dll"
  PARENT_SCOPE
)
