# SPDX license identifier: MPL-2.0
# Copyright (C) 2015, Visteon Corp.
# Author: Pavel Konopelko, pkonopel@visteon.com
#
# This file is part of Common API C
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), version 2.0.
# If a copy of the MPL was not distributed with this file,
# you can obtain one at http://mozilla.org/MPL/2.0/.
# For further information see http://www.genivi.org/.

bin_PROGRAMS = simpleclient simpleserver

simpleclient_CFLAGS = $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS) -Wall -Werror
simpleclient_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)
simpleclient_SOURCES = \
	src/simpleclient.c \
	src-gen/client-Calculator.c \
	src-gen/client-Calculator.h

simpleserver_CFLAGS = $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS) -Wall -Werror
simpleserver_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)
simpleserver_SOURCES = \
	src/simpleserver.c \
	src-gen/server-Calculator.c \
	src-gen/server-Calculator.h
