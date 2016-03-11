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

#ifndef INCLUDED_CC_LOG
#define INCLUDED_CC_LOG

#if ENABLE_LOGGING

#define WITH_SYSTEMD_JOURNAL
#ifdef WITH_SYSTEMD_JOURNAL

#include <systemd/sd-journal.h>

/* Uncomment to suppress using file name and line number in the messages. */
/*#define SD_JOURNAL_SUPPRESS_LOCATION*/

#define CC_LOG_OPEN(program) ((void)(program))
#define CC_LOG_CLOSE() ((void)0)
#define CC_LOG_ERROR(...) sd_journal_print(LOG_ERR, __VA_ARGS__)
#define CC_LOG_DEBUG(...) sd_journal_print(LOG_DEBUG, __VA_ARGS__)

#else

#include <syslog.h>

#define CC_LOG_OPEN(program) openlog((program), 0, LOG_USER)
#define CC_LOG_CLOSE() closelog()
#define CC_LOG_ERROR(...) syslog(LOG_ERR, __VA_ARGS__)
#define CC_LOG_DEBUG(...) syslog(LOG_DEBUG, __VA_ARGS__)

#endif

#else

#define CC_LOG_OPEN(program) ((void)(program))
#define CC_LOG_CLOSE() ((void)0)
#define CC_LOG_ERROR(...) ((void)0)
#define CC_LOG_DEBUG(...) ((void)0)

#endif


#endif /* ifndef INCLUDED_CC_LOG */
