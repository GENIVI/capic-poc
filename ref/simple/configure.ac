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

AC_INIT([ccref-simple], [0.2.0])
AC_COPYRIGHT([Copyright (c) 2015-2016 Visteon Corporation])

AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_PROG_CC
AC_PROG_INSTALL

PKG_CHECK_MODULES([LIBSYSTEMD], [libsystemd >= 219])
PKG_CHECK_MODULES([CAPIC], [capic >= 0.2])

AC_CONFIG_HEADERS(config.h)
AC_CONFIG_FILES([Makefile])
AC_OUTPUT
