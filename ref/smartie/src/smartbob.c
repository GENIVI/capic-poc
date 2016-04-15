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
#include <assert.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/server-Smartie.h"
#include "src-gen/client-Smartie.h"


enum smartie_state {SMARTIE_IDLE, SMARTIE_DIALING, SMARTIE_RINGING};
static enum smartie_state bob_state = SMARTIE_IDLE;

static int Smartie_impl_ring(struct cc_server_Smartie *instance, int32_t *status)
{
    CC_LOG_DEBUG("invoked Smartie_impl_ring()\n");
    assert(instance);
    assert(status);
    if (bob_state == SMARTIE_IDLE) {
        *status = 0;
        bob_state = SMARTIE_RINGING;
    } else
        *status = 1;
    CC_LOG_DEBUG("returning status=%d\n", *status);

    return 0;
}

static int Smartie_impl_hangup(struct cc_server_Smartie *instance, int32_t *status)
{
    CC_LOG_DEBUG("invoked Smartie_impl_hangup()\n");
    assert(instance);
    assert(status);
    if (bob_state == SMARTIE_RINGING) {
        *status = 0;
        bob_state = SMARTIE_IDLE;
    } else
        *status = 1;
    CC_LOG_DEBUG("returning status=%d\n", *status);

    return 0;
}

static struct cc_server_Smartie_impl bob_impl = {
    .ring = &Smartie_impl_ring,
    .hangup = &Smartie_impl_hangup
};

static int signal_handler(
    sd_event_source *source, const struct signalfd_siginfo *signal_info, void *userdata)
{
    sd_event *event = (sd_event *) userdata;
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


int main()
{
    int result = 0;
    struct cc_event_context *context = NULL;
    sd_event *event = NULL;
    struct cc_server_Smartie *bob = NULL;
    struct cc_client_Smartie *alice = NULL;

    CC_LOG_OPEN("smartbob");
    printf("Started smartbob\n");

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup the backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_server_Smartie_new(
        "org.genivi.capic.Smartie.Bob:/bob:org.genivi.capic.Smartie",
        &bob_impl, NULL, &bob);
    if (result < 0) {
        printf("unable to create server instance '/bob': %s\n", strerror(-result));
        goto fail;
    }
    result = cc_client_Smartie_new(
        "org.genivi.capic.Smartie.Alice:/alice:org.genivi.capic.Smartie", NULL, &alice);
    if (result < 0) {
        printf("unable to create client instance '/alice': %s\n", strerror(-result));
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
    alice = cc_client_Smartie_free(alice);
    bob = cc_server_Smartie_free(bob);
    cc_backend_shutdown();

    CC_LOG_CLOSE();
    printf("exiting smartbob\n");

    return result;
}
