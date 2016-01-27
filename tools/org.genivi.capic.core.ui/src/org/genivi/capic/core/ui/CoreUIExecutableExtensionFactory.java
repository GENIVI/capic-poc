/* SPDX license identifier: EPL-1.0
 * Copyright (C) 2015, Visteon Corp.
 *
 * This file is part of Common API C
 *
 * This program and the accompanying materials are made available
 * under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html.
 * For further information see http://www.genivi.org/.
 *
 * Contributors:
 *   Pavel Konopelko, pkonopel@visteon.com
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
