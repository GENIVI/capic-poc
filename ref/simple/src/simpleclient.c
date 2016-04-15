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
#include <errno.h>
#include <assert.h>

#include <systemd/sd-event.h>
#include <capic/log.h>
#include <capic/backend.h>
#include "src-gen/client-Calculator.h"


static void complete_Calculator_split(
    struct cc_client_Calculator *instance, int32_t whole, int32_t fraction)
{
    assert(instance);
    printf("received whole=%d, fraction=%d\n", whole, fraction);
}

int main()
{
    int result = 0;
    struct cc_event_context *context = NULL;
    sd_event *event = NULL;
    struct cc_client_Calculator *instance1 = NULL, *instance2 = NULL;
    double value = 3.14159265;
    int32_t whole = 0;
    int32_t fraction = 0;

    CC_LOG_OPEN("simpleclient");
    printf("Started simpleclient\n");

    result = cc_backend_startup();
    if (result < 0) {
        printf("unable to startup the backend: %s\n", strerror(-result));
        goto fail;
    }
    result = cc_client_Calculator_new(
        "org.genivi.capic.Server:/instance1:org.genivi.capic.Calculator",
        NULL, &instance1);
    if (result < 0) {
        printf("unable to create client instance '/instance1': %s\n", strerror(-result));
        goto fail;
    }
    result = cc_client_Calculator_new(
        "org.genivi.capic.Server:/instance2:org.genivi.capic.Calculator",
        NULL, &instance2);
    if (result < 0) {
        printf("unable to create client instance '/instance2': %s\n", strerror(-result));
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

    printf("invoking method instance1.split() with value=%g\n", value);
    printf(
        "expecting to receive whole=%d, fraction=%d\n", (int32_t)value,
        (int32_t)((value - (double)(int32_t)value) * 1.0e+9));
    result = cc_Calculator_split(instance1, value, &whole, &fraction);
    if (result < 0) {
        printf("failed while calling cc_Calculator_split(): %s\n", strerror(-result));
        goto fail;
    }
    printf("received whole=%d, fraction=%d\n", whole, fraction);

    printf("invoking method instance2.split() with value=%g\n", value);
    printf(
        "expecting to receive whole=%d, fraction=%d\n", (int32_t)value,
        (int32_t)((value - (double)(int32_t)value) * 1.0e+9));
    result = cc_Calculator_split_async(
        instance2, value, &complete_Calculator_split);
    if (result < 0) {
        printf("unable to issue cc_Calculator_split_async(): %s\n", strerror(-result));
        goto fail;
    }
    result = cc_Calculator_split(instance2, value, &whole, &fraction);
    if (result >= 0) {
        printf("invoking method with pending reply succeeded unexpectedly");
        goto fail;
    }
    assert(result == -EBUSY);
    result = sd_event_run(event, (uint64_t) -1);
    if (result < 0) {
        printf(
            "unable to complete cc_Calculator_split_async(): %s\n", strerror(-result));
        goto fail;
    }

fail:
    instance2 = cc_client_Calculator_free(instance2);
    instance1 = cc_client_Calculator_free(instance1);
    cc_backend_shutdown();

    CC_LOG_CLOSE();
    printf("exiting simpleclient\n");

    return result;
}
