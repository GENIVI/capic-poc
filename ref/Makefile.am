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
	-I $(top_srcdir)/simple \
	-I $(top_srcdir)/game \
	-I $(top_srcdir)/smartie

AM_CFLAGS = $(LIBSYSTEMD_CFLAGS) $(CAPIC_CFLAGS) $(MY_CFLAGS)
AM_LDFLAGS = $(LIBSYSTEMD_LIBS) $(CAPIC_LIBS)

bin_PROGRAMS =

if HAVE_SIMPLE
bin_PROGRAMS += simpleclient simpleserver

simpleclient_SOURCES = \
	simple/src/simpleclient.c \
	simple/src-gen/client-Calculator.c \
	simple/src-gen/client-Calculator.h

simpleserver_SOURCES = \
	simple/src/simpleserver.c \
	simple/src-gen/server-Calculator.c \
	simple/src-gen/server-Calculator.h
endif

if HAVE_GAME
bin_PROGRAMS += player ball

player_CFLAGS = $(GLIB_CFLAGS) $(AM_CFLAGS)
player_LDFLAGS = $(GLIB_LIBS) $(AM_LDFLAGS)
player_SOURCES = \
	game/src/player.c \
	game/src-gen/client-Ball.c \
	game/src-gen/client-Ball.h

ball_SOURCES = \
	game/src/ball.c \
	game/src-gen/server-Ball.c \
	game/src-gen/server-Ball.h
endif

if HAVE_SMARTIE
bin_PROGRAMS += smartalice smartbob

smartalice_SOURCES = \
	smartie/src/smartalice.c \
	smartie/src-gen/server-Smartie.c \
	smartie/src-gen/server-Smartie.h \
	smartie/src-gen/client-Smartie.c \
	smartie/src-gen/client-Smartie.h

smartbob_SOURCES = \
	smartie/src/smartbob.c \
	smartie/src-gen/server-Smartie.c \
	smartie/src-gen/server-Smartie.h \
	smartie/src-gen/client-Smartie.c \
	smartie/src-gen/client-Smartie.h
endif
