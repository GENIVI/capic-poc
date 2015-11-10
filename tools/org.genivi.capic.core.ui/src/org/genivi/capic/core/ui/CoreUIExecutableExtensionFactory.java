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
package org.genivi.capic.core.ui;

import org.franca.core.dsl.ui.FrancaIDLExecutableExtensionFactory;
import org.osgi.framework.Bundle;

public class CoreUIExecutableExtensionFactory extends FrancaIDLExecutableExtensionFactory {
    @Override
    protected Bundle getBundle() {
        return Activator.getDefault().getBundle();
    }
}
