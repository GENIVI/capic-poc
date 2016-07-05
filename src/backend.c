/* SPDX license identifier: MPL-2.0
 * Copyright (C) 2015-2016, Visteon Corp.
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

#include "private.h"
#include <capic/backend.h>

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <capic/log.h>
#include <capic/dbus-private.h>


/* FIXME: allocate backend objects on explicit client request */
static struct cc_backend backend = {0};
static struct cc_event_context event_context = {0};


CC_PUBLIC int cc_backend_startup()
{
    int result = 0;
    sd_id128_t id;
    const char *scope, *unique;

    CC_LOG_DEBUG("invoked cc_backend_startup()\n");
    assert(!backend.bus);

    /*result = sd_bus_open_user(&backend.bus);*/
    result = sd_bus_open_system(&backend.bus);
    if (result < 0) {
        CC_LOG_ERROR("unable to open system bus: %s\n", strerror(-result));
        goto fail;
    }

    CC_LOG_DEBUG("connected to bus with:\n");
    result = sd_bus_get_scope(backend.bus, &scope);
    if (result < 0) {
        CC_LOG_ERROR("unable to get bus scope: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("scope=%s\n", scope);
    result = sd_bus_get_bus_id(backend.bus, &id);
    if (result < 0) {
        CC_LOG_ERROR("unable to get peer ID: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("peer_id=" SD_ID128_FORMAT_STR "\n", SD_ID128_FORMAT_VAL(id));
    result = sd_bus_get_unique_name(backend.bus, &unique);
    if (result < 0) {
        CC_LOG_ERROR("unable to get unique name: %s\n", strerror(-result));
        goto fail;
    }
    CC_LOG_DEBUG("unique_name=%s\n", unique);

    result = sd_event_new(&backend.event);
    if (result < 0) {
        CC_LOG_ERROR("unable to initialize default event loop: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_bus_attach_event(backend.bus, backend.event, 0);
    if (result < 0) {
        CC_LOG_ERROR("unable to attach bus to event loop: %s\n", strerror(-result));
        goto fail;
    }

    return result;

fail:
    cc_backend_shutdown();
    return result;
}

CC_PUBLIC void cc_backend_shutdown()
{
    CC_LOG_DEBUG("invoked cc_backend_shutdown()\n");

    if (backend.bus) {
        sd_bus_detach_event(backend.bus);
        sd_bus_flush(backend.bus);
        sd_bus_close(backend.bus);
    }
    /* FIXME: use sd_bus_flush_close_unref() introduced since v222 */
    backend.bus = sd_bus_unref(backend.bus);
    backend.event = sd_event_unref(backend.event);
}

CC_PUBLIC int cc_instance_new(
    const char *address, bool server, struct cc_instance **instance)
{
    int result = 0;
    struct cc_instance *i;
    size_t address_size;
    char *colon = NULL;

    CC_LOG_DEBUG("invoked cc_instance_new()\n");
    assert(address);
    assert(instance);
    CC_LOG_DEBUG("with address='%s', server=%d\n", address, (int) server);
    if (!backend.bus) {
        CC_LOG_ERROR("not connected to a bus\n");
        return -ENOTCONN;
    }

    address_size = strlen(address) + 1;
    i = (struct cc_instance *) calloc(1, sizeof(*i) + address_size);
    if (!i) {
        CC_LOG_ERROR("failed to allocate instance memory\n");
        return -ENOMEM;
    }

    i->backend = &backend;
    strncpy(i->address, address, address_size);
    /* Expect address to be a colon-separated tuple "service:path:interface" */
    i->service = i->address;
    colon = strchr(i->address, ':');
    if (!colon) {
        CC_LOG_ERROR("illegal instance address format\n");
        result = -EINVAL;
        goto fail;
    }
    *colon++ = '\0';
    i->path = colon;
    colon = strchr(colon, ':');
    if (!colon) {
        CC_LOG_ERROR("illegal instance address format\n");
        result = -EINVAL;
        goto fail;
    }
    *colon++ = '\0';
    i->interface = colon;

    if (server) {
        result = sd_bus_request_name(backend.bus, i->service, 0);
        if (result < 0) {
            if (result == -EALREADY)
                CC_LOG_DEBUG("service name already owned\n");
            else {
                CC_LOG_ERROR("unable to request service name: %s\n", strerror(-result));
                goto fail;
            }
        }
    }

    *instance = i;
    return 0;

fail:
    i = cc_instance_free(i);
    return result;
}

CC_PUBLIC struct cc_instance *cc_instance_free(struct cc_instance *instance)
{
    CC_LOG_DEBUG("invoked cc_instance_free()\n");
    if (instance) {
        /* FIXME: deal with registered service names */
        /* FIXME: fix asserts to correctly handle partially initialized instances */
        /* assert(instance->backend && instance->backend->bus); */
        /* assert(sd_event_get_state(instance->backend->event) == SD_EVENT_FINISHED); */
        free(instance);
    }
    return NULL;
}

CC_PUBLIC int cc_backend_get_event_context(struct cc_event_context **context)
{
    CC_LOG_DEBUG("invoked cc_backend_get_event_context()\n");
    assert(context);
    assert(backend.event);
    event_context.event = backend.event;
    *context = &event_context;
    return 0;
}

CC_PUBLIC void *cc_event_get_native(struct cc_event_context *context)
{
    CC_LOG_DEBUG("invoked cc_event_get_native()\n");
    assert(context && context->event);
    return context->event;
}

CC_PUBLIC int cc_event_get_fd(struct cc_event_context *context)
{
    CC_LOG_DEBUG("invoked cc_event_get_fd()\n");
    assert(context && context->event);
    return sd_event_get_fd(context->event);
}

CC_PUBLIC int cc_event_prepare(struct cc_event_context *context)
{
    int state, result;

    CC_LOG_DEBUG("invoked cc_event_prepare()\n");
    assert(context && context->event);

    /* FIXME: find out correct approach to embed foreign loops into sd-event
     *
     * Client with a GLib main loop works without the additional code below.
     * It also works with the first variant, but the second one reults into EBUSY.
     * Server with an sd-event main loop does not work without the additional
     * code below.  Both first and second variants work for server.
     */
    state = sd_event_get_state(context->event);
    if (state < 0) {
        CC_LOG_ERROR("unable to get event loop state: %s\n", strerror(-state));
        return state;
    }
#if 1
    /* Already prepared--defer further processing */
    if (state != SD_EVENT_INITIAL) {
        result = (state == SD_EVENT_PENDING);
        CC_LOG_DEBUG("returning cc_event_prepare()=%d\n", result);
        return result;
    }
#else
    /* Already prepared--call sd_event_wait() first */
    if (state == SD_EVENT_ARMED) {
        result = sd_event_wait(context->event, 0);
        if (result < 0) {
            CC_LOG_ERROR("unable to wait on client event: %s\n", strerror(-result));
            return result;
        }
    }
#endif

    result = sd_event_prepare(context->event);
    if (result < 0)
        CC_LOG_ERROR("unable to prepare server event: %s\n", strerror(-result));

    CC_LOG_DEBUG("returning cc_event_prepare()=%d\n", result);
    return result;
}

CC_PUBLIC int cc_event_check(struct cc_event_context *context)
{
    int result;

    CC_LOG_DEBUG("invoked cc_event_check()\n");
    assert(context && context->event);
    result = sd_event_wait(context->event, 0);
    if (result < 0)
        CC_LOG_ERROR("unable to wait on server event: %s\n", strerror(-result));

    CC_LOG_DEBUG("returning cc_event_check()=%d\n", result);
    return result;
}

CC_PUBLIC int cc_event_dispatch(struct cc_event_context *context)
{
    int result;

    CC_LOG_DEBUG("invoked cc_event_dispatch()\n");
    assert(context && context->event);
    result = sd_event_dispatch(context->event);
    if (result < 0)
        CC_LOG_ERROR("unable to dispatch server event: %s\n", strerror(-result));

    CC_LOG_DEBUG("returning cc_event_dispatch()=%d\n", result);
    return result;
}
