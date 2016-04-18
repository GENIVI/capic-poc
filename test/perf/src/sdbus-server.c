/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2016, Visteon Corp.
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#include <systemd/sd-bus.h>


static int method_takeNoArgs(
    sd_bus_message *message, void *userdata, sd_bus_error *error)
{
    int result;
    (void) userdata;
    (void) error;

    result = sd_bus_message_read(message, "");
    if (result < 0) {
        fprintf(stderr, "unable to parse parameters: %s\n", strerror(-result));
        return result;
    }

    return sd_bus_reply_method_return(message, "");
}

static int method_take40ByteArgs(
    sd_bus_message *message, void *userdata, sd_bus_error *error)
{
    int result;
    int32_t in1;
    double in2, in3, in41, in42;
    uint32_t in43;
    (void) userdata;
    (void) error;

    result = sd_bus_message_read(
        message, "iddddu", &in1, &in2, &in3, &in41, &in42, &in43);
    if (result < 0) {
        fprintf(stderr, "unable to parse parameters: %s\n", strerror(-result));
        return result;
    }

    return sd_bus_reply_method_return(
        message, "iddddu", in1, in2, in3, in41, in42, in43);
}

static const sd_bus_vtable testPerf_vtable[] = {
    SD_BUS_VTABLE_START(0),
    SD_BUS_METHOD("takeNoArgs", "", "", method_takeNoArgs, SD_BUS_VTABLE_UNPRIVILEGED),
    SD_BUS_METHOD("take40ByteArgs", "iddddu", "iddddu", method_take40ByteArgs, SD_BUS_VTABLE_UNPRIVILEGED),
    SD_BUS_VTABLE_END
};


int main(int argc, char *argv[])
{
    int result = 0;
    sd_bus_slot *slot = NULL;
    sd_bus *bus = NULL;
    (void) argc;

    printf("Started %s\n", argv[0]);
    result = sd_bus_open_system(&bus);
    if (result < 0) {
        printf("unable to connect to system bus: %s\n", strerror(-result));
        goto fail;
    }

    result = sd_bus_request_name(bus, "org.genivi.capic.TestPerf", 0);
    if (result < 0) {
        printf("unable to acquire service name: %s\n", strerror(-result));
        goto fail;
    }

    result = sd_bus_add_object_vtable(
        bus, &slot, "/instance", "org.genivi.capic.TestPerf", testPerf_vtable, NULL);
    if (result < 0) {
        printf("unable to create server instance: %s\n", strerror(-result));
        goto fail;
    }

    printf("entering main loop...\n");
    for (;;) {
        result = sd_bus_process(bus, NULL);
        if (result < 0) {
            fprintf(stderr, "failed to process bus requests: %s\n", strerror(-result));
            goto fail;
        }
        if (result > 0)
            continue;

        result = sd_bus_wait(bus, (uint64_t) -1);
        if (result < 0) {
            fprintf(stderr, "failed waiting on bus: %s\n", strerror(-result));
            goto fail;
        }
    }

fail:
    sd_bus_slot_unref(slot);
    sd_bus_unref(bus);

    printf("exiting %s\n", argv[0]);

    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
