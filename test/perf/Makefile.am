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

AM_CFLAGS = $(MY_CFLAGS)

bin_PROGRAMS = capic-client capic-server

capic_client_CFLAGS = $(AM_CFLAGS) $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS)
capic_client_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)
capic_client_SOURCES = \
	src/capic-client.c
nodist_capic_client_SOURCES = \
	src-gen/client-TestPerf.c \
	src-gen/client-TestPerf.h

capic_server_CFLAGS = $(AM_CFLAGS) $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS)
capic_server_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)
capic_server_SOURCES = \
	src/capic-server.c
nodist_capic_server_SOURCES = \
	src-gen/server-TestPerf.c \
	src-gen/server-TestPerf.h

BUILT_SOURCES = \
	src-gen/client-TestPerf.h \
	src-gen/server-TestPerf.h

CLEANFILES = src-gen/*.c src-gen/*.h

# capic-core-gen requires absolute filename as its argument
src-gen/client-%.c src-gen/client-%.h src-gen/server-%.c src-gen/server-%.h: %.fidl
	arg=$$(basename $<) ; capic-core-gen $(abs_srcdir)/$${arg}


bin_PROGRAMS += sdbus-client sdbus-server

sdbus_client_CFLAGS = $(AM_CFLAGS) $(LIBSYSTEMD_CFLAGS)
sdbus_client_LDFLAGS = $(LIBSYSTEMD_LIBS)
sdbus_client_SOURCES = \
	src/sdbus-client.c

sdbus_server_CFLAGS = $(AM_CFLAGS) $(LIBSYSTEMD_CFLAGS)
sdbus_server_LDFLAGS = $(LIBSYSTEMD_LIBS)
sdbus_server_SOURCES = \
	src/sdbus-server.c
