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
package org.genivi.capic.core;

import org.eclipse.emf.common.util.BasicEList;
import org.eclipse.emf.common.util.EList;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FBasicTypeId;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMethod;
import org.franca.core.franca.FTypeRef;
import org.franca.core.franca.FrancaFactory;

public class MockFModel {

    public static class Argument {
        public FTypeRef typeRef;
        public String name;
        public Argument(FBasicTypeId typeId, String name) {
            this.typeRef = FrancaFactory.eINSTANCE.createFTypeRef();
            this.typeRef.setPredefined(typeId);
            this.name = name;
        }
    }

    public static FInterface makeInterface(String name) {
        return makeInterface(name, null);
    }

    public static FInterface makeInterface(String name, FMethod[] methods) {
        FInterface result = FrancaFactory.eINSTANCE.createFInterface();
        if (name != null)
            result.setName(name);
        if (methods != null)
            setMethods(result, methods);
        return result;
    }

    private static void setMethods(FInterface api, FMethod[] methods) {
        BasicEList<FMethod> ms = new BasicEList<FMethod>();
        assert(methods != null);
        for (FMethod m : methods)
            ms.add(m);
        api.eSet(api.eClass().getEStructuralFeature("methods"), ms);
    }

    public static FMethod makeMethod(Argument[] inArgs, Argument[] outArgs) {
        return makeMethod(null, inArgs, outArgs);
    }

    public static FMethod makeMethod(String name, Argument[] inArgs, Argument[] outArgs) {
        FMethod result = FrancaFactory.eINSTANCE.createFMethod();
        if (name != null)
            result.setName(name);
        if (inArgs != null)
            result.eSet(result.eClass().getEStructuralFeature("inArgs"), makeArgList(inArgs));
        if (outArgs != null)
            result.eSet(result.eClass().getEStructuralFeature("outArgs"), makeArgList(outArgs));
        return result;
    }

    private static EList<FArgument> makeArgList(Argument[] args) {
        assert(args != null);
        BasicEList<FArgument> result = new BasicEList<FArgument>();
        for (Argument a : args) {
            FArgument fa = FrancaFactory.eINSTANCE.createFArgument();
            fa.setName(a.name);
            fa.setType(a.typeRef);
            result.add(fa);
        }
        return result;
    }
}
