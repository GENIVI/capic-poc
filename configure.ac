# SPDX license identifier: MPL-2.0
# Copyright (C) 2015-2016, Visteon Corp.
# Author: Pavel Konopelko, pkonopel@visteon.com
#
# This file is part of Common API C
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), version 2.0.
# If a copy of the MPL was not distributed with this file,
# you can obtain one at http://mozilla.org/MPL/2.0/.
# For further information see http://www.genivi.org/.

AC_INIT([capic], [0.2.0])
AC_COPYRIGHT([Copyright (c) 2015-2016 Visteon Corporation])

AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_PROG_CC
AM_PROG_AR
AC_PROG_INSTALL
LT_PREREQ([2.2])
LT_INIT([disable-static])

PKG_CHECK_MODULES([LIBSYSTEMD], [libsystemd >= 219])
AC_CHECK_LIB(
    [systemd], [sd_bus_open],
    [dummy=yes], [AC_MSG_ERROR([libsystemd must have sd-bus library enabled])])
AC_CHECK_LIB(
    [systemd], [sd_bus_get_scope],
    [AC_DEFINE([HAVE_SD_BUS_GET_SCOPE], [1],
        [Define to 1 if libsystemd supports sd_bus_get_scope() introduced in v221])],
    [dummy=yes])
AC_CHECK_DECLS(
    [SD_EVENT_INITIAL], [], [],
    [[#include <systemd/sd-bus.h>
      #include <systemd/sd-event.h>]])

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile capic.pc])
AC_OUTPUT
