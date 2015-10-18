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

#ifndef INCLUDED_CLIENT_CALCULATOR
#define INCLUDED_CLIENT_CALCULATOR

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_client_Calculator;

typedef void (*cc_Calculator_split_reply_t)(
    struct cc_client_Calculator *instance, int32_t whole, int32_t fraction);

int cc_Calculator_split(
    struct cc_client_Calculator *instance, double value, int32_t *whole,
    int32_t *fraction);
int cc_Calculator_split_async(
    struct cc_client_Calculator *instance, double value,
    cc_Calculator_split_reply_t callback);

int cc_client_Calculator_new(
    const char *address, void *data, struct cc_client_Calculator **instance);
struct cc_client_Calculator *cc_client_Calculator_free(
    struct cc_client_Calculator *instance);
void *cc_client_Calculator_get_data(struct cc_client_Calculator *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_CLIENT_CALCULATOR */
