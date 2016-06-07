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
# * CAPICXX_VERSION - the provided version of CAPIC++
# * CAPICXX_DEFINITIONS - the compiler parameters to use with CAPIC++
# * CAPICXX_INCLUDE_DIRS - the list of directories with CAPIC++ include files
# * CAPICXX_LIBRARIES - the list of CAPIC++ libraries
# * CAPICXX_<component>_EXECUTABLE - the generator binary for each component
#   (by default only look for CORE and DBUS components)
#
# The list of supported components includes CORE and DBUS.  If no components
# are specified explicitly, the module searches for all available components.
#
# For developer builds, the variables CAPICXX_INCLUDE_DIR, CAPICXX_LIBRARY and
# CAPICXX_<component>_EXECUTABLE can be defined to override the values
# computed by this module.
##############################################################################


find_package(PkgConfig)
pkg_check_modules(CAPICXX_PC QUIET CommonAPI CommonAPI-DBus dbus-1)

# When no overrides were specified, use whatever pkg-config has found.
# Otherwise assume that the override has exactly the required version.
if (NOT CAPICXX_LIBRARY)
    set(CAPICXX_VERSION "${CAPICXX_PC_CommonAPI_VERSION}")
else()
    set(CAPICXX_VERSION "${CAPICXX_FIND_VERSION}")
endif()
set(CAPICXX_DEFINITION "${CAPICXX_DEFINITION} -pthread -std=c++11")
set(CAPICXX_INCLUDE_DIR ${CAPICXX_INCLUDE_DIR} ${CAPICXX_PC_INCLUDE_DIRS})
set(CAPICXX_LIBRARY ${CAPICXX_LIBRARY} ${CAPICXX_PC_LIBRARIES})


if (NOT CAPICXX_CORE_EXECUTABLE)
    find_program(CAPICXX_CORE_EXECUTABLE capicxx-core-gen)
endif()
if (NOT CAPICXX_DBUS_EXECUTABLE)
    find_program(CAPICXX_DBUS_EXECUTABLE capicxx-dbus-gen)
endif()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    CAPICXX
    REQUIRED_VARS CAPICXX_LIBRARY CAPICXX_INCLUDE_DIR
        CAPICXX_CORE_EXECUTABLE CAPICXX_DBUS_EXECUTABLE
    VERSION_VAR CAPICXX_VERSION
)

mark_as_advanced(CAPICXX_DEFINITION CAPICXX_INCLUDE_DIR CAPICXX_LIBRARY)

set(CAPICXX_DEFINITIONS ${CAPICXX_DEFINITION})
set(CAPICXX_INCLUDE_DIRS ${CAPICXX_INCLUDE_DIR})
set(CAPICXX_LIBRARIES ${CAPICXX_LIBRARY})
set(CAPICXX_VERSION_STRING ${CAPICXX_VERSION})

message(STATUS "CAPICXX_VERSION         = \"${CAPICXX_VERSION}\"")
message(STATUS "CAPICXX_DEFINITIONS     = \"${CAPICXX_DEFINITIONS}\"")
message(STATUS "CAPICXX_INCLUDE_DIRS    = \"${CAPICXX_INCLUDE_DIRS}\"")
message(STATUS "CAPICXX_LIBRARIES       = \"${CAPICXX_LIBRARIES}\"")
message(STATUS "CAPICXX_CORE_EXECUTABLE = \"${CAPICXX_CORE_EXECUTABLE}\"")
message(STATUS "CAPICXX_DBUS_EXECUTABLE = \"${CAPICXX_DBUS_EXECUTABLE}\"")
