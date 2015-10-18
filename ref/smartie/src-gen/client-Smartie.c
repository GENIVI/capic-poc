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

#include "src-gen/client-Smartie.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <capic/backend.h>
#include <capic/dbus-private.h>
#include <capic/log.h>


struct cc_client_Smartie {
    struct cc_instance *instance;
    void *data;
    cc_Smartie_ring_reply_t ring_reply_callback;
    sd_bus_slot *ring_reply_slot;
    cc_Smartie_hangup_reply_t hangup_reply_callback;
    sd_bus_slot *hangup_reply_slot;
};


int cc_Smartie_ring(struct cc_client_Smartie *instance, int32_t *status)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;
    sd_bus_message *reply = NULL;
    sd_bus_error error = SD_BUS_ERROR_NULL;

    CC_LOG_DEBUG("invoked cc_Smartie_ring()\n");
    assert(instance);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->ring_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->ring_reply_callback);

    result = sd_bus_call_method(
        i->backend->bus, i->service, i->path, i->interface, "ring", &error, &reply, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_read(reply, "i", status);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("returning status=%d\n", *status);

fail:
    sd_bus_error_free(&error);
    reply = sd_bus_message_unref(reply);
    message = sd_bus_message_unref(message);

    return result;
}

static int cc_Smartie_ring_reply_thunk(
    CC_IGNORE_BUS_ARG sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
{
    int result = 0;
    sd_bus *bus;
    struct cc_client_Smartie *ii = (struct cc_client_Smartie *) userdata;
    int32_t status;

    CC_LOG_DEBUG("invoked cc_Smartie_ring_reply_thunk()\n");
    assert(message);
    bus = sd_bus_message_get_bus(message);
    assert(bus);
    assert(ii);
    assert(ii->ring_reply_callback);
    assert(ii->ring_reply_slot == sd_bus_get_current_slot(bus));
    result = sd_bus_message_get_errno(message);
    if (result != 0) {
        CC_LOG_ERROR("failed to receive response: %s\n", strerror(result));
        goto finish;
    }
    result = sd_bus_message_read(message, "i", &status);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto finish;
    }
    CC_LOG_DEBUG("invoking callback in cc_Smartie_ring_reply_thunk()\n");
    CC_LOG_DEBUG("with status=%d\n", status);
    ii->ring_reply_callback(ii, status);
    result = 1;

finish:
    ii->ring_reply_callback = NULL;
    ii->ring_reply_slot = sd_bus_slot_unref(ii->ring_reply_slot);

    return result;
}

int cc_Smartie_ring_async(
    struct cc_client_Smartie *instance, cc_Smartie_ring_reply_t callback)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;

    CC_LOG_DEBUG("invoked cc_Smartie_ring_async()\n");
    assert(instance);
    assert(callback);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->ring_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->ring_reply_callback);

    result = sd_bus_message_new_method_call(
        i->backend->bus, &message, i->service, i->path, i->interface, "ring");
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
        i->backend->bus, &instance->ring_reply_slot, message, &cc_Smartie_ring_reply_thunk,
        instance, CC_DBUS_ASYNC_CALL_TIMEOUT_USEC);
    if (result < 0) {
        CC_LOG_ERROR("unable to issue method call: %s\n", strerror(-result));
        goto fail;
    }
    instance->ring_reply_callback = callback;

fail:
    message = sd_bus_message_unref(message);

    return result;
}

int cc_Smartie_hangup(struct cc_client_Smartie *instance, int32_t *status)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;
    sd_bus_message *reply = NULL;
    sd_bus_error error = SD_BUS_ERROR_NULL;

    CC_LOG_DEBUG("invoked cc_Smartie_hangup()\n");
    assert(instance);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->hangup_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->hangup_reply_callback);

    result = sd_bus_call_method(
        i->backend->bus, i->service, i->path, i->interface, "hangup", &error, &reply, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_message_read(reply, "i", status);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("returning status=%d\n", *status);

fail:
    sd_bus_error_free(&error);
    reply = sd_bus_message_unref(reply);
    message = sd_bus_message_unref(message);

    return result;
}

