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

#include "src-gen/server-Ball.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>
#include <capic/backend.h>
#include <capic/dbus-private.h>
#include <capic/log.h>


struct cc_server_Ball {
    struct cc_instance *instance;
    void *data;
    const struct cc_server_Ball_impl *impl;
    struct sd_bus_slot *vtable_slot;
};


static int cc_Ball_grab_thunk(
    sd_bus *bus, sd_bus_message *m, void *userdata, sd_bus_error *error)
{
    int result = 0;
    struct cc_server_Ball *ii = (struct cc_server_Ball *) userdata;
    bool success = false;

    CC_LOG_DEBUG("invoked cc_Ball_grab_thunk()\n");
    assert(bus);
    assert(m);
    assert(ii && ii->impl);
    CC_LOG_DEBUG("with path='%s'\n", sd_bus_message_get_path(m));

    result = sd_bus_message_read(m, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to read method parameters: %s\n", strerror(-result));
        return result;
    }
    if (!ii->impl->grab) {
        CC_LOG_ERROR("unsupported method invoked: %s\n", "Ball.grab");
        sd_bus_error_set(
            error, SD_BUS_ERROR_NOT_SUPPORTED,
            "instance does not support method Ball.grab");
        sd_bus_reply_method_error(m, error);
        return -ENOTSUP;
    }
    result = ii->impl->grab(ii, &success);
    if (result < 0) {
        CC_LOG_ERROR("failed to execute method: %s\n", strerror(-result));
        sd_bus_error_setf(
            error, SD_BUS_ERROR_FAILED,
            "method implementation failed with error=%d", result);
        sd_bus_reply_method_error(m, error);
        return result;
    }
    result = sd_bus_reply_method_return(m, "b", success);
    if (result < 0) {
        CC_LOG_ERROR("unable to send method reply: %s\n", strerror(-result));
        return result;
    }

    /* Successful method invocation must return >0 */
    return 1;
}

static int cc_Ball_drop_thunk(
    sd_bus *bus, sd_bus_message *m, void *userdata, sd_bus_error *error)
{
    int result = 0;
    struct cc_server_Ball *ii = (struct cc_server_Ball *) userdata;

    CC_LOG_DEBUG("invoked cc_Ball_drop_thunk()\n");
    assert(bus);
    assert(m);
    assert(ii && ii->impl);
    CC_LOG_DEBUG("with path='%s'\n", sd_bus_message_get_path(m));

    result = sd_bus_message_read(m, "");
    if (result < 0) {
        CC_LOG_ERROR("unable to read method parameters: %s\n", strerror(-result));
        return result;
    }
    if (!ii->impl->drop) {
        CC_LOG_ERROR("unsupported method invoked: %s\n", "Ball.drop");
        sd_bus_error_set(
            error, SD_BUS_ERROR_NOT_SUPPORTED,
            "instance does not support method Ball.drop");
        sd_bus_reply_method_error(m, error);
        return -ENOTSUP;
    }
    result = ii->impl->drop(ii);
    if (result < 0) {
        CC_LOG_ERROR("failed to execute method: %s\n", strerror(-result));
        sd_bus_error_setf(
            error, SD_BUS_ERROR_FAILED,
            "method implementation failed with error=%d", result);
        sd_bus_reply_method_error(m, error);
        return result;
    }

    /* Successful method invocation must return >0 */
    return 1;
}

static const sd_bus_vtable vtable_Ball[] = {
    SD_BUS_VTABLE_START(0),
    SD_BUS_METHOD("grab", "", "b", &cc_Ball_grab_thunk, 0),
    SD_BUS_METHOD("drop", "", "", &cc_Ball_drop_thunk, 0),
    SD_BUS_VTABLE_END
};

int cc_server_Ball_new(
    const char *address, const struct cc_server_Ball_impl *impl, void *data,
    struct cc_server_Ball **instance)
{
    int result;
    struct cc_server_Ball *ii;
    struct cc_instance *i;

    CC_LOG_DEBUG("invoked cc_server_Ball_new\n");
    assert(address);
    assert(impl);
    assert(instance);

    ii = (struct cc_server_Ball *) calloc(1, sizeof(*ii));
    if (!ii) {
        CC_LOG_ERROR("failed to allocate instance memory\n");
        return -ENOMEM;
    }

    result = cc_instance_new(address, true, &i);
    if (result < 0) {
        CC_LOG_ERROR("failed to create instance: %s\n", strerror(-result));
        goto fail;
    }
    ii->instance = i;
    ii->impl = impl;
    ii->data = data;

    result = sd_bus_add_object_vtable(
        i->backend->bus, &ii->vtable_slot, i->path, i->interface, vtable_Ball, ii);
    if (result < 0) {
        CC_LOG_ERROR("unable to initialize instance vtable: %s\n", strerror(-result));
        goto fail;
    }

    *instance = ii;
    return 0;

fail:
    ii = cc_server_Ball_free(ii);
    return result;
}

struct cc_server_Ball *cc_server_Ball_free(struct cc_server_Ball *instance)
{
    CC_LOG_DEBUG("invoked cc_server_Ball_free()\n");
    if (instance) {
        instance->vtable_slot = sd_bus_slot_unref(instance->vtable_slot);
        instance->instance = cc_instance_free(instance->instance);
        /* User is resposible for memory management of impl and data. */
        free(instance);
    }
    return NULL;
}

void *cc_server_Ball_get_data(struct cc_server_Ball *instance)
{
    assert(instance);
    return instance->data;
}
