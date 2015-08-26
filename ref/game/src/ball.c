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

#include <stdio.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <sys/epoll.h>
#include <assert.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/server-Ball.h"


/* Ball implements the following state machine
 * SOURCE_STATE: EVENT / ACTION(S) -> TARGET_STATE
 *
 * INITIAL: -> RESTING
 * RESTING: grab / ^grab_success -> GRABBED
 * *: grab / ^grab_failure -> *
 * GRABBED: drop -> FALLING
 * FALLING: timeout(entry, 1s) -> RESTING
 */

enum ball_event {
    EVENT_DROP,
    EVENT_GRAB,
    EVENT_LAND
};

enum ball_state {
    STATE_INITIAL,
    STATE_RESTING,
    STATE_GRABBED,
    STATE_FALLING,
    STATE_MAXSTATE
};

enum ball_timeout {
    TIMEOUT_IN_FALLING_US = 1000000ULL
};

struct ball_data {
    enum ball_state state;
    struct cc_server_Ball *ball;
    sd_event *event;
    sd_event_source *backend_source;
    sd_event_source *fall_timer;
};

typedef int (*ball_state_handler_t)(struct ball_data *data, enum ball_event event);

static int ball_do_initial(struct ball_data *data, enum ball_event event)
{
    CC_LOG_DEBUG("invoked ball_do_initial()\n");
    assert(data);

    (void) event;
    data->state = STATE_RESTING;
    return 0;
}

