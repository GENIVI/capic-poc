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

#include "src-gen/client-Ball.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <capic/backend.h>
#include <capic/dbus-private.h>
#include <capic/log.h>


struct cc_client_Ball {
    struct cc_instance *instance;
    void *data;
    cc_Ball_grab_reply_t grab_reply_callback;
    sd_bus_slot *grab_reply_slot;
};


int cc_Ball_grab(struct cc_client_Ball *instance, bool *success)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;
    sd_bus_message *reply = NULL;
    sd_bus_error error = SD_BUS_ERROR_NULL;
    int success_int;

    CC_LOG_DEBUG("invoked cc_Ball_grab()\n");
    assert(instance);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->grab_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->grab_reply_callback);

    result = sd_bus_call_method(
        i->backend->bus, i->service, i->path, i->interface, "grab", &error, &reply, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_read(reply, "b", &success_int);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto fail;
    }
    *success = !!success_int;
    CC_LOG_DEBUG("returning success=%d\n", (int) *success);

fail:
    sd_bus_error_free(&error);
    reply = sd_bus_message_unref(reply);
    message = sd_bus_message_unref(message);

    return result;
}

static int cc_Ball_grab_reply_thunk(
    CC_IGNORE_BUS_ARG sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
{
    int result = 0;
    sd_bus *bus;
    struct cc_client_Ball *ii = (struct cc_client_Ball *) userdata;
    int success_int;

    CC_LOG_DEBUG("invoked cc_Ball_grab_reply_thunk()\n");
    assert(message);
    bus = sd_bus_message_get_bus(message);
    assert(bus);
    assert(ii);
    assert(ii->grab_reply_callback);
    assert(ii->grab_reply_slot == sd_bus_get_current_slot(bus));
    result = sd_bus_message_get_errno(message);
    if (result != 0) {
        CC_LOG_ERROR("failed to receive response: %s\n", strerror(result));
        goto finish;
    }
    result = sd_bus_message_read(message, "b", &success_int);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto finish;
    }
    CC_LOG_DEBUG("invoking callback in cc_Ball_grab_reply_thunk()\n");
    CC_LOG_DEBUG("with success=%d\n", !!success_int);
    ii->grab_reply_callback(ii, !!success_int);
    result = 1;

finish:
    ii->grab_reply_callback = NULL;
    ii->grab_reply_slot = sd_bus_slot_unref(ii->grab_reply_slot);

    return result;
}

int cc_Ball_grab_async(struct cc_client_Ball *instance, cc_Ball_grab_reply_t callback)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;

    CC_LOG_DEBUG("invoked cc_Ball_grab_async()\n");
    assert(instance);
    assert(callback);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->grab_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->grab_reply_callback);

    result = sd_bus_message_new_method_call(
        i->backend->bus, &message, i->service, i->path, i->interface, "grab");
    if (result < 0) {
        CC_LOG_ERROR("unable to create message: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_append(message, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to append message method arguments: %s\n", strerror(-result));
        goto fail;
    }

    result = sd_bus_call_async(
        i->backend->bus, &instance->grab_reply_slot, message, &cc_Ball_grab_reply_thunk,
        instance, CC_DBUS_ASYNC_CALL_TIMEOUT_USEC);
    if (result < 0) {
        CC_LOG_ERROR("unable to issue method call: %s\n", strerror(-result));
        goto fail;
    }
    instance->grab_reply_callback = callback;

fail:
    message = sd_bus_message_unref(message);

    return result;
}

int cc_Ball_drop(struct cc_client_Ball *instance)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;

    CC_LOG_DEBUG("invoked cc_Ball_drop()\n");
    assert(instance);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    result = sd_bus_message_new_method_call(
        i->backend->bus, &message, i->service, i->path, i->interface, "drop");
    if (result < 0) {
        CC_LOG_ERROR("unable to create message: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_set_expect_reply(message, 0);
    if (result < 0) {
        CC_LOG_ERROR("unable to flag message no-reply-expected: %s\n", strerror(-result));
        goto fail;
    }
    /* Setting cookie=NULL in sd_bus_send() call makes the previous one redundant */
    result = sd_bus_send(i->backend->bus, message, NULL);
    if (result < 0) {
        CC_LOG_ERROR("unable to send message: %s\n", strerror(-result));
        goto fail;
    }

fail:
    message = sd_bus_message_unref(message);

    return result;
}

int cc_client_Ball_new(const char *address, void *data, struct cc_client_Ball **instance)
{
    int result;
    struct cc_client_Ball *ii;

    CC_LOG_DEBUG("invoked cc_client_Ball_new\n");
    assert(address);
    assert(instance);

    ii = (struct cc_client_Ball *) calloc(1, sizeof(*ii));
    if (!ii) {
        CC_LOG_ERROR("failed to allocate instance memory\n");
        return -ENOMEM;
    }

    result = cc_instance_new(address, false, &ii->instance);
    if (result < 0) {
        CC_LOG_ERROR("failed to create instance: %s\n", strerror(-result));
        goto fail;
    }
    ii->data = data;

    *instance = ii;
    return 0;

fail:
    ii = cc_client_Ball_free(ii);
    return result;
}

struct cc_client_Ball *cc_client_Ball_free(struct cc_client_Ball *instance)
{
    CC_LOG_DEBUG("invoked cc_client_Ball_free()\n");
    if (instance) {
        instance->grab_reply_slot = sd_bus_slot_unref(instance->grab_reply_slot);
        instance->instance = cc_instance_free(instance->instance);
        /* User is responsible for memory management of data. */
        free(instance);
    }
    return NULL;
}

void *cc_client_Ball_get_data(struct cc_client_Ball *instance)
{
    assert(instance);
    return instance->data;
}
