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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <errno.h>
#include <assert.h>

#include <glib.h>
#include <glib-unix.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/client-Ball.h"


/* Player implements the following state machine
 * SOURCE_STATE: EVENT / ACTION(S) -> TARGET_STATE
 *
 * INITIAL: -> FREE
 * FREE: timeout(enter, random[0..1s]) / grab() -> GRABBING
 * GRABBING: grab_success -> ON_BALL
 * GRABBING: grab_failure -> FREE
 * ON_BALL: timeout(entry, random[0..1s]) / drop(); quit() -> FREE
 */

enum player_event {
    EVENT_GRAB,
    EVENT_GRABBED,
    EVENT_NOT_GRABBED,
    EVENT_DROP
};

enum player_state {
    STATE_INITIAL,
    STATE_FREE,
    STATE_GRABBING,
    STATE_ON_BALL,
    STATE_MAXSTATE
};

enum player_timeout {
    TIMEOUT_IN_FREE_MAX_US = 1000000ULL,
    TIMEOUT_IN_ON_BALL_MAX_US = 1000000ULL
};

struct player_data {
    enum player_state state;
    struct cc_client_Ball *ball;
    GMainContext *context;
    GMainLoop *main_loop;
    GSource *grab_timer;
    GSource *drop_timer;
};

typedef int (*player_state_handler_t)(struct player_data *data, enum player_event event);

static int player_do_initial(struct player_data *data, enum player_event event)
{
    gint64 timeout;
    (void) event;

    CC_LOG_DEBUG("invoked player_do_initial()\n");
    assert(data);

    data->state = STATE_FREE;
    srand(time(NULL));
    timeout = (gint64) (TIMEOUT_IN_FREE_MAX_US * 1.0 * random() / RAND_MAX);
    g_source_set_ready_time(data->grab_timer, g_get_monotonic_time() + timeout);

    return 0;
}

static void player_grab_response_handler(struct cc_client_Ball *instance, bool success);

