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
#include <stdint.h>
#include <unistd.h>
#include <time.h>

#include <dbus/dbus.h>


static int32_t in1 = 12;
static double in2 = 34.0, in3 = 0.56;
static double in41 = 0.78, in42 = 91.0;
static uint32_t in43 = 1112;

static int32_t out1;
static double out2, out3;
static double out41, out42;
static uint32_t out43;


int main(int argc, char *argv[])
{
    int message_count = 10000, message_payload = 0;
    int option, result = 0;
    DBusError error;
    DBusConnection *bus = NULL;
    DBusMessage *message = NULL;
    DBusMessage *reply = NULL;
    struct timespec start, stop;
    double seconds;
    int counter;

    while ((option = getopt(argc, argv, "m:p")) != -1) {
        switch (option) {
        case 'm':
            message_count = atoi(optarg);
            break;
        case 'p':
            message_payload = 1;
            break;
        default:
            printf("Usage: %s [-m count] [-p]\n", argv[0]);
            printf("-m count  send count messages\n");
            printf("-p        send messages with payload\n");
            return EXIT_FAILURE;
        }
    }

    dbus_error_init(&error);

    printf("Started %s\n", argv[0]);
    bus = dbus_bus_get(DBUS_BUS_SYSTEM, &error);
    if (dbus_error_is_set(&error)) {
        printf("unable to connect to bus: %s -- %s\n", error.name, error.message);
        return EXIT_FAILURE;
    }

    printf("starting test...\n");
    clock_gettime(CLOCK_REALTIME, &start);

    if (message_payload) {
        for (counter = message_count; counter > 0; --counter) {
            message = dbus_message_new_method_call(
                "org.genivi.capic.TestPerf", "/instance", "org.genivi.capic.TestPerf",
                "take40ByteArgs");
            if (message == NULL) {
                printf("unable to create method message\n");
                result = -1;
                goto fail;
            }
            if (!dbus_message_append_args(
                    message, DBUS_TYPE_INT32, &in1, DBUS_TYPE_DOUBLE, &in2,
                    DBUS_TYPE_DOUBLE, &in3, DBUS_TYPE_DOUBLE, &in41,
                    DBUS_TYPE_DOUBLE, &in42, DBUS_TYPE_UINT32, &in43,
                    DBUS_TYPE_INVALID))
            {
                printf("unable to append message arg\n");
                result = -1;
                goto fail;
            }
            reply = dbus_connection_send_with_reply_and_block(bus, message, -1, &error);
            if (!reply) {
                printf("unable to send with reply: %s -- %s\n", error.name, error.message);
                result = -1;
                goto fail;
            }
            if (dbus_message_get_type(reply) != DBUS_MESSAGE_TYPE_METHOD_RETURN) {
                printf("unexpected reply received for method invocation\n");
                result = -1;
                goto fail;
            }
            if (!dbus_message_get_args(
                    reply, &error, DBUS_TYPE_INT32, &out1, DBUS_TYPE_DOUBLE,
                    &out2, DBUS_TYPE_DOUBLE, &out3, DBUS_TYPE_DOUBLE, &out41,
                    DBUS_TYPE_DOUBLE, &out42, DBUS_TYPE_UINT32, &out43,
                    DBUS_TYPE_INVALID))
            {
                printf("unable to get reply args: %s -- %s\n", error.name, error.message);
                result = -1;
                goto fail;
            }
            in1 = out1;
            in2 = out2;
            in3 = out3;
            in41 = out41;
            in42 = out42;
            in43 = out43;

            dbus_message_unref(reply);
            dbus_message_unref(message);
            message = NULL;
            reply = NULL;
        }
    } else {
        for (counter = message_count; counter > 0; --counter) {
            message = dbus_message_new_method_call(
                "org.genivi.capic.TestPerf", "/instance", "org.genivi.capic.TestPerf",
                "takeNoArgs");
            if (message == NULL) {
                printf("unable to create method message\n");
                result = -1;
                goto fail;
            }
            reply = dbus_connection_send_with_reply_and_block(bus, message, -1, &error);
            if (!reply) {
                printf("unable to send with reply: %s -- %s\n", error.name, error.message);
                result = -1;
                goto fail;
            }

            dbus_message_unref(reply);
            dbus_message_unref(message);
            message = NULL;
            reply = NULL;
        }
    }

    clock_gettime(CLOCK_REALTIME, &stop);
    seconds = stop.tv_sec - start.tv_sec + (stop.tv_nsec - start.tv_nsec) / 1.0e+9;
    printf("test completed\n");
    printf("message payload [bytes]: %d\n", message_payload ? 40 : 0);
    printf("sync messages sent:      %d\n", message_count);
    printf("messages per [s]:        %g\n", message_count / seconds);

fail:

    if (reply)
        dbus_message_unref(reply);
    if (message)
        dbus_message_unref(message);
    if (bus)
        dbus_connection_unref(bus);
    dbus_error_free(&error);

    printf("exiting %s\n", argv[0]);

    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
