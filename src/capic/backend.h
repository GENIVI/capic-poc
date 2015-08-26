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

#ifndef INCLUDED_CC_BACKEND
#define INCLUDED_CC_BACKEND

#include <stdbool.h>


#ifdef __cplusplus
extern "C" {
#endif

struct cc_instance;
struct cc_event_context;

int cc_backend_startup();
void cc_backend_shutdown();

int cc_instance_new(const char *address, bool server, struct cc_instance **instance);
struct cc_instance *cc_instance_free(struct cc_instance *instance);

int cc_backend_get_event_context(struct cc_event_context **context);
void *cc_event_get_native(struct cc_event_context *context);
int cc_event_get_fd(struct cc_event_context *context);
int cc_event_prepare(struct cc_event_context *context);
int cc_event_check(struct cc_event_context *context);
int cc_event_dispatch(struct cc_event_context *context);


#ifdef __cplusplus
}
#endif


#endif /* ifndef INCLUDED_CC_BACKEND */