static int player_do_free(struct player_data *data, enum player_event event)
{
    int result = 0;

    CC_LOG_DEBUG("invoked player_do_free()\n");
    assert(data);
    assert(data->state == STATE_FREE);

    switch (event) {
    case EVENT_GRAB:
        data->state = STATE_GRABBING;
        result = cc_Ball_grab_async(data->ball, &player_grab_response_handler);
        if (result < 0) {
            CC_LOG_ERROR("unable to invoke cc_Ball_grab_async(): %s\n", strerror(-result));
            return result;
        }
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static int player_do_grabbing(struct player_data *data, enum player_event event)
{
    gint64 timeout;

    CC_LOG_DEBUG("invoked player_do_grabbing()\n");
    assert(data);
    assert(data->state == STATE_GRABBING);

    switch (event) {
    case EVENT_GRABBED:
        data->state = STATE_ON_BALL;
        timeout = (gint64) (TIMEOUT_IN_ON_BALL_MAX_US * 1.0 * random() / RAND_MAX);
        g_source_set_ready_time(data->drop_timer, g_get_monotonic_time() + timeout);
        return 0;
    case EVENT_NOT_GRABBED:
        data->state = STATE_FREE;
        timeout = (gint64) (TIMEOUT_IN_FREE_MAX_US * 1.0 * random() / RAND_MAX);
        g_source_set_ready_time(data->grab_timer, g_get_monotonic_time() + timeout);
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static int player_do_on_ball(struct player_data *data, enum player_event event)
{
    int result;

    CC_LOG_DEBUG("invoked player_do_on_ball()\n");
    assert(data);
    assert(data->state == STATE_ON_BALL);

    switch (event) {
    case EVENT_DROP:
        data->state = STATE_FREE;
        result = cc_Ball_drop(data->ball);
        if (result < 0) {
            CC_LOG_ERROR("unable to issue cc_Ball_drop(): %s\n", strerror(-result));
            return result;
        }
        g_main_loop_quit(data->main_loop);
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static player_state_handler_t const player_state_handlers[STATE_MAXSTATE] = {
    &player_do_initial,
    &player_do_free,
    &player_do_grabbing,
    &player_do_on_ball
};

static gboolean player_grab_handler(gpointer userdata)
{
    struct player_data *data;

    CC_LOG_DEBUG("invoked player_grab_handler()\n");
    data = (struct player_data *) userdata;
    assert(data);
    (void) player_state_handlers[data->state](data, EVENT_GRAB);

    return TRUE;
}

static gboolean player_drop_handler(gpointer userdata)
{
    struct player_data *data;

    CC_LOG_DEBUG("invoked player_drop_handler()\n");
    data = (struct player_data *) userdata;
    assert(data);
    (void) player_state_handlers[data->state](data, EVENT_DROP);

    return TRUE;
}

static void player_grab_response_handler(struct cc_client_Ball *instance, bool success)
{
    struct player_data *data;

    CC_LOG_DEBUG("invoked player_grab_response_handler()\n");
    CC_LOG_DEBUG("with success=%d\n", (int) success);
    assert(instance);
    data = (struct player_data *) cc_client_Ball_get_data(instance);
    assert(data);

    if (success)
        player_state_handlers[data->state](data, EVENT_GRABBED);
    else
        player_state_handlers[data->state](data, EVENT_NOT_GRABBED);
}


/* Integration of cc_backend event loop into GMainLoop */

typedef struct CCEventSource {
    GSource source;
    GPollFD pollfd;
    struct cc_event_context *event_context;
} CCEventSource;

static gboolean backend_event_prepare(GSource *source, gint *timeout)
{
    struct cc_event_context *context;
    int result;
    (void) timeout;

    CC_LOG_DEBUG("invoked backend_event_prepare()\n");
    assert(source);
    context = ((CCEventSource *) source)->event_context;
    result = cc_event_prepare(context);

    return (result > 0) ? TRUE : FALSE;
}

static gboolean backend_event_check(GSource *source)
{
    struct cc_event_context *context;
    int result;

    CC_LOG_DEBUG("invoked backend_event_check()\n");
    assert(source);
    context = ((CCEventSource *) source)->event_context;
    result = cc_event_check(context);

    return (result > 0) ? TRUE : FALSE;
}

static gboolean backend_event_dispatch(
    GSource *source, GSourceFunc callback, gpointer userdata)
{
    struct cc_event_context *context;
    int result;
    (void) callback;
    (void) userdata;

    CC_LOG_DEBUG("invoked backend_event_dispatch()\n");
    assert(source);
    context = ((CCEventSource *) source)->event_context;
    result = cc_event_dispatch(context);

    return (result < 0) ? G_SOURCE_REMOVE : G_SOURCE_CONTINUE;
}

static GSourceFuncs backend_event_funcs = {
    .prepare = backend_event_prepare,
    .check = backend_event_check,
    .dispatch = backend_event_dispatch,
    .finalize = NULL
};

static int attach_backend_event(struct cc_event_context *context, GMainLoop *main_loop)
{
    GSource *source = NULL;
    CCEventSource *event_source;

    CC_LOG_DEBUG("invoked attach_backend_event()\n");
    assert(context);
    assert(main_loop);

    source = g_source_new(&backend_event_funcs, sizeof(CCEventSource));
    if (!source) {
        CC_LOG_ERROR("unable to create event source: %s\n", strerror(ENOMEM));
        return -ENOMEM;
    }
    g_source_set_name(source, "cc-client");

    event_source = (CCEventSource *) source;
    event_source->event_context = context;
    event_source->pollfd.fd = cc_event_get_fd(context);
    event_source->pollfd.events = G_IO_IN | G_IO_HUP | G_IO_ERR;

    g_source_add_poll(source, &event_source->pollfd);

    g_source_attach(source, g_main_loop_get_context(main_loop));

    return 0;
}

static gboolean signal_handler(gpointer userdata)
{
    struct player_data *data;

    CC_LOG_DEBUG("invoked signal_handler()\n");
    data = (struct player_data *) userdata;
    assert(data);
    g_main_loop_quit(data->main_loop);

    return TRUE;
}

static void initialize_main_context(struct player_data *data)
{
    GSource *signal_source;

    data->context = g_main_context_new();
    data->grab_timer = g_timeout_source_new(-1);
    data->drop_timer = g_timeout_source_new(-1);
    (void) g_source_attach(data->grab_timer, data->context);
    (void) g_source_attach(data->drop_timer, data->context);
    data->main_loop = g_main_loop_new(data->context, FALSE);
    g_source_set_callback(data->grab_timer, &player_grab_handler, data, NULL);
    g_source_set_callback(data->drop_timer, &player_drop_handler, data, NULL);
    signal_source = g_unix_signal_source_new(SIGTERM);
    (void) g_source_attach(signal_source, data->context);
    g_source_set_callback(signal_source, &signal_handler, data, NULL);
    signal_source = g_unix_signal_source_new(SIGINT);
    (void) g_source_attach(signal_source, data->context);
    g_source_set_callback(signal_source, &signal_handler, data, NULL);
}


int main()
{
    int result = 0;
    struct cc_event_context *event_context = NULL;
    struct player_data player = {
        .state = STATE_INITIAL,
        .ball = NULL,
        .context = NULL,
        .main_loop = NULL,
        .grab_timer = NULL,
        .drop_timer = NULL
    };

    CC_LOG_OPEN("player");
    printf("Started player\n");

    initialize_main_context(&player);

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup the backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_backend_get_event_context(&event_context);
    if (result < 0) {
        printf("unable to get backend event context: %s\n", strerror(-result));
        goto fail;
    }
    assert(event_context);
    result = attach_backend_event(event_context, player.main_loop);
    if (result < 0) {
        printf("unable to attach client events to main loop: %s\n", strerror(-result));
        goto fail;
    }

    result = cc_client_Ball_new(
        "org.genivi.capic.Ball:/ball:org.genivi.capic.Ball",
        &player, &player.ball);
    if (result < 0) {
        printf("unable to create client instance '/ball': %s\n", strerror(-result));
        goto fail;
    }
    result = player_do_initial(&player, 0);
    if (result < 0) {
        printf("unable to initiale state machine: %s\n", strerror(-result));
        goto fail;
    }

    printf("invoking GLib main loop...\n");
    g_main_loop_run(player.main_loop);

fail:
    player.ball = cc_client_Ball_free(player.ball);
    cc_backend_shutdown();

    if (player.main_loop)
        g_main_loop_unref(player.main_loop);
    if (player.drop_timer)
        g_source_destroy(player.drop_timer);
    if (player.grab_timer)
        g_source_destroy(player.grab_timer);
    if (player.context)
        g_main_context_unref(player.context);

    CC_LOG_CLOSE();
    printf("exiting player\n");

    return result;
}
