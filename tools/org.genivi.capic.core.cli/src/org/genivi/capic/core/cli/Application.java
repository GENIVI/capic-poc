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
package org.genivi.capic.core.cli;

import org.eclipse.equinox.app.IApplication;
import org.eclipse.equinox.app.IApplicationContext;

public class Application implements IApplication {

    @Override
    public Object start(IApplicationContext context) throws Exception {
        System.out.println("GENIVI Common API C Core Standalone Generator");
        final String[] appArgs = (String[]) context.getArguments().get(
            IApplicationContext.APPLICATION_ARGS);
        for (final String arg : appArgs)
            System.out.println(arg);
        return IApplication.EXIT_OK;
    }

    @Override
    public void stop() {
    }

}
