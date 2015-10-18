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

#ifndef INCLUDED_SERVER_CALCULATOR
#define INCLUDED_SERVER_CALCULATOR

#include <stdint.h>
#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_server_Calculator;

typedef int (*cc_Calculator_split_t)(
    struct cc_server_Calculator *instance, double value, int32_t *whole, int32_t *fraction);

struct cc_server_Calculator_impl {
    cc_Calculator_split_t split;
};

int cc_server_Calculator_new(
    const char *address, const struct cc_server_Calculator_impl *impl, void *data,
    struct cc_server_Calculator **instance);
struct cc_server_Calculator *cc_server_Calculator_free(
    struct cc_server_Calculator *instance);
void *cc_server_Calculator_get_data(struct cc_server_Calculator *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_SERVER_CALCULATOR */
