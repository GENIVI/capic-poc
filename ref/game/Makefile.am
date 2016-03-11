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

AM_CFLAGS = $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS) $(MY_CFLAGS)
AM_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)

bin_PROGRAMS = player ball

player_CFLAGS = $(GLIB_CFLAGS) $(AM_CFLAGS)
player_LDFLAGS = $(GLIB_LIBS) $(AM_LDFLAGS)
player_SOURCES = \
	src/player.c \
	src-gen/client-Ball.c \
	src-gen/client-Ball.h

ball_SOURCES = \
	src/ball.c \
	src-gen/server-Ball.c \
	src-gen/server-Ball.h
