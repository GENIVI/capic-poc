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

m4_define([capic_major], [0])
m4_define([capic_minor], [2])
m4_define([capic_micro], [1])
m4_define([capic_nano], [0])

m4_define([capic_base_version],
          [capic_major.capic_minor.capic_micro])

m4_define([capic_version],
          [m4_if(capic_nano, 0,
                [capic_base_version],
                [capic_base_version].[capic_nano])])

# Before making a release, the version info should be modified.
# Follow these instructions sequentially:
#   1. If the library source code has changed at all since the last update, then
#      increment revision (‘c:r:a’ becomes ‘c:r+1:a’).
#   2. If any interfaces have been added, removed, or changed since the last
#      update, increment current, and set revision to 0.
#   3. If any interfaces have been added since the last public release, then
#      increment age.
#   4. If any interfaces have been removed or changed since the last public
#      release, then set age to 0. Also increment capic_major.
m4_define([capic_lt_current], [0])
m4_define([capic_lt_revision], [2])
m4_define([capic_lt_age], [1])

m4_define([capic_lt_version],
[capic_lt_current:capic_lt_revision:capic_lt_age])

AC_PREREQ([2.62])
AC_INIT([capic], capic_version)
AC_CONFIG_AUX_DIR(config)
AM_MAINTAINER_MODE([enable])
AC_SUBST(CAPIC_VERSION,capic_version)
AC_SUBST(CAPIC_LT_VERSION,capic_lt_version)
AC_SUBST(CAPIC_API_VERSION,capic_major)

AC_COPYRIGHT([Copyright (c) 2015-2016 Visteon Corporation])

AC_CONFIG_MACRO_DIR([m4])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
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