static int cc_Smartie_hangup_reply_thunk(
    CC_IGNORE_BUS_ARG sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
{
    int result = 0;
    sd_bus *bus;
    struct cc_client_Smartie *ii = (struct cc_client_Smartie *) userdata;
    int32_t status;

    CC_LOG_DEBUG("invoked cc_Smartie_hangup_reply_thunk()\n");
    assert(message);
    bus = sd_bus_message_get_bus(message);
    assert(bus);
    assert(ii);
    assert(ii->hangup_reply_callback);
    assert(ii->hangup_reply_slot == sd_bus_get_current_slot(bus));
    result = sd_bus_message_get_errno(message);
    if (result != 0) {
        CC_LOG_ERROR("failed to receive response: %s\n", strerror(result));
        goto finish;
    }
    result = sd_bus_message_read(message, "i", &status);
    if (result < 0) {
        CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
        goto finish;
    }
    CC_LOG_DEBUG("invoking callback in cc_Smartie_hangup_reply_thunk()\n");
    CC_LOG_DEBUG("with status=%d\n", status);
    ii->hangup_reply_callback(ii, status);
    result = 1;

finish:
    ii->hangup_reply_callback = NULL;
    ii->hangup_reply_slot = sd_bus_slot_unref(ii->hangup_reply_slot);

    return result;
}

int cc_Smartie_hangup_async(
    struct cc_client_Smartie *instance, cc_Smartie_hangup_reply_t callback)
{
    int result = 0;
    struct cc_instance *i;
    sd_bus_message *message = NULL;

    CC_LOG_DEBUG("invoked cc_Smartie_hangup_async()\n");
    assert(instance);
    assert(callback);
    i = instance->instance;
    assert(i && i->backend && i->backend->bus);
    assert(i->service && i->path && i->interface);

    if (instance->hangup_reply_slot) {
        CC_LOG_ERROR("unable to call method with already pending reply\n");
        return -EBUSY;
    }
    assert(!instance->hangup_reply_callback);

    result = sd_bus_message_new_method_call(
        i->backend->bus, &message, i->service, i->path, i->interface, "hangup");
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
        i->backend->bus, &instance->hangup_reply_slot, message,
        &cc_Smartie_hangup_reply_thunk, instance, CC_DBUS_ASYNC_CALL_TIMEOUT_USEC);
    if (result < 0) {
        CC_LOG_ERROR("unable to issue method call: %s\n", strerror(-result));
        goto fail;
    }
    instance->hangup_reply_callback = callback;

fail:
    message = sd_bus_message_unref(message);

    return result;
}

int cc_client_Smartie_new(
    const char *address, void *data, struct cc_client_Smartie **instance)
{
    int result;
    struct cc_client_Smartie *ii;

    CC_LOG_DEBUG("invoked cc_client_Smartie_new\n");
    assert(address);
    assert(instance);

    ii = (struct cc_client_Smartie *) calloc(1, sizeof(*ii));
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
    ii = cc_client_Smartie_free(ii);
    return result;
}

struct cc_client_Smartie *cc_client_Smartie_free(struct cc_client_Smartie *instance)
{
    CC_LOG_DEBUG("invoked cc_client_Smartie_free()\n");
    if (instance) {
        instance->ring_reply_slot = sd_bus_slot_unref(instance->ring_reply_slot);
        instance->hangup_reply_slot = sd_bus_slot_unref(instance->hangup_reply_slot);
        instance->instance = cc_instance_free(instance->instance);
        /* User is responsible for memory management of data. */
        free(instance);
    }
    return NULL;
}

void *cc_client_Smartie_get_data(struct cc_client_Smartie *instance)
{
    assert(instance);
    return instance->data;
}
