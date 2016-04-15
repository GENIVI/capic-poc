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
package org.genivi.capic.core

import static org.junit.Assert.*
import static org.hamcrest.CoreMatchers.*
import static org.genivi.capic.core.XGenerator.Domain.*
import static extension org.genivi.capic.core.XGenerator.*
import static org.genivi.capic.core.MockFModel.*

import org.eclipse.xtext.junit4.XtextRunner
import org.eclipse.xtext.junit4.InjectWith
import org.franca.core.dsl.FrancaIDLTestsInjectorProvider
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FArgument
import org.franca.core.franca.FMethod
import org.genivi.capic.core.XGenerator
import org.hamcrest.Matcher
import org.junit.runner.RunWith
import org.junit.Test
import org.junit.Assert

@RunWith(XtextRunner)
@InjectWith(FrancaIDLTestsInjectorProvider)
class XGeneratorTest {

	static def assertThatSeq(CharSequence s, Matcher<String> matcher) {
		Assert.assertThat("", s.toString(), matcher)
	}


	@Test
	def testBasicTypeMappingToCapicSignature() {
		assertThat(makeTypeRef().getPredefined(), is(FBasicTypeId.UNDEFINED))
		try { makeTypeRef().asSdBusSig; fail("Expected UnsupportedOperationException"); }
		catch (UnsupportedOperationException e) {}
		assertThat(makeTypeRef(FBasicTypeId.BOOLEAN).asCapicSig, is("bool "))
		assertThat(makeTypeRef(FBasicTypeId.INT8).asCapicSig, is("int8_t "))
		assertThat(makeTypeRef(FBasicTypeId.INT16).asCapicSig, is("int16_t "))
		assertThat(makeTypeRef(FBasicTypeId.INT32).asCapicSig, is("int32_t "))
		assertThat(makeTypeRef(FBasicTypeId.INT64).asCapicSig, is("int64_t "))
		assertThat(makeTypeRef(FBasicTypeId.UINT8).asCapicSig, is("uint8_t "))
		assertThat(makeTypeRef(FBasicTypeId.UINT16).asCapicSig, is("uint16_t "))
		assertThat(makeTypeRef(FBasicTypeId.UINT32).asCapicSig, is("uint32_t "))
		assertThat(makeTypeRef(FBasicTypeId.UINT64).asCapicSig, is("uint64_t "))
		assertThat(makeTypeRef(FBasicTypeId.FLOAT).asCapicSig, is("float "))
		assertThat(makeTypeRef(FBasicTypeId.DOUBLE).asCapicSig, is("double "))
		try { makeTypeRef(FBasicTypeId.BYTE_BUFFER).asCapicSig; fail("Expected IllegalArgumentException"); }
		catch (IllegalArgumentException e) {}
		return
	}


	@Test
	def testTypeSignatures() {
		val xgen = new XGenerator()
		val Iterable<FMethod> methods = #[makeMethod("func")]
		val api = makeInterface("ApiName", methods)
		assertThatSeq(xgen.clientTypeSignature(api), is("struct cc_client_ApiName"))
		assertThatSeq(xgen.clientReplyTypeName(methods.get(0)), is("cc_ApiName_func_reply_t"))
		assertThatSeq(xgen.clientReplyThunkName(methods.get(0)), is("cc_ApiName_func_reply_thunk"))
		assertThatSeq(xgen.serverTypeSignature(api), is("struct cc_server_ApiName"))
		assertThatSeq(xgen.serverImplTypeSignature(api), is("struct cc_server_ApiName_impl"))
		assertThatSeq(xgen.serverThunkName(methods.get(0)), is("cc_ApiName_func_thunk"))
	}


	@Test
	def testMethodPrefixes() {
		val xgen = new XGenerator()
		val api = makeInterface("TestInterface")
		assertThatSeq(xgen.clientMethodPrefix(api), is("cc_client_TestInterface"))
		assertThatSeq(xgen.serverMethodPrefix(api), is("cc_server_TestInterface"))
	}


