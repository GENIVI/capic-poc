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

#ifndef INCLUDED_CLIENT_SMARTIE
#define INCLUDED_CLIENT_SMARTIE

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_client_Smartie;

typedef void (*cc_Smartie_ring_reply_t)(
    struct cc_client_Smartie *instance, int32_t status);
typedef void (*cc_Smartie_hangup_reply_t)(
    struct cc_client_Smartie *instance, int32_t status);

int cc_Smartie_ring(
    struct cc_client_Smartie *instance, int32_t *status);
int cc_Smartie_ring_async(
    struct cc_client_Smartie *instance, cc_Smartie_ring_reply_t callback);

int cc_Smartie_hangup(
    struct cc_client_Smartie *instance, int32_t *status);
int cc_Smartie_hangup_async(
    struct cc_client_Smartie *instance, cc_Smartie_hangup_reply_t callback);

int cc_client_Smartie_new(
    const char *address, void *data, struct cc_client_Smartie **instance);
struct cc_client_Smartie *cc_client_Smartie_free(struct cc_client_Smartie *instance);
void *cc_client_Smartie_get_data(struct cc_client_Smartie *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_CLIENT_SMARTIE */
