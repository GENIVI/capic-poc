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

#ifndef INCLUDED_CC_PRIVATE
#define INCLUDED_CC_PRIVATE

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif


#define CC_PUBLIC __attribute__ ((visibility("default")))
#define CC_UNUSED __attribute__ ((unused))

#if defined(HAVE_DECL_SD_EVENT_INITIAL) && !HAVE_DECL_SD_EVENT_INITIAL
/* These enum constants were renamed between v219 and v220 */
#define SD_EVENT_INITIAL SD_EVENT_PASSIVE
#define SD_EVENT_ARMED SD_EVENT_PREPARED
#endif

#if !defined(HAVE_SD_BUS_GET_SCOPE)
/* This function is exported since v221 */
#define sd_bus_get_scope(x, y) mock_sd_bus_get_scope(x, y)
static inline int mock_sd_bus_get_scope(sd_bus CC_UNUSED *bus, const char **scope)
{ *scope = "unknown"; return 0; }
#endif


#endif /* ifndef INCLUDED_CC_PRIVATE */