	@Test
	def testHeaderGuards() {
		val xgen = new XGenerator()
		val api = MockFModel.makeInterface("MyService")
		assertThatSeq(xgen.clientHeaderGuard(api), is("INCLUDED_CLIENT_MYSERVICE"))
		assertThatSeq(xgen.serverHeaderGuard(api), is("INCLUDED_SERVER_MYSERVICE"))
	}


	@Test
	def testEmtpyArguments() {
		val Iterable<FArgument> inArgs = #[]
		val Iterable<FArgument> outArgs = #[]
		val method = makeMethod(inArgs, outArgs)
		assertThatSeq(method.inArgs.byVal(Capic).asParam, is(""))
		assertThatSeq(method.outArgs.byRef(Capic).asParam, is(""))
		assertThatSeq(method.outArgs.byVal(Capic).asParam, is(""))
	}


	@Test
	def testArguments() {
		val inArgs = #[
				makeArgument(FBasicTypeId.INT32, "arg1"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg2")]
		val outArgs = #[
				makeArgument(FBasicTypeId.UINT8, "arg10"),
				makeArgument(FBasicTypeId.DOUBLE, "arg20")]
		val method = makeMethod(inArgs, outArgs)
		assertSame(method.getInArgs(), method.inArgs)
		assertSame(method.getOutArgs(), method.outArgs)
		assertThatSeq(method.inArgs.byVal(Capic).asParam, is(", int32_t arg1, bool arg2"))
		assertThatSeq(method.outArgs.byRef(Capic).asParam, is(", uint8_t *arg10, double *arg20"))
		assertThatSeq(method.outArgs.byVal(Capic).asParam, is(", uint8_t arg10, double arg20"))
	}


	@Test
	def testClientMethodPrototypes() {
		val xgen = new XGenerator()
		val inArgs = #[
				makeArgument(FBasicTypeId.INT32, "arg1"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg2")]
		val outArgs = #[
				makeArgument(FBasicTypeId.UINT8, "arg10"),
				makeArgument(FBasicTypeId.DOUBLE, "arg20")]
		val methods = #[makeMethod("method", inArgs, outArgs, false)]
		val api = makeInterface("TestApi", methods)
		val clientHeader = xgen.generateClientInterfaceHeader(api).toString()
		assertThat(clientHeader, containsString(
				"(*cc_TestApi_method_reply_t)(struct cc_client_TestApi *instance, uint8_t arg10, double arg20"))
		assertThat(clientHeader, containsString(
				"cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, uint8_t *arg10, double *arg20"))
		assertThat(clientHeader, containsString(
				"cc_TestApi_method_async(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, cc_TestApi_method_reply_t callback"))
		val clientBody = xgen.generateClientInterfaceHeader(api).toString()
		assertThat(clientBody, containsString(
				"cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, uint8_t *arg10, double *arg20"))
		assertThat(clientBody, containsString(
				"cc_TestApi_method_async(struct cc_client_TestApi *instance, int32_t arg1, bool arg2, cc_TestApi_method_reply_t callback"))
	}


