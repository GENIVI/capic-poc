/* SPDX license identifier: EPL-1.0
 * Copyright (C) 2015-2016, Visteon Corp.
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

    public static FInterface makeInterface(String name) {
        return makeInterface(name, null);
    }

    public static FInterface makeInterface(String name, Iterable<FMethod> methods) {
        FInterface result = FrancaFactory.eINSTANCE.createFInterface();
        if (name != null)
            result.setName(name);
        if (methods != null)
            setMethods(result, methods);
        return result;
    }

    private static void setMethods(FInterface api, Iterable<FMethod> methods) {
        BasicEList<FMethod> ms = new BasicEList<FMethod>();
        assert(methods != null);
        for (FMethod m : methods)
            ms.add(m);
        api.eSet(api.eClass().getEStructuralFeature("methods"), ms);
    }

    public static FMethod makeMethod(String name) {
        return makeMethod(name, (Iterable<FArgument>)null, (Iterable<FArgument>)null, false);
    }

    public static FMethod makeMethod(Iterable<FArgument> inArgs, Iterable<FArgument> outArgs) {
        return makeMethod(null, inArgs, outArgs, false);
    }

    public static FMethod makeMethod(String name, Iterable<FArgument> inArgs, Iterable<FArgument> outArgs) {
        return makeMethod(name, inArgs, outArgs, false);
    }

    public static FMethod makeMethod(String name, Iterable<FArgument> inArgs, Iterable<FArgument> outArgs, boolean isFireAndForget) {
        FMethod result = FrancaFactory.eINSTANCE.createFMethod();
        if (name != null)
            result.setName(name);
        if (inArgs != null)
            result.eSet(result.eClass().getEStructuralFeature("inArgs"), makeArgList(inArgs));
        if (outArgs != null)
            result.eSet(result.eClass().getEStructuralFeature("outArgs"), makeArgList(outArgs));
        result.setFireAndForget(isFireAndForget);
        return result;
    }

    public static EList<FArgument> makeArgList(Iterable<FArgument> args) {
        BasicEList<FArgument> result = new BasicEList<FArgument>();
        if (args == null)
            return result;
        for (FArgument a : args)
            result.add(a);
        return result;
    }

    public static FArgument makeArgument(FBasicTypeId typeId, String name) {
        return makeArgument(makeTypeRef(typeId), name);
    }

    public static FArgument makeArgument(FTypeRef typeRef, String name) {
        FArgument result = FrancaFactory.eINSTANCE.createFArgument();
        result.setName(name);
        result.setType(typeRef);
        return result;
    }

    public static FTypeRef makeTypeRef() {
        return FrancaFactory.eINSTANCE.createFTypeRef();
    }

    public static FTypeRef makeTypeRef(FBasicTypeId typeId) {
        FTypeRef result = makeTypeRef();
        result.eSet(result.eClass().getEStructuralFeature("predefined"), typeId);
        return result;
    }
}
