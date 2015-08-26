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
#include <assert.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/server-Calculator.h"


static int Calculator_impl1_split(
    struct cc_server_Calculator *instance, double value, int32_t *whole, int32_t *fraction)
{
    CC_LOG_DEBUG("invoked method Calculator_impl1_split()\n");
    CC_LOG_DEBUG("with value=%g\n", value);
    assert(instance);
    assert(whole);
    assert(fraction);
    *whole = (int32_t)value;
    *fraction = (int32_t)((value - (double)*whole) * 1.0e+9);
    CC_LOG_DEBUG("returning whole=%d, fraction=%d\n", *whole, *fraction);
    return 0;
}

static int Calculator_impl2_split(
    struct cc_server_Calculator *instance, double value, int32_t *whole, int32_t *fraction)
{
    CC_LOG_DEBUG("invoked method Calculator_impl1_split()\n");
    CC_LOG_DEBUG("with value=%g\n", value);
    assert(instance);
    assert(whole);
    assert(fraction);
    *whole = -1;
    *fraction = -2;
    CC_LOG_DEBUG("returning whole=%d, fraction=%d\n", *whole, *fraction);
    return 0;
}

static struct cc_server_Calculator_impl impl1 = {
    .split = &Calculator_impl1_split
};

static struct cc_server_Calculator_impl impl2 = {
    .split = &Calculator_impl2_split
};

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
    struct cc_event_context *context = NULL;
    sd_event *event = NULL;
    struct cc_server_Calculator *instance1 = NULL, *instance2 = NULL;

    CC_LOG_OPEN("simpleserver");
    printf("Started simpleserver\n");

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_server_Calculator_new(
        "org.genivi.capic.Server:/instance1:org.genivi.capic.Calculator",
        &impl1, NULL, &instance1);
    if (result < 0) {
        printf("unable to create server instance '/instance1': %s\n", strerror(-result));
        goto fail;
    }
    result = cc_server_Calculator_new(
        "org.genivi.capic.Server:/instance2:org.genivi.capic.Calculator",
        &impl2, NULL, &instance2);
    if (result < 0) {
        printf("unable to create server instance '/instance2': %s\n", strerror(-result));
        goto fail;
    }

    result = cc_backend_get_event_context(&context);
    if (result < 0) {
        printf("unable to get backend event context: %s\n", strerror(-result));
        goto fail;
    }
    event = (sd_event *) cc_event_get_native(context);
    assert(event);
    sd_event_ref(event);
    result = setup_signals(event);
    if (result < 0) {
        printf("unable to setup signal sources: %s\n", strerror(-result));
        goto fail;
    }

    printf("entering main loop...\n");
    result = sd_event_loop(event);
    if (result < 0) {
        printf("unable to run event loop: %s\n", strerror(-result));
        goto fail;
    }

fail:
    if (event)
        sd_event_unref(event);
    instance2 = cc_server_Calculator_free(instance2);
    instance1 = cc_server_Calculator_free(instance1);
    cc_backend_shutdown();

    CC_LOG_CLOSE();
    printf("exiting simpleserver\n");

    return result;
}
