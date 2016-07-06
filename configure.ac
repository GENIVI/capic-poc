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

AC_INIT([capic], [0.2.1])
AC_COPYRIGHT([Copyright (c) 2015-2016 Visteon Corporation])

AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects silent-rules])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])
AC_PROG_CC
AM_PROG_AR
AC_PROG_INSTALL
AC_PROG_AWK
LT_PREREQ([2.2])
LT_INIT([disable-static])

MY_CFLAGS=""

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

MY_CFLAGS="$MY_CFLAGS \
-Wall \
-Wextra \
-Werror \
"
AS_IF(
    [test `${CC} -v 2>&1 | tail -n 1 | ${AWK} '{print $1}'` = gcc \
          -a `${CC} -dumpversion | ${AWK} '{print $1<5.0?"1":"0"}'` = 1],
    [MY_CFLAGS="$MY_CFLAGS -Wno-missing-field-initializers"])
AC_SUBST([MY_CFLAGS])

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile capic.pc])
AC_OUTPUT

AC_MSG_RESULT([
    $PACKAGE_NAME $VERSION

    compiler:  ${CC}
    CPPFLAGS:  ${CPPFLAGS}
    CFLAGS:    ${MY_CFLAGS} ${CFLAGS}
    LDFLAGS:   ${LDFLAGS}

    logging:   ${enable_logging}
])
