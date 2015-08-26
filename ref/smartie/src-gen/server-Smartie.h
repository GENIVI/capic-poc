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

#ifndef INCLUDED_SERVER_SERVICE
#define INCLUDED_SMARTIE_SERVICE

#include <stdint.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_server_Smartie;

typedef int (*cc_Smartie_call_t)(struct cc_server_Smartie *instance, int32_t *status);
typedef int (*cc_Smartie_hangup_t)(struct cc_server_Smartie *instance, int32_t *status);

struct cc_server_Smartie_impl {
    cc_Smartie_call_t call;
    cc_Smartie_hangup_t hangup;
};

int cc_server_Smartie_new(
    const char *address, const struct cc_server_Smartie_impl *impl, void *data,
    struct cc_server_Smartie **instance);
struct cc_server_Smartie *cc_server_Smartie_free(struct cc_server_Smartie *instance);
void *cc_server_Smartie_get_data(struct cc_server_Smartie *instance);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_SMARTIE_SERVICE */
