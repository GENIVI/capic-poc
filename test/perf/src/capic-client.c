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
#include <unistd.h>
#include <time.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/client-TestPerf.h"


static int32_t in1 = 12;
static double in2 = 34.0, in3 = 0.56;
static double in41 = 0.78, in42 = 91.0;
static uint32_t in43 = 1112;

static int32_t out1;
static double out2, out3;
static double out41, out42;
static uint32_t out43;


int main(int argc, char *argv[])
{
    int message_count = 10000, message_payload = 0;
    int option, result = 0;
    struct cc_event_context *context = NULL;
    sd_event *event = NULL;
    struct cc_client_TestPerf *instance = NULL;
    struct timespec start, stop;
    double seconds;
    int counter;

    while ((option = getopt(argc, argv, "m:p")) != -1) {
        switch (option) {
        case 'm':
            message_count = atoi(optarg);
            break;
        case 'p':
            message_payload = 1;
            break;
        default:
            printf("Usage: %s [-m count] [-p]\n", argv[0]);
            printf("-m count  send count messages\n");
            printf("-p        send messages with payload\n");
            return EXIT_FAILURE;
        }
    }

    CC_LOG_OPEN(argv[0]);
    printf("Started %s\n", argv[0]);

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup the backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_client_TestPerf_new(
        "org.genivi.capic.TestPerf:/instance:org.genivi.capic.TestPerf",
        NULL, &instance);
    if (result < 0) {
        printf("unable to create client instance '/instance': %s\n", strerror(-result));
        goto fail;
    }

    result = cc_backend_get_event_context(&context);
    if (result < 0) {
        printf("unable to get backend event context: %s\n", strerror(-result));
        goto fail;
    }
    event = (sd_event *) cc_event_get_native(context);
    if (!event) {
        printf("unable to get backend event context: %s\n", strerror(-result));
        goto fail;
    }
    sd_event_ref(event);

    printf("starting test...\n");
    clock_gettime(CLOCK_REALTIME, &start);

    if (message_payload) {
        for (counter = message_count; counter > 0; --counter) {
            result = cc_TestPerf_take40ByteArgs(
                instance, in1, in2, in3, in41, in42, in43,
                &out1, &out2, &out3, &out41, &out42, &out43);
            if (result < 0) {
                printf(
                    "failed while calling cc_TestPerf_take40ByteArgs(): %s\n",
                    strerror(-result));
                goto fail;
            }
            in1 = out1;
            in2 = out2;
            in3 = out3;
            in41 = out41;
            in42 = out42;
            in43 = out43;
        }
    } else {
        for (counter = message_count; counter > 0; --counter) {
            result = cc_TestPerf_takeNoArgs(instance);
            if (result < 0) {
                printf(
                    "failed while calling cc_TestPerf_takeNoArgs(): %s\n",
                    strerror(-result));
                goto fail;
            }
        }
    }

    clock_gettime(CLOCK_REALTIME, &stop);
    seconds = stop.tv_sec - start.tv_sec + (stop.tv_nsec - start.tv_nsec) / 1.0e+9;
    printf("test completed\n");
    printf("message payload [bytes]: %d\n", message_payload ? 40 : 0);
    printf("sync messages sent:      %d\n", message_count);
    printf("messages per [s]:        %g\n", message_count / seconds);

fail:
    instance = cc_client_TestPerf_free(instance);
    cc_backend_shutdown();

    CC_LOG_CLOSE();
    printf("exiting capic-client\n");

    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