static int ball_do_resting(struct ball_data *data, enum ball_event event)
{
    CC_LOG_DEBUG("invoked ball_do_resting()\n");
    assert(data);
    assert(data->state == STATE_RESTING);

    switch (event) {
    case EVENT_GRAB:
        data->state = STATE_GRABBED;
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static uint64_t time_now()
{
    struct timespec ts;

    assert(clock_gettime(CLOCK_MONOTONIC, &ts) == 0);
    if (ts.tv_sec == (time_t) -1 && ts.tv_nsec == (long) -1)
        return (uint64_t) -1;

    if ((uint64_t) ts.tv_sec > (UINT64_MAX - (ts.tv_nsec / 1000ULL)) / 1000000ULL)
        return (uint64_t) -1;

    return (uint64_t) ts.tv_sec * 1000000ULL + (uint64_t) ts.tv_nsec / 1000ULL;
}

static int ball_do_grabbed(struct ball_data *data, enum ball_event event)
{
    int result = 0;

    CC_LOG_DEBUG("invoked ball_do_grabbed()\n");
    assert(data);
    assert(data->state == STATE_GRABBED);
    assert(data->fall_timer);

    switch (event) {
    case EVENT_DROP:
        data->state = STATE_FALLING;
        result = sd_event_source_set_time(
            data->fall_timer, time_now() + TIMEOUT_IN_FALLING_US);
        if (result < 0) {
            CC_LOG_ERROR("unable to set time for event source: %s\n", strerror(-result));
            return result;
        }
        result = sd_event_source_set_enabled(data->fall_timer, SD_EVENT_ONESHOT);
        if (result < 0) {
            CC_LOG_ERROR("unable to enable event source: %s\n", strerror(-result));
            return result;
        }
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static int ball_do_falling(struct ball_data *data, enum ball_event event)
{
    CC_LOG_DEBUG("invoked ball_do_falling()\n");
    assert(data);
    assert(data->state == STATE_FALLING);

    switch (event) {
    case EVENT_LAND:
        data->state = STATE_RESTING;
        return 0;
    default:
        CC_LOG_DEBUG("ignoring event=%d", (int) event);
    }

    return -EPROTO;
}

static ball_state_handler_t const ball_state_handlers[STATE_MAXSTATE] = {
    &ball_do_initial,
    &ball_do_resting,
    &ball_do_grabbed,
    &ball_do_falling
};

static int Ball_impl_grab(struct cc_server_Ball *instance, bool *success)
{
    struct ball_data *data;

    CC_LOG_DEBUG("invoked method Ball_impl_grab()\n");
    assert(instance);
    assert(success);
    data = (struct ball_data *) cc_server_Ball_get_data(instance);
    assert(data);
    if (ball_state_handlers[data->state](data, EVENT_GRAB) < 0)
        *success = false;
    else
        *success = true;
    CC_LOG_DEBUG("returning success=%d\n", (int) *success);

    return 0;
}

static int Ball_impl_drop(struct cc_server_Ball *instance)
{
    struct ball_data *data;

    CC_LOG_DEBUG("invoked method Ball_impl_drop()\n");
    assert(instance);
    data = (struct ball_data *) cc_server_Ball_get_data(instance);
    assert(data);
    (void) ball_state_handlers[data->state](data, EVENT_DROP);

    return 0;
}

static struct cc_server_Ball_impl ball_impl = {
    .grab = &Ball_impl_grab,
    .drop = &Ball_impl_drop
};

static int ball_land_handler(sd_event_source *source, uint64_t usec, void *userdata)
{
    struct ball_data *data;

    CC_LOG_DEBUG("invoked ball_land_handler()\n");
    data = (struct ball_data *) userdata;
    assert(data);
    (void) ball_state_handlers[data->state](data, EVENT_LAND);

    return 1;
}

static int backend_event_prepare(sd_event_source *source, void *userdata)
{
    int result;
    struct cc_event_context *context = (struct cc_event_context *) userdata;

    CC_LOG_DEBUG("invoked backend_event_prepare()\n");
    assert(context);
    result = cc_event_prepare(context);
    if (result < 0)
        CC_LOG_ERROR("unable to prepare server event: %s\n", strerror(-result));

    return result;
}

static int backend_event_dispatch(
    sd_event_source *source, int fd, uint32_t revents, void *userdata)
{
    int result;
    struct cc_event_context *context = (struct cc_event_context *) userdata;

    CC_LOG_DEBUG("invoked backend_event_dispatch()\n");
    assert(context);
    result = cc_event_check(context);
    if (result < 0) {
        CC_LOG_ERROR("unable to check server event: %s\n", strerror(-result));
        return result;
    }
    if (result == 0)
        return result;
    result = cc_event_dispatch(context);
    if (result < 0)
        CC_LOG_ERROR("unable to dispatch server event: %s\n", strerror(-result));

    return result;
}

static int signal_handler(
    sd_event_source *source, const struct signalfd_siginfo *signal_info, void *user_data)
{
    sd_event *event = (sd_event *) user_data;
    int result;

    CC_LOG_DEBUG("invoked signal_handler() with signal %d\n", signal_info->ssi_signo);
    assert(event);
    assert(signal_info->ssi_signo == SIGTERM || signal_info->ssi_signo == SIGINT);

    result = sd_event_exit(event, 0);
    if (result < 0)
        CC_LOG_ERROR("unable to exit event loop: %s\n", strerror(-result));

    return result;
}

static int setup_signals(sd_event *event)
{
    sigset_t signals;
    int result;

    CC_LOG_DEBUG("invoked setup_signals()\n");
    assert(event);
    sigemptyset(&signals);
    sigaddset(&signals, SIGTERM);
    sigaddset(&signals, SIGINT);
    result = sigprocmask(SIG_BLOCK, &signals, NULL);
    if (result != 0) {
        CC_LOG_ERROR("unable to block signals: %s\n", strerror(result));
        return -result;
    }
    result = sd_event_add_signal(event, NULL, SIGTERM, &signal_handler, event);
    if (result < 0) {
        CC_LOG_ERROR("unable to setup SIGTERM handler: %s\n", strerror(-result));
        return result;
    }
    result = sd_event_add_signal(event, NULL, SIGINT, &signal_handler, event);
    if (result < 0) {
        CC_LOG_ERROR("unable to setup SIGINT handler: %s\n", strerror(-result));
        return result;
    }

    return 0;
}


int main(int argc, char *argv[])
{
    int result = 0;
    struct cc_event_context *event_context = NULL;
    struct ball_data ball = {
        .state = STATE_INITIAL,
        .ball = NULL,
        .event = NULL,
        .backend_source = NULL,
        .fall_timer = NULL
    };

    CC_LOG_OPEN("ball");
    printf("Started ball\n");

    result = sd_event_default(&ball.event);
    if (result < 0) {
        printf("unable to get default event loop: %s\n", strerror(-result));
        goto fail;
    }
    result = setup_signals(ball.event);
    if (result < 0) {
        printf("unable to setup signal sources: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_event_add_time(
        ball.event, &ball.fall_timer, CLOCK_MONOTONIC, 0, 0,
        &ball_land_handler, &ball);
    if (result < 0) {
        printf("unable to add land time event source: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_event_source_set_enabled(ball.fall_timer, SD_EVENT_OFF);
    if (result < 0) {
        printf("unable to deactivate time event source: %s\n", strerror(-result));
        goto fail;
    }

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_server_Ball_new(
        "org.genivi.capic.Ball:/ball:org.genivi.capic.Ball",
        &ball_impl, &ball, &ball.ball);
    if (result < 0) {
        printf("unable to create server instance '/ball': %s\n", strerror(-result));
        goto fail;
    }
    result = ball_do_initial(&ball, 0);
    if (result < 0) {
        printf("unable to initiale state machine: %s\n", strerror(-result));
        goto fail;
    }

    result = cc_backend_get_event_context(&event_context);
    if (result < 0) {
        printf("unable to get backend event context: %s\n", strerror(-result));
        goto fail;
    }
    assert(event_context);
    result = sd_event_add_io(
        ball.event, &ball.backend_source, cc_event_get_fd(event_context),
        EPOLLIN | EPOLLHUP | EPOLLERR, &backend_event_dispatch, event_context);
    if (result < 0) {
        printf("unable to add backend event source: %s\n", strerror(-result));
        goto fail;
    }
    result = sd_event_source_set_prepare(ball.backend_source, &backend_event_prepare);
    if (result < 0) {
        printf("unable to set backend event prepare callback: %s\n", strerror(-result));
        goto fail;
    }

    printf("entering main loop...\n");
    result = sd_event_loop(ball.event);
    if (result < 0) {
        printf("unable to run event loop: %s\n", strerror(-result));
        goto fail;
    }

fail:
    sd_event_source_unref(ball.backend_source);
    ball.ball = cc_server_Ball_free(ball.ball);
    cc_backend_shutdown();
    sd_event_source_unref(ball.fall_timer);
    sd_event_unref(ball.event);

    CC_LOG_CLOSE();
    printf("exiting ball\n");

    return result;
}
