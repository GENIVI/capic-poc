/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2015, Visteon Corp.
 * Author: Pavel Konopelko, pkonopel@visteon.com
 *
 * This file is part of Common API C
 *
 * This Source Code Form is subject to the terms of the
 * Mozilla Public License (MPL), version 2.0.
 * If a copy of the MPL was not distributed with this file,
 * you can obtain one at http://mozilla.org/MPL/2.0/.
 * For further information see http://www.genivi.org/.
 */

#ifndef INCLUDED_CC_DBUS_PRIVATE
#define INCLUDED_CC_DBUS_PRIVATE

#include <systemd/sd-bus.h>
#include <systemd/sd-event.h>


#ifdef __cplusplus
extern "C" {
#endif

/* Assume the stable sd-bus and sd-event API by default. */
#if !defined(CC_SD_API_VERSION)
#define CC_SD_API_VERSION 221
#endif

/* Callback signature sd_bus_message_handler_t changed between the version 219
 * and 220 to remove the first argument 'sd_bus *bus'.
 */
#if CC_SD_API_VERSION >= 220
#define CC_IGNORE_BUS_ARG
#else
#define CC_IGNORE_BUS_ARG sd_bus __attribute__ ((unused)) *b__,
#endif

enum {
    CC_DBUS_ASYNC_CALL_TIMEOUT_USEC = 2000 * 1000ULL
};

struct cc_backend {
    sd_bus *bus;
    sd_event *event;
};

struct cc_instance {
    struct cc_backend *backend;
    const char *service;
    const char *path;
    const char *interface;
    char address[];
};

struct cc_event_context {
    sd_event *event;
};


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_CC_DBUS_PRIVATE */
