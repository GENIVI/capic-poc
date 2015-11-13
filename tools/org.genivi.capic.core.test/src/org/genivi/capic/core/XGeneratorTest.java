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
import static org.hamcrest.CoreMatchers.*;

import org.eclipse.xtext.junit4.InjectWith;
import org.eclipse.xtext.junit4.XtextRunner;
import org.franca.core.dsl.FrancaIDLTestsInjectorProvider;
import org.franca.core.franca.FBasicTypeId;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMethod;
import org.franca.core.franca.FTypeRef;
import org.franca.core.franca.FrancaFactory;
import org.hamcrest.Matcher;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(XtextRunner.class)
@InjectWith(FrancaIDLTestsInjectorProvider.class)
public class XGeneratorTest {

    private static void assertThat(CharSequence s, Matcher<String> matcher)
    {
        Assert.assertThat("", s.toString(), matcher);
    }

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

    @Test
    public void testTypeSignatures() {
        XGenerator xgen = new XGenerator();
        FMethod[] methods = {MockFModel.makeMethod("func", null, null)};
        FInterface api = MockFModel.makeInterface("ApiName", methods);
        assertThat(xgen.clientTypeSignature(api), is("struct cc_client_ApiName"));
        assertThat(xgen.clientReplyTypeName(methods[0]), is("cc_ApiName_func_reply_t"));
        assertThat(xgen.clientReplyThunkName(methods[0]), is("cc_ApiName_func_reply_thunk"));
        assertThat(xgen.serverTypeSignature(api), is("struct cc_server_ApiName"));
        assertThat(xgen.serverImplTypeSignature(api), is("struct cc_server_ApiName_impl"));
        assertThat(xgen.serverThunkName(methods[0]), is("cc_ApiName_func_thunk"));
    }

    @Test
    public void testMethodPrefixes() {
        XGenerator xgen = new XGenerator();
        FInterface api = MockFModel.makeInterface("TestInterface");
        assertThat(xgen.clientMethodPrefix(api), is("cc_client_TestInterface"));
        assertThat(xgen.serverMethodPrefix(api), is("cc_server_TestInterface"));
    }

    @Test
    public void testHeaderGuards() {
        XGenerator xgen = new XGenerator();
        FInterface api = MockFModel.makeInterface("MyService");
        assertThat(xgen.clientHeaderGuard(api), is("INCLUDED_CLIENT_MYSERVICE"));
        assertThat(xgen.serverHeaderGuard(api), is("INCLUDED_SERVER_MYSERVICE"));
    }

    @Test
    public void testEmtpyArguments() {
        XGenerator xgen = new XGenerator();
        MockFModel.Argument[] inArgs = {};
        MockFModel.Argument[] outArgs = {};
        FMethod method = MockFModel.makeMethod(inArgs, outArgs);
        assertThat(xgen.byVal(xgen.inArgs(method)), is(""));
        assertThat(xgen.byRef(xgen.outArgs(method)), is(""));
        assertThat(xgen.byVal(xgen.outArgs(method)), is(""));
    }

    @Test
    public void testArguments() {
        XGenerator xgen = new XGenerator();
        MockFModel.Argument[] inArgs = {
                new MockFModel.Argument(FBasicTypeId.INT32, "arg1"),
                new MockFModel.Argument(FBasicTypeId.BOOLEAN, "arg2")};
        MockFModel.Argument[] outArgs = {
                new MockFModel.Argument(FBasicTypeId.UINT8, "arg10"),
                new MockFModel.Argument(FBasicTypeId.DOUBLE, "arg20")};
        FMethod method = MockFModel.makeMethod(inArgs, outArgs);
        assertSame(method.getInArgs(), xgen.inArgs(method));
        assertSame(method.getOutArgs(), xgen.outArgs(method));
        assertThat(xgen.byVal(xgen.inArgs(method)), is(", int32_t arg1, bool arg2"));
        assertThat(xgen.byRef(xgen.outArgs(method)), is(", uint8_t *arg10, double *arg20"));
        assertThat(xgen.byVal(xgen.outArgs(method)), is(", uint8_t arg10, double arg20"));
    }

    @Test
    public void testClientMethodPrototypes() {
        XGenerator xgen = new XGenerator();
        MockFModel.Argument[] inArgs = {
                new MockFModel.Argument(FBasicTypeId.INT32, "arg1"),
                new MockFModel.Argument(FBasicTypeId.BOOLEAN, "arg2")};
        MockFModel.Argument[] outArgs = {
                new MockFModel.Argument(FBasicTypeId.UINT8, "arg10"),
                new MockFModel.Argument(FBasicTypeId.DOUBLE, "arg20")};
        FMethod[] methods = {MockFModel.makeMethod("method", inArgs, outArgs)};
        FInterface api = MockFModel.makeInterface("TestApi", methods);
        String clientHeader = xgen.generateClientInterfaceHeader(api).toString();
        assertThat(clientHeader, containsString(
                "(*cc_TestApi_method_reply_t)(struct cc_client_TestApi *instance, uint8_t arg10, double arg20"));
        assertThat(clientHeader, containsString(
                "cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, uint8_t *arg10, double *arg20"));
        assertThat(clientHeader, containsString(
                "cc_TestApi_method_async(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, cc_TestApi_method_reply_t callback"));
        String clientBody = xgen.generateClientInterfaceHeader(api).toString();
        assertThat(clientBody, containsString(
                "cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, uint8_t *arg10, double *arg20"));
        assertThat(clientBody, containsString(
                "cc_TestApi_method_async(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, cc_TestApi_method_reply_t callback"));
    }

    @Test
    public void testServerMethodPrototypes() {
        XGenerator xgen = new XGenerator();
        MockFModel.Argument[] inArgs = {
                new MockFModel.Argument(FBasicTypeId.UINT16, "arg01"),
                new MockFModel.Argument(FBasicTypeId.INT64, "arg02")};
        MockFModel.Argument[] outArgs = {
                new MockFModel.Argument(FBasicTypeId.INT8, "arg11"),
                new MockFModel.Argument(FBasicTypeId.BOOLEAN, "arg22"),
                new MockFModel.Argument(FBasicTypeId.FLOAT, "arg33")};
        FMethod[] methods = {MockFModel.makeMethod("func", inArgs, outArgs)};
        FInterface api = MockFModel.makeInterface("MyService", methods);
        String clientHeader = xgen.generateServerInterfaceHeader(api).toString();
        assertThat(clientHeader, containsString(
                "(*cc_MyService_func_t)(struct cc_server_MyService *instance, uint16_t arg01, int64_t arg02, int8_t *arg11, bool *arg22, float *arg33"));
    }
}
