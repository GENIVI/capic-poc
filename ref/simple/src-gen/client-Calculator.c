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

#include "src-gen/client-Calculator.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <capic/backend.h>
#include <capic/dbus-private.h>
#include <capic/log.h>


struct cc_client_Calculator {
    struct cc_instance *instance;
    void *data;
    cc_Calculator_split_reply_t split_reply_callback;
    sd_bus_slot *split_reply_slot;
};


int cc_Calculator_split(
    struct cc_client_Calculator *instance, double value, int32_t *whole, int32_t *fraction)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;
    sd_bus_message *reply = NULL;
    sd_bus_error error = SD_BUS_ERROR_NULL;

    CC_LOG_DEBUG("invoked cc_Calculator_split()\n");
    assert(instance);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->split_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->split_reply_callback);

    result = sd_bus_call_method(
        i->backend->bus, i->service, i->path, i->interface,
        "split", &error, &reply, "d", value);
    if (result < 0) {
        CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_read(reply, "ii", whole, fraction);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("returning whole=%d, fraction=%d\n", *whole, *fraction);

fail:
    sd_bus_error_free(&error);
    reply = sd_bus_message_unref(reply);
    message = sd_bus_message_unref(message);

    return result;
}

static int cc_Calculator_split_reply_thunk(
    sd_bus *bus, sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
{
    int result = 0;
    struct cc_client_Calculator *ii = (struct cc_client_Calculator *) userdata;
    int32_t whole = 0, fraction = 0;

    CC_LOG_DEBUG("invoked cc_Calculator_split_reply_thunk()\n");
    assert(ii);
    assert(ii->split_reply_callback);
    assert(ii->split_reply_slot == sd_bus_get_current_slot(bus));
    result = sd_bus_message_get_errno(message);
    if (result != 0) {
        CC_LOG_ERROR("failed to receive response: %s\n", strerror(result));
        goto finish;
    }
    result = sd_bus_message_read(message, "ii", &whole, &fraction);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto finish;
    }
    CC_LOG_DEBUG("invoking callback in cc_Calculator_split_reply_thunk()\n");
    CC_LOG_DEBUG("with whole=%d, fraction=%d\n", whole, fraction);
    ii->split_reply_callback(ii, whole, fraction);
    result = 1;

finish:
    ii->split_reply_callback = NULL;
    ii->split_reply_slot = sd_bus_slot_unref(ii->split_reply_slot);

    return result;
}

int cc_Calculator_split_async(
    struct cc_client_Calculator *instance, double value,
    cc_Calculator_split_reply_t callback)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;

    CC_LOG_DEBUG("invoked cc_Calculator_split_async()\n");
    assert(instance);
    assert(callback);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->split_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->split_reply_callback);

    result = sd_bus_message_new_method_call(
        i->backend->bus, &message, i->service, i->path, i->interface, "split");
    if (result < 0) {
        CC_LOG_ERROR("unable to create message: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_append(message, "d", value);
    if (result < 0) {
        CC_LOG_ERROR("unable to append message method arguments: %s\n", strerror(-result));
        goto fail;
    }

    result = sd_bus_call_async(
        i->backend->bus, &instance->split_reply_slot, message,
        &cc_Calculator_split_reply_thunk, instance, CC_DBUS_ASYNC_CALL_TIMEOUT_USEC);
    if (result < 0) {
        CC_LOG_ERROR("unable to issue method call: %s\n", strerror(-result));
        goto fail;
    }
    instance->split_reply_callback = callback;

fail:
    message = sd_bus_message_unref(message);

    return result;
}

int cc_client_Calculator_new(
    const char *address, void *data, struct cc_client_Calculator **instance)
{
    int result;
    struct cc_client_Calculator *ii;

    CC_LOG_DEBUG("invoked cc_client_Calculator_new\n");
    assert(address);
    assert(instance);

    ii = (struct cc_client_Calculator *) calloc(1, sizeof(*ii));
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
    ii = cc_client_Calculator_free(ii);
    return result;
}

struct cc_client_Calculator *cc_client_Calculator_free(
    struct cc_client_Calculator *instance)
{
    CC_LOG_DEBUG("invoked cc_client_Calculator_free()\n");
    if (instance) {
        instance->split_reply_slot = sd_bus_slot_unref(
            instance->split_reply_slot);
        instance->instance = cc_instance_free(instance->instance);
        /* User is responsible for memory management of data. */
        free(instance);
    }
    return NULL;
}

void *cc_client_Calculator_get_data(struct cc_client_Calculator *instance)
{
    assert(instance);
    return instance->data;
}
