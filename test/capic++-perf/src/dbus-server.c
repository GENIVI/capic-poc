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

#include <dbus/dbus.h>


static void takeNoArgs(DBusConnection *bus, DBusMessage *message)
{
    DBusMessage *reply = NULL;

    reply = dbus_message_new_method_return(message);
    if (!reply) {
        printf("insufficient memory\n");
        goto fail;
    }
    if (!dbus_connection_send(bus, reply, NULL)) {
        printf("insufficient memory\n");
        goto fail;
    }
    dbus_connection_flush(bus);

fail:
    if (reply)
        dbus_message_unref(reply);
}

static void take40ByteArgs(DBusConnection *bus, DBusMessage *message)
{
    DBusMessage *reply = NULL;
    DBusError error;
    int32_t in1;
    double in2, in3, in41, in42;
    uint32_t in43;

    dbus_error_init(&error);

    if (!dbus_message_get_args(
            message, &error, DBUS_TYPE_INT32, &in1, DBUS_TYPE_DOUBLE, &in2,
            DBUS_TYPE_DOUBLE, &in3, DBUS_TYPE_DOUBLE, &in41, DBUS_TYPE_DOUBLE,
            &in42, DBUS_TYPE_UINT32, &in43, DBUS_TYPE_INVALID))
    {
        printf("unable to get method args: %s -- %s\n", error.name, error.message);
        goto fail;
    }
    reply = dbus_message_new_method_return(message);
    if (!reply) {
        printf("insufficient memory\n");
        goto fail;
    }
    if (!dbus_message_append_args(
            reply, DBUS_TYPE_INT32, &in1, DBUS_TYPE_DOUBLE, &in2,
            DBUS_TYPE_DOUBLE, &in3, DBUS_TYPE_DOUBLE, &in41, DBUS_TYPE_DOUBLE,
            &in42, DBUS_TYPE_UINT32, &in43, DBUS_TYPE_INVALID))
    {
        printf("unable to append message arg\n");
        goto fail;
    }

    if (!dbus_connection_send(bus, reply, NULL)) {
        printf("insufficient memory\n");
        goto fail;
    }
    dbus_connection_flush(bus);

fail:
    if (reply)
        dbus_message_unref(reply);
}


int main(int argc, char *argv[])
{
    DBusError error;
    DBusConnection *bus = NULL;
    DBusMessage *message;
    int result;
    (void) argc;

    dbus_error_init(&error);

    printf("Started %s\n", argv[0]);
    bus = dbus_bus_get_private(DBUS_BUS_SYSTEM, &error);
    if (!bus || dbus_error_is_set(&error)) {
        printf("unable to connect to bus: %s -- %s\n", error.name, error.message);
        return EXIT_FAILURE;
    }
    result = dbus_bus_request_name(
        bus, "org.genivi.capic.TestPerf", DBUS_NAME_FLAG_DO_NOT_QUEUE, &error);
    if (result < 1 || result != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER) {
        printf("unable to request name: %s -- %s\n", error.name, error.message);
        goto fail;
    }

    printf("entering main loop...\n");
    for (;;) {
        if (!dbus_connection_read_write(bus, -1)) {
            printf("connection was terminated\n");
            goto fail;
        }
        while ((message = dbus_connection_pop_message(bus)) != NULL) {
            if (message == NULL)
                break;

            if (dbus_message_is_method_call(
                    message, "org.genivi.capic.TestPerf", "takeNoArgs"))
            {
                takeNoArgs(bus, message);
            } else if (dbus_message_is_method_call(
                    message, "org.genivi.capic.TestPerf", "take40ByteArgs"))
            {
                take40ByteArgs(bus, message);
            }

            dbus_message_unref(message);
        }
    }

fail:
    if (bus)
        dbus_connection_unref(bus);
    dbus_error_free(&error);

    printf("exiting %s\n", argv[0]);

    return EXIT_SUCCESS;
}
