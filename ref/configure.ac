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

AC_INIT([capic-ref], [0.2.0])
AC_COPYRIGHT([Copyright (c) 2015-2016 Visteon Corporation])

AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_PROG_CC
AC_PROG_INSTALL

PKG_CHECK_MODULES([LIBSYSTEMD], [libsystemd >= 219])
PKG_CHECK_MODULES([GLIB], [glib-2.0])
PKG_CHECK_MODULES([CAPIC], [capic >= 0.2])

MY_CFLAGS=""

AC_ARG_ENABLE(
    [logging],
    AS_HELP_STRING([--disable-logging], [disable loging output @<:@default=enable@:>@]),
    [], [enable_logging=yes])
AS_IF(
    [test "x$enable_logging" = "xyes"],
    MY_CFLAGS="$MY_CFLAGS -DENABLE_LOGGING=1")

AC_ARG_ENABLE(
    [simple],
    AS_HELP_STRING(
        [--disable-simple],
        [disable building reference example simple @<:@default=enable@:>@]),
    [], [enable_simple=yes])
AM_CONDITIONAL(HAVE_SIMPLE, [test "x$enable_simple" = "xyes"])

AC_ARG_ENABLE(
    [game],
    AS_HELP_STRING(
        [--disable-game],
        [disable building reference example game @<:@default=enable@:>@]),
    [], [enable_game=yes])
AM_CONDITIONAL(HAVE_GAME, [test "x$enable_game" = "xyes"])

AC_ARG_ENABLE(
    [smartie],
    AS_HELP_STRING(
        [--disable-smartie],
        [disable building reference example smartie @<:@default=enable@:>@]),
    [], [enable_smartie=yes])
AM_CONDITIONAL(HAVE_SMARTIE, [test "x$enable_smartie" = "xyes"])

MY_CFLAGS="$MY_CFLAGS \
-Wall \
-Wextra \
-Werror \
"
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
    simple:    ${enable_simple}
    game:      ${enable_game}
    smartie:   ${enable_smartie}
])
