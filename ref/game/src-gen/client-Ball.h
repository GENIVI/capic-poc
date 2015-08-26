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

#ifndef INCLUDED_CLIENT_BALL
#define INCLUDED_CLIENT_BALL

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_client_Ball;

typedef void (*cc_Ball_grab_reply_t)(struct cc_client_Ball *instance, bool success);

int cc_Ball_grab(struct cc_client_Ball *instance, bool *succes);
int cc_Ball_grab_async(struct cc_client_Ball *instance, cc_Ball_grab_reply_t callback);

int cc_Ball_drop(struct cc_client_Ball *instance);

int cc_client_Ball_new(const char *address, void *data, struct cc_client_Ball **instance);
struct cc_client_Ball *cc_client_Ball_free(struct cc_client_Ball *instance);
void *cc_client_Ball_get_data(struct cc_client_Ball *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_CLIENT_BALL */