	@Test
	def testClientFireAndForgetMethodPrototypes() {
		val xgen = new XGenerator()
		val inArgs = #[
				makeArgument(FBasicTypeId.INT32, "arg1"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg2")]
		val methods = #[makeMethodFireAndForget("method", inArgs)]
		val api = makeInterface("TestApi", methods)
		val clientHeader = xgen.generateClientInterfaceHeader(api).toString()
		assertThat(clientHeader, not(containsString("cc_TestApi_method_reply_t")))
		assertThat(clientHeader, containsString(
				"cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2"))
		assertThat(clientHeader, not(containsString("cc_TestApi_method_async")))
		val clientBody = xgen.generateClientInterfaceHeader(api).toString()
		assertThat(clientBody, containsString(
				"cc_TestApi_method(struct cc_client_TestApi *instance, int32_t arg1, bool arg2"))
		assertThat(clientBody, not(containsString("cc_TestApi_method_async")))
	}


	@Test
	def testClientMethodBodies() {
		val xgen = new XGenerator()
		val inArgs = #[
				makeArgument(FBasicTypeId.INT32, "arg1"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg2")]
		val outArgs = #[
				makeArgument(FBasicTypeId.UINT8, "arg10"),
				makeArgument(FBasicTypeId.DOUBLE, "arg20")]
		val methods = #[makeMethod("method", inArgs, outArgs, false)]
		val api = makeInterface("TestApi", methods)
		val serverBody = xgen.generateClientInterfaceBody(api).toString()
		assertThat(serverBody, containsString("(void) ret_error;"))
	}


	@Test
	def testServerMethodPrototypes() {
		val xgen = new XGenerator()
		val inArgs = #[
				makeArgument(FBasicTypeId.UINT16, "arg01"),
				makeArgument(FBasicTypeId.INT64, "arg02")]
		val outArgs = #[
				makeArgument(FBasicTypeId.INT8, "arg11"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg22"),
				makeArgument(FBasicTypeId.FLOAT, "arg33")]
		val methods = #[makeMethod("func", inArgs, outArgs)]
		val api = makeInterface("MyService", methods)
		val serverHeader = xgen.generateServerInterfaceHeader(api).toString()
		assertThat(serverHeader, containsString(
				"(*cc_MyService_func_t)(struct cc_server_MyService *instance, uint16_t arg01, int64_t arg02, int8_t *arg11, bool *arg22, float *arg33"))
	}


