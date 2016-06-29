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

AM_CPPFLAGS = \
	-I$(top_srcdir)/src \
	-I$(top_builddir) \
	$(LIBSYSTEMD_CFLAGS)

AM_CFLAGS = \
	$(MY_CFLAGS) \
	-fvisibility=hidden

lib_LTLIBRARIES = libcapic.la

libcapic_la_LDFLAGS = \
	-no-undefined \
	-version-info 0:0:0

pkginclude_HEADERS = \
	src/capic/backend.h \
	src/capic/log.h \
	src/capic/dbus-private.h

libcapic_la_SOURCES = \
	$(pkginclude_HEADERS) \
	src/private.h \
	src/backend.c

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = capic.pc

MAINTAINERCLEANFILES = \
        $(GITIGNORE_MAINTAINERCLEANFILES_TOPLEVEL) \
        $(GITIGNORE_MAINTAINERCLEANFILES_MAKEFILE_IN) \
        $(GITIGNORE_MAINTAINERCLEANFILES_M4_LIBTOOL) \
        configure \
	Makefile.in \
        $(NULL)

-include $(top_srcdir)/git.mk
