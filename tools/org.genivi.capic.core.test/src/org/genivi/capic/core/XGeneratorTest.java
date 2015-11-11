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

import static org.junit.Assert.*;

import org.eclipse.xtext.junit4.InjectWith;
import org.eclipse.xtext.junit4.XtextRunner;
import org.franca.core.dsl.FrancaIDLTestsInjectorProvider;
import org.franca.core.franca.FBasicTypeId;
import org.franca.core.franca.FTypeRef;
import org.franca.core.franca.FrancaFactory;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(XtextRunner.class)
@InjectWith(FrancaIDLTestsInjectorProvider.class)
public class XGeneratorTest {
    @Test
    public void testBasicTypeSignature() {
        XGenerator xgen = new XGenerator();
        FTypeRef type = FrancaFactory.eINSTANCE.createFTypeRef();
        type.setPredefined(FBasicTypeId.BOOLEAN);
        assertEquals("bool ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.INT8);
        assertEquals("int8_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.INT16);
        assertEquals("int16_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.INT32);
        assertEquals("int32_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.INT64);
        assertEquals("int64_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.UINT8);
        assertEquals("uint8_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.UINT16);
        assertEquals("uint16_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.UINT32);
        assertEquals("uint32_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.UINT64);
        assertEquals("uint64_t ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.FLOAT);
        assertEquals("float ", xgen.typeSignature(type));
        type.setPredefined(FBasicTypeId.DOUBLE);
        assertEquals("double ", xgen.typeSignature(type));
    }
}
