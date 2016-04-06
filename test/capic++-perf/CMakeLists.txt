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

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -std=c++0x")

find_package(PkgConfig)
pkg_check_modules(PC CommonAPI>=3.1 CommonAPI-DBus>=3.1 dbus-1)

set(CAPICXX_PERF_INCLUDE_DIRS
    ${CAPICXX_PERF_INCLUDE_DIRS}
    ${PC_INCLUDE_DIRS}
)

set(CAPICXX_PERF_LIBS ${CAPICXX_PERF_LIBS} ${PC_LIBRARIES})

set(FIDL_DIR ${CMAKE_SOURCE_DIR}/fidl)
set(SRC_GEN_DIR ${CMAKE_BINARY_DIR}/src-gen)
set(PERFTEST_DIR ${SRC_GEN_DIR}/v0/org/genivi/capic)

set(CAPICXX_CORE_GEN_CMD capic++-core-gen -sk)
set(CAPICXX_DBUS_GEN_CMD capic++-dbus-gen)

include_directories(
     ${SRC_GEN_DIR}
     ${CAPICXX_PERF_INCLUDE_DIRS}
)

link_directories(
     ${CAPICXX_PERF_LINK_DIRS}
)

set(PERFTEST_CORE_OUTPUT
    ${PERFTEST_DIR}/TestPerf.hpp
    ${PERFTEST_DIR}/TestPerfProxyBase.hpp
    ${PERFTEST_DIR}/TestPerfProxy.hpp
    ${PERFTEST_DIR}/TestPerfStubDefault.cpp
    ${PERFTEST_DIR}/TestPerfStubDefault.hpp
    ${PERFTEST_DIR}/TestPerfStub.hpp
)
add_custom_command(
    OUTPUT ${PERFTEST_CORE_OUTPUT}
    COMMAND ${CAPICXX_CORE_GEN_CMD} ${FIDL_DIR}/TestPerf.fidl
    DEPENDS ${FIDL_DIR}/TestPerf.fidl
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

set(PERFTEST_DBUS_OUTPUT
    ${PERFTEST_DIR}/TestPerfDBusDeployment.cpp
    ${PERFTEST_DIR}/TestPerfDBusDeployment.hpp
    ${PERFTEST_DIR}/TestPerfDBusProxy.cpp
    ${PERFTEST_DIR}/TestPerfDBusProxy.hpp
    ${PERFTEST_DIR}/TestPerfDBusStubAdapter.cpp
    ${PERFTEST_DIR}/TestPerfDBusStubAdapter.hpp
)
add_custom_command(
    OUTPUT ${PERFTEST_DBUS_OUTPUT}
    COMMAND ${CAPICXX_DBUS_GEN_CMD} ${FIDL_DIR}/TestPerf.fidl
    DEPENDS ${FIDL_DIR}/TestPerf.fidl
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

# Note: TestPerf.hpp is necessary to trigger the execution of the core generator
add_executable(capic++-client
    src/capic++-client.cpp
    ${PERFTEST_DIR}/TestPerf.hpp
    ${PERFTEST_DIR}/TestPerfDBusProxy.cpp
    ${PERFTEST_DIR}/TestPerfDBusDeployment.cpp
)
target_link_libraries(capic++-client ${CAPICXX_PERF_LIBS})

add_executable(capic++-server
    src/capic++-server.cpp
    ${PERFTEST_DIR}/TestPerfDBusStubAdapter.cpp
    ${PERFTEST_DIR}/TestPerfStubDefault.cpp
    ${PERFTEST_DIR}/TestPerfDBusDeployment.cpp
)
target_link_libraries(capic++-server ${CAPICXX_PERF_LIBS})

install(
    TARGETS capic++-client capic++-server
    RUNTIME DESTINATION bin
)
