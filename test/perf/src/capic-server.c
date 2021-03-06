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
#include <string.h>
#include <assert.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/server-TestPerf.h"


static int TestPerf_impl_takeNoArgs(struct cc_server_TestPerf *instance)
{
    CC_LOG_DEBUG("invoked method TestPerf_impl_takeNoArgs()\n");
    assert(instance);
    return 0;
}

static int TestPerf_impl_take40ByteArgs(
    struct cc_server_TestPerf *instance,
    int32_t in1, double in2, double in3, double in41, double in42, uint32_t in43,
    int32_t *out1, double *out2, double *out3, double *out41, double *out42, uint32_t *out43)
{
    CC_LOG_DEBUG("invoked method TestPerf_impl_take40ByteArgs()\n");
    assert(instance);
    *out1 = in1;
    *out2 = in2;
    *out3 = in3;
    *out41 = in41;
    *out42 = in42;
    *out43 = in43;
    return 0;
}

static struct cc_server_TestPerf_impl impl = {
    .takeNoArgs = &TestPerf_impl_takeNoArgs,
    .take40ByteArgs = &TestPerf_impl_take40ByteArgs
};

static int signal_handler(
    sd_event_source *source, const struct signalfd_siginfo *signal_info, void *user_data)
{
    sd_event *event = (sd_event *) user_data;
    int result;

    CC_LOG_DEBUG("invoked signal_handler() with signal %d\n", signal_info->ssi_signo);
    assert(source);
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


int main(int argc, char* argv[])
{
    int result = 0;
    struct cc_event_context *context = NULL;
    sd_event *event = NULL;
    struct cc_server_TestPerf *instance = NULL;
    (void) argc;

    CC_LOG_OPEN(argv[0]);
    printf("Started %s\n", argv[0]);

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_server_TestPerf_new(
        "org.genivi.capic.TestPerf:/instance:org.genivi.capic.TestPerf",
        &impl, NULL, &instance);
    if (result < 0) {
        printf("unable to create server instance '/instance': %s\n", strerror(-result));
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
    instance = cc_server_TestPerf_free(instance);
    cc_backend_shutdown();

    CC_LOG_CLOSE();
    printf("exiting %s\n", argv[0]);

    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