	@Test
	def testServerMethodBodies() {
		val xgen = new XGenerator()
		val inArgs = #[
				makeArgument(FBasicTypeId.UINT16, "arg01"),
				makeArgument(FBasicTypeId.INT64, "arg02")]
		val outArgs = #[
				makeArgument(FBasicTypeId.INT8, "arg11"),
				makeArgument(FBasicTypeId.BOOLEAN, "arg22"),
				makeArgument(FBasicTypeId.FLOAT, "arg33")]
		val methods = #[makeMethod("func", inArgs, outArgs), makeMethodFireAndForget("fire", null)]
		val api = makeInterface("MyService", methods)
		val serverBody = xgen.generateServerInterfaceBody(api).toString()
		assertThat(serverBody, containsString(
				"SD_BUS_METHOD(\"func\", \"qx\", \"ybd\", &cc_MyService_func_thunk, SD_BUS_VTABLE_UNPRIVILEGED),"))
		assertThat(serverBody, containsString(
				"SD_BUS_METHOD(\"fire\", \"\", \"\", &cc_MyService_fire_thunk, SD_BUS_VTABLE_METHOD_NO_REPLY | SD_BUS_VTABLE_UNPRIVILEGED),"))
	}


	@Test
	def testSymbolAsValAndRef() {
		val arg = makeArgument(FBasicTypeId.INT32, "n1")
		assertThat(arg.byVal(SdBus).byRef(Capic), is(arg.byRef(Capic)))
		assertThat(arg.byRef(SdBus).byRef(Capic), is(arg.byRef(Capic)))
		assertThat(arg.byVal(Capic).byVal(SdBus), is(arg.byVal(SdBus)))
		assertThat(arg.byRef(Capic).byVal(SdBus), is(arg.byVal(SdBus)))
	}


	@Test
	def testCapicSymbolsAsParam() {
		assertThatSeq(#[].byVal(Capic).asParam, is(""))
		assertThatSeq(#[].byRef(Capic).asParam, is(""))
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "p1"),
			makeArgument(FBasicTypeId.FLOAT, "p2"),
			makeArgument(FBasicTypeId.INT8, "p3"),
			makeArgument(FBasicTypeId.UINT32, "p4")]
		val args = makeArgList(argList)
		assertThatSeq(args.byVal(Capic).asParam, is(", bool p1, float p2, int8_t p3, uint32_t p4"))
		assertThatSeq(args.byRef(Capic).asParam, is(", bool *p1, float *p2, int8_t *p3, uint32_t *p4"))
	}


	@Test
	def testSdBusSymbolsAsDecl() {
		assertThatSeq(#[].byVal(SdBus).asDecl, is(""))
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "v1"),
			makeArgument(FBasicTypeId.FLOAT, "v2"),
			makeArgument(FBasicTypeId.INT8, "v3"),
			makeArgument(FBasicTypeId.UINT32, "v4")]
		val args = makeArgList(argList)
		assertThatSeq(args.byVal(SdBus).asDecl, is("int v1_int;\ndouble v2_double;\nuint8_t v3_uint8_t;\nuint32_t v4;\n"))
	}


	@Test
	def testSdBusSymbolsAsAssign() {
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "vv1"),
			makeArgument(FBasicTypeId.FLOAT, "vv2"),
			makeArgument(FBasicTypeId.INT8, "vv3")]
		val args = makeArgList(argList)
		assertThatSeq(args.byRef(Capic).asAssign(args.byVal(SdBus)), is("*vv1 = !!vv1_int;\n*vv2 = (float) vv2_double;\n*vv3 = (int8_t) vv3_uint8_t;\n"))
	}


	@Test
	def testEmptySymbolsMapping() {
		val FArgument[] argList = #[]
		val args = makeArgList(argList)
		assertThatSeq(args.byVal(Capic).asRVal(SdBus), is(""))
		assertThatSeq(args.byRef(Capic).asRef(SdBus), is(""))
		assertThatSeq(args.byRef(Capic).asRVal(Printf), is(""))
		assertThatSeq(args.byVal(SdBus).asRVal(Capic), is(""))
		assertThatSeq(args.byVal(SdBus).asRVal(Printf), is(""))
		assertThatSeq(args.byVal(SdBus).asRef(SdBus), is(""))
	}


	@Test
	def testSymbolsMapping() {
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "a1"),
			makeArgument(FBasicTypeId.FLOAT, "a2"),
			makeArgument(FBasicTypeId.INT8, "a3"),
			makeArgument(FBasicTypeId.UINT32, "a4")]
		val args = makeArgList(argList)
		assertThatSeq(args.byVal(Capic).asRVal(SdBus), is(", (int) a1, (double) a2, (uint8_t) a3, a4"))
		assertThatSeq(args.byRef(Capic).asRef(SdBus), is(", &a1_int, &a2_double, &a3_uint8_t, a4"))
		assertThatSeq(args.byRef(Capic).asRVal(Printf), is(", (int) *a1, (double) *a2, *a3, *a4"))
		assertThatSeq(args.byVal(SdBus).asRVal(Capic), is(", !!a1_int, (float) a2_double, (int8_t) a3_uint8_t, a4"))
		assertThatSeq(args.byVal(SdBus).asRVal(Printf), is(", !!a1_int, a2_double, (int8_t) a3_uint8_t, a4"))
		assertThatSeq(args.byVal(SdBus).asRef(SdBus), is(", &a1_int, &a2_double, &a3_uint8_t, &a4"))
	}


	@Test
	def testSymbolsDiffBySig() {
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.INT16, "s1"),
			makeArgument(FBasicTypeId.BOOLEAN, "s2"),
			makeArgument(FBasicTypeId.FLOAT, "s3"),
			makeArgument(FBasicTypeId.INT8, "s4"),
			makeArgument(FBasicTypeId.UINT32, "s5")]
		val args = makeArgList(argList)
		val FArgument[] argDiffList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "s2"),
			makeArgument(FBasicTypeId.FLOAT, "s3"),
			makeArgument(FBasicTypeId.INT8, "s4")]
		val argsDiff = makeArgList(argDiffList)
		//FIXME: use the right matcher; isEqual does not work as expected for Iterable<Symbol>
		//assertThat(args.byVal(SdBus).diffBySig(args.byVal(Capic)), is(argsDiff.byVal(SdBus)))
		val result = args.byVal(SdBus).diffBySig(args.byVal(Capic))
		assertThat(result.size, is(argsDiff.byVal(SdBus).size))
		assertThat(result, hasItem(argsDiff.byVal(SdBus).get(0)))
		assertThat(result, hasItem(argsDiff.byVal(SdBus).get(1)))
		assertThat(result, hasItem(argsDiff.byVal(SdBus).get(2)))
	}


	@Test
	def testSymbolAsParam() {
		val arg0 = makeArgument(FBasicTypeId.DOUBLE, "q1")
		assertThat(arg0.byVal(Capic).asParam, is("double q1"))
		assertThat(arg0.byRef(Capic).asParam, is("double *q1"))
		val arg1 = makeArgument(FBasicTypeId.INT8, "q2")
		assertThat(arg1.byVal(Capic).asParam, is("int8_t q2"))
		assertThat(arg1.byRef(Capic).asParam, is("int8_t *q2"))
	}


	@Test
	def testSymbolAsDecl() {
		val arg0 = makeArgument(FBasicTypeId.INT64, "p1")
		assertThat(arg0.byVal(Capic).asDecl, is("int64_t p1"))
		assertThat(arg0.byVal(SdBus).asDecl, is("int64_t p1"))
		val arg1 = makeArgument(FBasicTypeId.FLOAT, "p2")
		assertThat(arg1.byVal(Capic).asDecl, is("float p2"))
		assertThat(arg1.byVal(SdBus).asDecl, is("double p2_double"))
	}


	@Test
	def testSymbolAsAssign() {
		val arg0 = makeArgument(FBasicTypeId.BOOLEAN, "x1")
		assertThat(arg0.byRef(Capic).asAssign(arg0.byVal(SdBus)), is("*x1 = !!x1_int"))
		val arg1 = makeArgument(FBasicTypeId.FLOAT, "x2")
		assertThat(arg1.byRef(Capic).asAssign(arg1.byVal(SdBus)), is("*x2 = (float) x2_double"))
		val arg2 = makeArgument(FBasicTypeId.INT8, "x3")
		assertThat(arg2.byRef(Capic).asAssign(arg2.byVal(SdBus)), is("*x3 = (int8_t) x3_uint8_t"))
		val arg3 = makeArgument(FBasicTypeId.INT32, "x4")
		assertThat(arg3.byVal(Capic).asAssign(arg3.byVal(SdBus)), is("x4 = x4"))
	}


	@Test
	def testSymbolAsSig() {
		val arg0 = makeArgument(FBasicTypeId.BOOLEAN, "t1")
		assertThat(arg0.byVal(Capic).asSig, is("bool "))
		assertThat(arg0.byRef(Capic).asSig, is("bool *"))
		assertThat(arg0.byVal(SdBus).asSig, is("int "))
		val arg1 = makeArgument(FBasicTypeId.FLOAT, "t2")
		assertThat(arg1.byVal(Capic).asSig, is("float "))
		assertThat(arg1.byRef(Capic).asSig, is("float *"))
		assertThat(arg1.byVal(SdBus).asSig, is("double "))
		val arg2 = makeArgument(FBasicTypeId.INT8, "t3")
		assertThat(arg2.byVal(Capic).asSig, is("int8_t "))
		assertThat(arg2.byRef(Capic).asSig, is("int8_t *"))
		assertThat(arg2.byVal(SdBus).asSig, is("uint8_t "))
		val arg3 = makeArgument(FBasicTypeId.UINT32, "t4")
		assertThat(arg3.byVal(Capic).asSig, is("uint32_t "))
		assertThat(arg3.byRef(Capic).asSig, is("uint32_t *"))
		assertThat(arg3.byVal(SdBus).asSig, is("uint32_t "))
	}


	@Test
	def testSymbolAsRVal() {
		val arg0 = makeArgument(FBasicTypeId.UINT16, "a1")
		assertThat(arg0.byVal(Capic).asRVal(SdBus), is("a1"))
		assertThat(arg0.byVal(SdBus).asRVal(Capic), is("a1"))
		assertThat(arg0.byVal(SdBus).asRVal(Printf), is("a1"))
		assertThat(arg0.byRef(Capic).asRVal(Printf), is("*a1"))
		val arg1 = makeArgument(FBasicTypeId.BOOLEAN, "a2")
		assertThat(arg1.byVal(Capic).asRVal(SdBus), is("(int) a2"))
		assertThat(arg1.byVal(SdBus).asRVal(Capic), is("!!a2_int"))
		assertThat(arg1.byVal(SdBus).asRVal(Printf), is("!!a2_int"))
		assertThat(arg1.byRef(Capic).asRVal(Printf), is("(int) *a2"))
		val arg2 = makeArgument(FBasicTypeId.FLOAT, "a3")
		assertThat(arg2.byVal(Capic).asRVal(SdBus), is("(double) a3"))
		assertThat(arg2.byVal(SdBus).asRVal(Capic), is("(float) a3_double"))
		assertThat(arg2.byVal(SdBus).asRVal(Printf), is("a3_double"))
		assertThat(arg2.byRef(Capic).asRVal(Printf), is("(double) *a3"))
	}


	@Test
	def testSymbolAsLVal() {
		val arg0 = makeArgument(FBasicTypeId.FLOAT, "s1")
		assertThat(arg0.byVal(SdBus).asLVal(SdBus), is("s1_double"))
		assertThat(arg0.byRef(Capic).asLVal(Capic), is("*s1"))
		val arg1 = makeArgument(FBasicTypeId.INT32, "s2")
		assertThat(arg1.byVal(SdBus).asLVal(SdBus), is("s2"))
		assertThat(arg1.byRef(Capic).asLVal(Capic), is("*s2"))
	}


	@Test
	def testSymbolAsRef() {
		val arg0 =  makeArgument(FBasicTypeId.INT8, "v1")
		assertThat(arg0.byVal(Capic).asRef(Capic), is("&v1"))
		assertThat(arg0.byRef(Capic).asRef(SdBus), is("&v1_uint8_t"))
		assertThat(arg0.byVal(SdBus).asRef(SdBus), is("&v1_uint8_t"))
		val arg1 = makeArgument(FBasicTypeId.UINT64, "v2")
		assertThat(arg1.byVal(Capic).asRef(Capic), is("&v2"))
		assertThat(arg1.byRef(Capic).asRef(SdBus), is("v2"))
		assertThat(arg1.byVal(SdBus).asRef(SdBus), is("&v2"))
	}


	def testBasicTypeMappingToSdBusSig() {
		assertThat(makeTypeRef().getPredefined(), is(FBasicTypeId.UNDEFINED))
		try { makeTypeRef().asSdBusSig; fail("Expected UnsupportedOperationException"); }
		catch (UnsupportedOperationException e) {}
		assertThat(makeTypeRef(FBasicTypeId.BOOLEAN).asSdBusSig, is("b"))
		assertThat(makeTypeRef(FBasicTypeId.INT8).asSdBusSig, is("y"))
		assertThat(makeTypeRef(FBasicTypeId.INT16).asSdBusSig, is("n"))
		assertThat(makeTypeRef(FBasicTypeId.INT32).asSdBusSig, is("i"))
		assertThat(makeTypeRef(FBasicTypeId.INT64).asSdBusSig, is("x"))
		assertThat(makeTypeRef(FBasicTypeId.UINT8).asSdBusSig, is("y"))
		assertThat(makeTypeRef(FBasicTypeId.UINT16).asSdBusSig, is("q"))
		assertThat(makeTypeRef(FBasicTypeId.UINT32).asSdBusSig, is("u"))
		assertThat(makeTypeRef(FBasicTypeId.UINT64).asSdBusSig, is("t"))
		assertThat(makeTypeRef(FBasicTypeId.FLOAT).asSdBusSig, is("d"))
		assertThat(makeTypeRef(FBasicTypeId.DOUBLE).asSdBusSig, is("d"))
		try { makeTypeRef(FBasicTypeId.BYTE_BUFFER).asSdBusSig; fail("Expected IllegalArgumentException"); }
		catch (IllegalArgumentException e) {}
		return
	}


	@Test
	def testSymbolsAsSdBusSig() {
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "p1"),
			makeArgument(FBasicTypeId.DOUBLE, "p2"),
			makeArgument(FBasicTypeId.INT8, "p3"),
			makeArgument(FBasicTypeId.UINT32, "p4"),
			makeArgument(FBasicTypeId.INT64, "p5")]
		val args = makeArgList(argList)
		assertThatSeq(args.byVal(Capic).asSdBusSig, is("\"bdyux\""))
		assertThatSeq(args.byRef(SdBus).asSdBusSig, is("\"bdyux\""))
	}


	def testBasicTypeMappingToPrintfSig() {
		assertThat(makeTypeRef().getPredefined(), is(FBasicTypeId.UNDEFINED))
		try { makeTypeRef().asSdBusSig; fail("Expected UnsupportedOperationException"); }
		catch (UnsupportedOperationException e) {}
		assertThat(makeTypeRef(FBasicTypeId.BOOLEAN).asPrintfSig, is("d"))
		assertThat(makeTypeRef(FBasicTypeId.INT8).asPrintfSig, is("PRId8"))
		assertThat(makeTypeRef(FBasicTypeId.INT16).asPrintfSig, is("PRId16"))
		assertThat(makeTypeRef(FBasicTypeId.INT32).asPrintfSig, is("PRId32"))
		assertThat(makeTypeRef(FBasicTypeId.INT64).asPrintfSig, is("PRId64"))
		assertThat(makeTypeRef(FBasicTypeId.UINT8).asPrintfSig, is("PRIu8"))
		assertThat(makeTypeRef(FBasicTypeId.UINT16).asPrintfSig, is("PRIu16"))
		assertThat(makeTypeRef(FBasicTypeId.UINT32).asPrintfSig, is("PRIu32"))
		assertThat(makeTypeRef(FBasicTypeId.UINT64).asPrintfSig, is("PRIu64"))
		assertThat(makeTypeRef(FBasicTypeId.FLOAT).asPrintfSig, is("g"))
		assertThat(makeTypeRef(FBasicTypeId.DOUBLE).asPrintfSig, is("g"))
		try { makeTypeRef(FBasicTypeId.BYTE_BUFFER).asSdBusSig; fail("Expected IllegalArgumentException"); }
		catch (IllegalArgumentException e) {}
		return
	}


	@Test
	def testSymbolsAsPrintfFormat() {
		assertThatSeq(#[].byRef(Capic).asPrintfFormat, is("void"));
		val FArgument[] argList = #[
			makeArgument(FBasicTypeId.BOOLEAN, "pp1"),
			makeArgument(FBasicTypeId.FLOAT, "pp2"),
			makeArgument(FBasicTypeId.DOUBLE, "pp3"),
			makeArgument(FBasicTypeId.INT8, "pp4"),
			makeArgument(FBasicTypeId.UINT32, "pp5")]
		val args = makeArgList(argList)
		assertThatSeq(args.byRef(Capic).asPrintfFormat, is("pp1=%d, pp2=%g, pp3=%g, pp4=%\" PRId8 \", pp5=%\" PRIu32 \""))
	}
}
