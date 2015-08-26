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

#ifndef INCLUDED_SERVER_BALL
#define INCLUDED_SERVER_BALL

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_server_Ball;

typedef int (*cc_Ball_grab_t)(struct cc_server_Ball *instance, bool *success);
typedef int (*cc_Ball_drop_t)(struct cc_server_Ball *instance);

struct cc_server_Ball_impl {
    cc_Ball_grab_t grab;
    cc_Ball_drop_t drop;
};

int cc_server_Ball_new(
    const char *address, const struct cc_server_Ball_impl *impl, void *data,
    struct cc_server_Ball **instance);
struct cc_server_Ball *cc_server_Ball_free(struct cc_server_Ball *instance);
void *cc_server_Ball_get_data(struct cc_server_Ball *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_SERVER_BALL */
