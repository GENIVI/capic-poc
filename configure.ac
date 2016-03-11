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

AC_ARG_ENABLE(
    [logging],
    AS_HELP_STRING([--disable-logging], [disable loging output @<:@default=enable@:>@]),
    [], [enable_logging=yes])
AS_IF(
    [test "x$enable_logging" = "xyes"],
    [AC_DEFINE(ENABLE_LOGGING, [1], [Define to enable loging output])])

PKG_CHECK_MODULES([LIBSYSTEMD], [libsystemd >= 219])
AC_CHECK_LIB(
    [systemd], [sd_bus_open],
    [dummy=yes], [AC_MSG_ERROR([libsystemd must have sd-bus library enabled])])
AC_CHECK_LIB(
    [systemd], [sd_bus_get_scope],
    [AC_DEFINE(
        [HAVE_SD_BUS_GET_SCOPE], [1],
        [Define if libsystemd supports sd_bus_get_scope() introduced in v221])],
    [dummy=yes])
AC_CHECK_DECLS(
    [SD_EVENT_INITIAL], [], [],
    [[#include <systemd/sd-bus.h>
      #include <systemd/sd-event.h>]])

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile capic.pc])
AC_OUTPUT

AC_MSG_RESULT([
    $PACKAGE_NAME $VERSION

    logging: ${enable_logging}
])
