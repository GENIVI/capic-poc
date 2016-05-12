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

##############################################################################
# Find CAPIC++
#
# This module finds installed CAPIC++.  It sets the following variables:
#
# * CAPICXX_FOUND - set to true if CAPIC++ is found
# * CAPICXX_DEFINITIONS - the compiler parameters to use with CAPIC++
# * CAPICXX_INCLUDE_DIRS - the list of directories with CAPIC++ include files
# * CAPICXX_LIBRARIES - the list of CAPIC++ libraries
#
# For developer builds, the variables CAPICXX_INCLUDE_DIR and CAPICXX_LIBRARY
# can be defined to override the values computed by this module.
##############################################################################

find_package(PkgConfig)
pkg_check_modules(CAPICXX_PC CommonAPI CommonAPI-DBus dbus-1)

set(CAPICXX_DEFINITION "${CAPICXX_DEFINITION} -pthread -std=c++0x")
set(CAPICXX_INCLUDE_DIR ${CAPICXX_INCLUDE_DIR} ${CAPICXX_PC_INCLUDE_DIRS})
set(CAPICXX_LIBRARY ${CAPICXX_LIBRARY} ${CAPICXX_PC_LIBRARIES})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    CAPICXX DEFAULT_MSG CAPICXX_LIBRARY CAPICXX_INCLUDE_DIR)

mark_as_advanced(CAPICXX_DEFINITION CAPICXX_INCLUDE_DIR CAPICXX_LIBRARY)

set(CAPICXX_DEFINITIONS ${CAPICXX_DEFINITION})
set(CAPICXX_INCLUDE_DIRS ${CAPICXX_INCLUDE_DIR})
set(CAPICXX_LIBRARIES ${CAPICXX_LIBRARY})

message(STATUS "CAPICXX_DEFINITIONS  = \"${CAPICXX_DEFINITIONS}\"")
message(STATUS "CAPICXX_INCLUDE_DIRS = \"${CAPICXX_INCLUDE_DIRS}\"")
message(STATUS "CAPICXX_LIBRARIES    = \"${CAPICXX_LIBRARIES}\"")
