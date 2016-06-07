# SPDX license identifier: MPL-2.0
# Copyright (C) 2016, Visteon Corp.
# Author: Pavel Konopelko, pkonopel@visteon.com
#
# This file is part of Common API C
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), version 2.0.
# If a copy of the MPL was not distributed with this file,
# you can obtain one at http://mozilla.org/MPL/2.0/.
# For further information see http://www.genivi.org/.

cmake_minimum_required(VERSION 2.8)

set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/Modules" ${CMAKE_MODULE_PATH})
find_package(CAPICXX 3.1.5 REQUIRED)

include(Modules/UseCAPICXX.cmake)

if (NOT CAPICXX_FOUND)
    message(FATAL_ERROR "Unable to find CAPIC++ libraries")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CAPICXX_DEFINITIONS}")

include_directories(
    ${CAPICXX_INCLUDE_DIRS}
    ${CAPICXX_SRCGEN_DIR}
)

link_directories(
     ${CAPICXX_LINK_DIR}
)

CAPICXX_ADD_INTERFACE(TestPerf CORE SKELETON)
CAPICXX_ADD_INTERFACE(TestPerf DBUS)

add_executable(capicxx-client
    src/capicxx-client.cpp
    ${CAPICXX_TestPerf_CORE_CLIENT_FILES}
    ${CAPICXX_TestPerf_DBUS_CLIENT_FILES}
)
target_link_libraries(capicxx-client ${CAPICXX_LIBRARIES})

add_executable(capicxx-server
    src/capicxx-server.cpp
    ${CAPICXX_TestPerf_CORE_SERVER_FILES}
    ${CAPICXX_TestPerf_DBUS_SERVER_FILES}
)
target_link_libraries(capicxx-server ${CAPICXX_LIBRARIES})

add_executable(dbus-client
  src/dbus-client.c
)
target_link_libraries(dbus-client ${CAPICXX_LIBRARIES})

add_executable(dbus-server
  src/dbus-server.c
)
target_link_libraries(dbus-server ${CAPICXX_LIBRARIES})

install(
    TARGETS capicxx-client capicxx-server dbus-client dbus-server
    RUNTIME DESTINATION bin
)
