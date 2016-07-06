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

AC_INIT([test-perf], [0.2.1])
AC_COPYRIGHT([Copyright (c) 2016 Visteon Corporation])

AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_PROG_CC
AC_PROG_INSTALL
AC_PROG_AWK

PKG_CHECK_MODULES([LIBSYSTEMD], [libsystemd >= 219])
PKG_CHECK_MODULES([CAPIC], [capic >= 0.2.1])

MY_CFLAGS=""

AC_ARG_ENABLE(
    [logging],
    AS_HELP_STRING([--disable-logging], [disable loging output @<:@default=enable@:>@]),
    [], [enable_logging=yes])
AS_IF(
    [test "x$enable_logging" = "xyes"],
    MY_CFLAGS="$MY_CFLAGS -DENABLE_LOGGING=1")

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
AC_CONFIG_FILES([Makefile])
AC_OUTPUT

AC_MSG_RESULT([
    $PACKAGE_NAME $VERSION

    compiler:  ${CC}
    CPPFLAGS:  ${CPPFLAGS}
    CFLAGS:    ${MY_CFLAGS} ${CFLAGS}
    LDFLAGS:   ${LDFLAGS}

    logging:   ${enable_logging}
])
