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

import static org.genivi.capic.core.XGenerator.Domain.*

import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FArgument

class XGenerator {

	enum Domain {Capic, SdBus, Printf}


	static class Symbol {
		final String name
		final FTypeRef type
		final boolean isRef
		final Domain domain

		new(String name, FTypeRef type, boolean isRef, Domain domain) {
			this.name = name
			this.type = type
			this.isRef = isRef
			this.domain = domain
		}
		override boolean equals(Object obj) {
			if (obj.class != typeof(Symbol))
				return false
			val Symbol sym = obj as Symbol
			name == sym.name && type.match(sym.type) && isRef == sym.isRef && domain == sym.domain
		}
		def match(FTypeRef it, FTypeRef obj) {
			return predefined != FBasicTypeId.UNDEFINED && predefined == obj.predefined
		}
		override def String toString() {
			"Symbol name=" + name + ", type=" + type.predefined.toString() +
					", isRef=" + isRef.toString() + ", domain=" + domain.toString()
		}
		def byVal(Domain domain) {
			new Symbol(this.name, this.type, false, domain)
		}
		def byRef(Domain domain) {
			new Symbol(this.name, this.type, true, domain)
		}
	}


	def generateClientInterfaceHeader(FInterface api) '''
		«copyrightNotice»

		#ifndef «api.clientHeaderGuard»
		#define «api.clientHeaderGuard»

		#include <stdint.h>
		#include <stdbool.h>


		#ifdef __cplusplus
		extern "C" {
		#endif

		«api.clientTypeSignature»;

		«FOR m : api.methods»
		«IF !m.fireAndForget»
		typedef void (*«m.clientReplyTypeName»)(«api.clientTypeSignature» *instance«m.outArgs.byVal(Capic).asParam»);
		«ENDIF»
		«ENDFOR»

		«FOR m : api.methods»
		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance«m.inArgs.byVal(Capic).asParam»«m.outArgs.byRef(Capic).asParam»);
		«IF !m.fireAndForget»
		int cc_«api.name»_«m.name»_async(«api.clientTypeSignature» *instance«m.inArgs.byVal(Capic).asParam», «m.clientReplyTypeName» callback);
		«ENDIF»

		«ENDFOR»
		int «api.clientMethodPrefix»_new(const char *address, void *data, «api.clientTypeSignature» **instance);
		«api.clientTypeSignature» *«api.clientMethodPrefix»_free(«api.clientTypeSignature» *instance);
		void *«api.clientMethodPrefix»_get_data(«api.clientTypeSignature» *instance);


		#ifdef __cplusplus
		}
		#endif


		#endif /* ifndef «api.clientHeaderGuard» */
	'''


	def generateClientInterfaceBody(FInterface api) '''
		«copyrightNotice»

		#include "src-gen/client-«api.name».h"

		#include <assert.h>
		#include <errno.h>
		#include <stdlib.h>
		#include <inttypes.h>
		#include <capic/backend.h>
		#include <capic/dbus-private.h>
		#include <capic/log.h>


		«api.clientTypeSignature» {
			struct cc_instance *instance;
			void *data;
			«FOR m : api.methods»
			«IF !m.fireAndForget»
			«m.clientReplyTypeName» «m.name»_reply_callback;
			sd_bus_slot *«m.name»_reply_slot;
			«ENDIF»
			«ENDFOR»
		};

		«FOR m : api.methods»
		«IF m.isFireAndForget»

		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance«m.inArgs.byVal(Capic).asParam»)
		{
			int result = 0;
			struct cc_instance *i;
			sd_bus_message *message = NULL;

			CC_LOG_DEBUG("invoked cc_«api.name»_«m.name»()\n");
			assert(instance);
			i = instance->instance;
			assert(i && i->backend && i->backend->bus);
			assert(i->service && i->path && i->interface);

			result = sd_bus_message_new_method_call(
				i->backend->bus, &message, i->service, i->path, i->interface, "«m.name»");
			if (result < 0) {
				CC_LOG_ERROR("unable to create message: %s\n", strerror(-result));
				goto fail;
			}
			«IF !m.inArgs.empty»
			result = sd_bus_message_append(message, «m.inArgs.byVal(Capic).asSdBusSig»«m.inArgs.byVal(Capic).asRVal(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to append message method arguments: %s\n", strerror(-result));
				goto fail;
			}
			«ENDIF»
			result = sd_bus_message_set_expect_reply(message, 0);
			if (result < 0) {
				CC_LOG_ERROR("unable to flag message no-reply-expected: %s\n", strerror(-result));
				goto fail;
			}
			/* Setting cookie=NULL in sd_bus_send() call makes the previous one redundant */
			result = sd_bus_send(i->backend->bus, message, NULL);
			if (result < 0) {
				CC_LOG_ERROR("unable to send message: %s\n", strerror(-result));
				goto fail;
			}

		fail:
			message = sd_bus_message_unref(message);

			return result;
		}
		«ELSE»

		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance«m.inArgs.byVal(Capic).asParam»«m.outArgs.byRef(Capic).asParam»)
		{
			int result = 0;
			struct cc_instance *i;
			sd_bus_message *message = NULL;
			sd_bus_message *reply = NULL;
			sd_bus_error error = SD_BUS_ERROR_NULL;
			«val outArgsDiff = m.outArgs.byVal(SdBus).diffBySig(m.outArgs.byVal(Capic))»
			«FOR s : outArgsDiff»
			«s.byVal(SdBus).asSig»«s.byVal(SdBus).asLVal(SdBus)»;
			«ENDFOR»

			CC_LOG_DEBUG("invoked cc_«api.name»_«m.name»()\n");
			assert(instance);
			i = instance->instance;
			assert(i && i->backend && i->backend->bus);
			assert(i->service && i->path && i->interface);

			if (instance->«m.name»_reply_slot) {
				CC_LOG_ERROR("unable to call method with already pending reply\n");
				return -EBUSY;
			}
			assert(!instance->«m.name»_reply_callback);

			result = sd_bus_call_method(
				i->backend->bus, i->service, i->path, i->interface, "«m.name»", &error, &reply, «m.inArgs.byVal(Capic).asSdBusSig»«m.inArgs.byVal(Capic).asRVal(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
				goto fail;
			}
			result = sd_bus_message_read(reply, «m.outArgs.byRef(Capic).asSdBusSig»«m.outArgs.byRef(Capic).asRef(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
				goto fail;
			}
			«FOR s : outArgsDiff»
			«s.byRef(Capic).asLVal(Capic)» = «s.byVal(SdBus).asRVal(Capic)»;
			«ENDFOR»
			CC_LOG_DEBUG("returning «m.outArgs.byRef(Capic).asPrintfFormat»\n"«m.outArgs.byRef(Capic).asRVal(Printf)»);

		fail:
			sd_bus_error_free(&error);
			reply = sd_bus_message_unref(reply);
			message = sd_bus_message_unref(message);

			return result;
		}

		static int «m.clientReplyThunkName»(CC_IGNORE_BUS_ARG sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
		{
			int result = 0;
			sd_bus *bus;
			«api.clientTypeSignature» *ii = («api.clientTypeSignature» *) userdata;
			«m.outArgs.byVal(SdBus).asDecl»

			CC_LOG_DEBUG("invoked «m.clientReplyThunkName»()\n");
			assert(message);
			bus = sd_bus_message_get_bus(message);
			assert(bus);
			assert(ii);
			assert(ii->«m.name»_reply_callback);
			assert(ii->«m.name»_reply_slot == sd_bus_get_current_slot(bus));
			result = sd_bus_message_get_errno(message);
			if (result != 0) {
				CC_LOG_ERROR("failed to receive response: %s\n", strerror(result));
				goto finish;
			}
			result = sd_bus_message_read(message, «m.outArgs.byVal(SdBus).asSdBusSig»«m.outArgs.byVal(SdBus).asRef(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
				goto finish;
			}
			CC_LOG_DEBUG("invoking callback in «m.clientReplyThunkName»()\n");
			CC_LOG_DEBUG("with «m.outArgs.byVal(SdBus).asPrintfFormat»\n"«m.outArgs.byVal(SdBus).asRVal(Printf)»);
			ii->«m.name»_reply_callback(ii«m.outArgs.byVal(SdBus).asRVal(Capic)»);
			result = 1;

		finish:
			ii->«m.name»_reply_callback = NULL;
			ii->«m.name»_reply_slot = sd_bus_slot_unref(ii->«m.name»_reply_slot);

			return result;
		}

		int cc_«api.name»_«m.name»_async(«api.clientTypeSignature» *instance«m.inArgs.byVal(Capic).asParam», «m.clientReplyTypeName» callback)
		{
			int result = 0;
			struct cc_instance *i;
			sd_bus_message *message = NULL;

			CC_LOG_DEBUG("invoked cc_«api.name»_«m.name»_async()\n");
			assert(instance);
			assert(callback);
			i = instance->instance;
			assert(i && i->backend && i->backend->bus);
			assert(i->service && i->path && i->interface);

			if (instance->«m.name»_reply_slot) {
				CC_LOG_ERROR("unable to call method with already pending reply\n");
				return -EBUSY;
			}
			assert(!instance->«m.name»_reply_callback);

			result = sd_bus_message_new_method_call(
				i->backend->bus, &message, i->service, i->path, i->interface, "«m.name»");
			if (result < 0) {
				CC_LOG_ERROR("unable to create message: %s\n", strerror(-result));
				goto fail;
			}
			result = sd_bus_message_append(message, «m.inArgs.byVal(Capic).asSdBusSig»«m.inArgs.byVal(Capic).asRVal(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to append message method arguments: %s\n", strerror(-result));
				goto fail;
			}

			result = sd_bus_call_async(
				i->backend->bus, &instance->«m.name»_reply_slot, message, &«m.clientReplyThunkName»,
				instance, CC_DBUS_ASYNC_CALL_TIMEOUT_USEC);
			if (result < 0) {
				CC_LOG_ERROR("unable to issue method call: %s\n", strerror(-result));
				goto fail;
			}
			instance->«m.name»_reply_callback = callback;

		fail:
			message = sd_bus_message_unref(message);

			return result;
		}
		«ENDIF»
		«ENDFOR»

		int «api.clientMethodPrefix»_new(const char *address, void *data, «api.clientTypeSignature» **instance)
		{
			int result;
			«api.clientTypeSignature» *ii;

			CC_LOG_DEBUG("invoked «api.clientMethodPrefix»_new\n");
			assert(address);
			assert(instance);

			ii = («api.clientTypeSignature» *) calloc(1, sizeof(*ii));
			if (!ii) {
				CC_LOG_ERROR("failed to allocate instance memory\n");
				return -ENOMEM;
			}

			result = cc_instance_new(address, false, &ii->instance);
			if (result < 0) {
				CC_LOG_ERROR("failed to create instance: %s\n", strerror(-result));
				goto fail;
			}
			ii->data = data;

			*instance = ii;
			return 0;

		fail:
			ii = «api.clientMethodPrefix»_free(ii);
			return result;
		}

		«api.clientTypeSignature» *«api.clientMethodPrefix»_free(«api.clientTypeSignature» *instance)
		{
			CC_LOG_DEBUG("invoked «api.clientMethodPrefix»_free()\n");
			if (instance) {
				«FOR m : api.methods»
				«IF !m.fireAndForget»
				instance->«m.name»_reply_slot = sd_bus_slot_unref(instance->«m.name»_reply_slot);
				«ENDIF»
				«ENDFOR»
				instance->instance = cc_instance_free(instance->instance);
				/* User is responsible for memory management of data. */
				free(instance);
			}
			return NULL;
		}

		void *«api.clientMethodPrefix»_get_data(«api.clientTypeSignature» *instance)
		{
			assert(instance);
			return instance->data;
		}
	'''


	def generateServerInterfaceHeader(FInterface api) '''
		«copyrightNotice»

		#ifndef «api.serverHeaderGuard»
		#define «api.serverHeaderGuard»

		#include <stdint.h>
		#include <stdbool.h>


		#ifdef __cplusplus
		extern "C" {
		#endif

		«api.serverTypeSignature»;

		«FOR m : api.methods»
		typedef int (*cc_«api.name»_«m.name»_t)(«api.serverTypeSignature» *instance«m.inArgs.byVal(Capic).asParam»«m.outArgs.byRef(Capic).asParam»);
		«ENDFOR»

		«api.serverImplTypeSignature» {
			«FOR m : api.methods»
			cc_«api.name»_«m.name»_t «m.name»;
			«ENDFOR»
		};

		int «api.serverMethodPrefix»_new(const char *address, const «api.serverImplTypeSignature» *impl, void *data, «api.serverTypeSignature» **instance);
		«api.serverTypeSignature» *«api.serverMethodPrefix»_free(«api.serverTypeSignature» *instance);
		void *«api.serverMethodPrefix»_get_data(«api.serverTypeSignature» *instance);


		#ifdef __cplusplus
		}
		#endif


		#endif /* ifndef «api.serverHeaderGuard» */
	'''


	def generateServerInterfaceBody(FInterface api) '''
		«copyrightNotice»

		#include "src-gen/server-«api.name».h"

		#include <assert.h>
		#include <errno.h>
		#include <stdlib.h>
		#include <capic/backend.h>
		#include <capic/dbus-private.h>
		#include <capic/log.h>


		«api.serverTypeSignature» {
			struct cc_instance *instance;
			void *data;
			const «api.serverImplTypeSignature» *impl;
			struct sd_bus_slot *vtable_slot;
		};

		«FOR m : api.methods»

		static int «m.serverThunkName»(CC_IGNORE_BUS_ARG sd_bus_message *m, void *userdata, sd_bus_error *error)
		{
			int result = 0;
			«api.serverTypeSignature» *ii = («api.serverTypeSignature» *) userdata;
			«m.inArgs.byVal(SdBus).asDecl»
			«m.outArgs.byVal(Capic).asDecl»

			CC_LOG_DEBUG("invoked «m.serverThunkName»()\n");
			assert(m);
			assert(ii && ii->impl);
			CC_LOG_DEBUG("with path='%s'\n", sd_bus_message_get_path(m));

			result = sd_bus_message_read(m, «m.inArgs.byVal(SdBus).asSdBusSig»«m.inArgs.byVal(SdBus).asRef(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to read method parameters: %s\n", strerror(-result));
				return result;
			}
			if (!ii->impl->«m.name») {
				CC_LOG_ERROR("unsupported method invoked: %s\n", "«api.name».«m.name»");
				sd_bus_error_set(error, SD_BUS_ERROR_NOT_SUPPORTED, "instance does not support method «api.name».«m.name»");
				sd_bus_reply_method_error(m, error);
				return -ENOTSUP;
			}
			result = ii->impl->«m.name»(ii«m.inArgs.byVal(SdBus).asRVal(Capic)»«m.outArgs.byVal(Capic).asRef(Capic)»);
			if (result < 0) {
				CC_LOG_ERROR("failed to execute method: %s\n", strerror(-result));
				sd_bus_error_setf(error, SD_BUS_ERROR_FAILED, "method implementation failed with error=%d", result);
				sd_bus_reply_method_error(m, error);
				return result;
			}
			«IF !m.fireAndForget»
			result = sd_bus_reply_method_return(m, «m.outArgs.byVal(Capic).asSdBusSig»«m.outArgs.byVal(Capic).asRVal(SdBus)»);
			if (result < 0) {
				CC_LOG_ERROR("unable to send method reply: %s\n", strerror(-result));
				return result;
			}
			«ENDIF»

			/* Successful method invocation must return >0 */
			return 1;
		}
		«ENDFOR»

		static const sd_bus_vtable vtable_«api.name»[] = {
			SD_BUS_VTABLE_START(0),
			«FOR m : api.methods»
			SD_BUS_METHOD("«m.name»", «m.inArgs.byVal(SdBus).asSdBusSig», «m.outArgs.byVal(SdBus).asSdBusSig», &«m.serverThunkName», «IF m.fireAndForget»SD_BUS_VTABLE_METHOD_NO_REPLY | «ENDIF»SD_BUS_VTABLE_UNPRIVILEGED),
			«ENDFOR»
			SD_BUS_VTABLE_END
		};

		int «api.serverMethodPrefix»_new(const char *address, const «api.serverImplTypeSignature» *impl, void *data, «api.serverTypeSignature» **instance)
		{
			int result;
			«api.serverTypeSignature» *ii;
			struct cc_instance *i;

			CC_LOG_DEBUG("invoked «api.serverMethodPrefix»_new\n");
			assert(address);
			assert(impl);
			assert(instance);

			ii = («api.serverTypeSignature» *) calloc(1, sizeof(*ii));
			if (!ii) {
				CC_LOG_ERROR("failed to allocate instance memory\n");
				return -ENOMEM;
			}

			result = cc_instance_new(address, true, &i);
			if (result < 0) {
				CC_LOG_ERROR("failed to create instance: %s\n", strerror(-result));
				goto fail;
			}
			ii->instance = i;
			ii->impl = impl;
			ii->data = data;

			result = sd_bus_add_object_vtable(i->backend->bus, &ii->vtable_slot, i->path, i->interface, vtable_«api.name», ii);
			if (result < 0) {
				CC_LOG_ERROR("unable to initialize instance vtable: %s\n", strerror(-result));
				goto fail;
			}

			*instance = ii;
			return 0;

		fail:
			ii = «api.serverMethodPrefix»_free(ii);
			return result;
		}

		«api.serverTypeSignature» *«api.serverMethodPrefix»_free(«api.serverTypeSignature» *instance)
		{
			CC_LOG_DEBUG("invoked «api.serverMethodPrefix»_free()\n");
			if (instance) {
				instance->vtable_slot = sd_bus_slot_unref(instance->vtable_slot);
				instance->instance = cc_instance_free(instance->instance);
				/* User is resposible for memory management of impl and data. */
				free(instance);
			}
			return NULL;
		}

		void *«api.serverMethodPrefix»_get_data(«api.serverTypeSignature» *instance)
		{
			assert(instance);
			return instance->data;
		}
	'''


	def copyrightNotice() '''
		/* This file is created by Common API C code generator automatically. */'''


	def clientHeaderGuard(FInterface it) '''
		INCLUDED_CLIENT_«it.name.toUpperCase»'''


	def clientTypeSignature(FInterface it) '''
		struct cc_client_«it.name»'''


	def clientMethodPrefix(FInterface it) '''
		cc_client_«it.name»'''


	def clientReplyTypeName(FMethod it) '''
		cc_«it.apiName»_«it.name»_reply_t'''


	def clientReplyThunkName(FMethod it) '''
		cc_«it.apiName»_«it.name»_reply_thunk'''


	def serverHeaderGuard(FInterface it) '''
		INCLUDED_SERVER_«it.name.toUpperCase»'''


	def serverTypeSignature(FInterface it) '''
		struct cc_server_«it.name»'''


	def serverMethodPrefix(FInterface it) '''
		cc_server_«it.name»'''


	def serverImplTypeSignature(FInterface it) '''
		struct cc_server_«it.name»_impl'''


	def serverThunkName(FMethod it) '''
		cc_«it.apiName»_«it.name»_thunk'''


	def apiName(FMethod it) {
		var api = it.eContainer()
		api.eGet(api.eClass().getEStructuralFeature("name"))
	}


	static def inArgs(FMethod it) {
		getInArgs()
	}


	static def outArgs(FMethod it) {
		getOutArgs()
	}


	static def byVal(Iterable<FArgument> it, Domain domain) {
		map[a | byVal(a, domain)]
	}


	static def byRef(Iterable<FArgument> it, Domain domain) {
		map[a | byRef(a, domain)]
	}


	static def asParam(Iterable<Symbol> it) '''
		«FOR s : it», «s.asParam»«ENDFOR»'''


	static def asDecl(Iterable<Symbol> it) '''
		«FOR s : it»«s.asDecl»;
		«ENDFOR»'''


	static def asAssign(Iterable<Symbol> it, Iterable<Symbol> ss) '''
		«if (it.size != ss.size)
			throw new IllegalArgumentException("Sequences must have the same size")»
		«val iter = ss.iterator()»
		«val pairs = map[ s | s -> iter.next ]»
		«FOR p : pairs»«p.key.asAssign(p.value)»;
		«ENDFOR»'''


	static def asRVal(Iterable<Symbol> it, Domain domain) '''
		«FOR s : it», «s.asRVal(domain)»«ENDFOR»'''


	static def asRef(Iterable<Symbol> it, Domain domain) '''
		«FOR s : it», «s.asRef(domain)»«ENDFOR»'''


	static def Iterable<Symbol> diffBySig(Iterable<Symbol> it, Iterable<Symbol> ss) {
		if (it.size != ss.size)
			throw new IllegalArgumentException("Sequences must have the same size")
		var result = newArrayList()
		for (var n = 0; n < it.size; n++)
			if (it.get(n).asSig != ss.get(n).asSig)
				result.add(it.get(n))
		return result
	}


	static def byVal(FArgument it, Domain domain) {
		new Symbol(name, type, false, domain)
	}


	static def byRef(FArgument it, Domain domain) {
		new Symbol(name, type, true, domain)
	}


	static def asParam(Symbol it) {
		asSig + name
	}


	static def asDecl(Symbol it) {
		asSig + asLVal(domain)
	}


	static def asAssign(Symbol it, Symbol sym) {
		asLVal(domain) + " = " + sym.asRVal(domain)
	}


	static def asCapicSig(FTypeRef it) {
		if (predefined == FBasicTypeId.UNDEFINED)
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		switch (predefined) {
			case FBasicTypeId::BOOLEAN:     "bool "
			case FBasicTypeId::INT8:        "int8_t "
			case FBasicTypeId::INT16:       "int16_t "
			case FBasicTypeId::INT32:       "int32_t "
			case FBasicTypeId::INT64:       "int64_t "
			case FBasicTypeId::UINT8:       "uint8_t "
			case FBasicTypeId::UINT16:      "uint16_t "
			case FBasicTypeId::UINT32:      "uint32_t "
			case FBasicTypeId::UINT64:      "uint64_t "
			case FBasicTypeId::FLOAT:       "float "
			case FBasicTypeId::DOUBLE:      "double "
			default: throw new IllegalArgumentException("Unsupported basic type " + predefined.toString)
		}
	}


	static def asSig(Symbol it) {
		if (it.domain == Capic && !it.isRef)
			return type.asCapicSig
		if (it.domain == Capic && it.isRef)
			return type.asCapicSig + "*"
		if (it.domain == SdBus && !it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "int "
				case FBasicTypeId::FLOAT:       "double "
				case FBasicTypeId::INT8:        "uint8_t "
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      type.asCapicSig
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		throw new UnsupportedOperationException("FIXME: Unsupported symbol transformation")
	}


	static def asRVal(Symbol it, Domain domain) {
		if (it.domain == Capic && domain == Capic && !it.isRef)
			return name
		if (it.domain == Capic && domain == SdBus && !it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "(int) " + name
				case FBasicTypeId::FLOAT:       "(double) " + name
				case FBasicTypeId::INT8:        "(uint8_t) " + name
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		if (it.domain == Capic && domain == Printf && it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "(int) *" + name
				case FBasicTypeId::FLOAT:       "(double) *" + name
				case FBasicTypeId::INT8,
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      "*" + name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		if (it.domain == SdBus && domain == Capic && !it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "!!" + name + "_int"
				case FBasicTypeId::FLOAT:       "(float) " + name + "_double"
				case FBasicTypeId::INT8:        "(int8_t) " + name + "_uint8_t"
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		if (it.domain == SdBus && domain == Printf && !it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "!!" + name + "_int"
				case FBasicTypeId::FLOAT:       name + "_double"
				case FBasicTypeId::INT8:        "(int8_t) " + name + "_uint8_t"
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		throw new UnsupportedOperationException("FIXME: Unsupported symbol transformation")
	}


	static def asLVal(Symbol it, Domain domain) {
		if (it.domain == Capic && domain == Capic && !it.isRef)
			return name
		if (it.domain == Capic && domain == Capic && it.isRef)
			return "*" + name
		if (it.domain == SdBus && domain == SdBus && !it.isRef) {
			if (type.predefined == FBasicTypeId.UNDEFINED)
				throw new UnsupportedOperationException("Derived and Integer types are not supported")
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     name + "_int"
				case FBasicTypeId::FLOAT:       name + "_double"
				case FBasicTypeId::INT8:        name + "_uint8_t"
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		throw new UnsupportedOperationException("FIXME: Unsupported symbol transformation")
	}


	static def asRef(Symbol it, Domain domain) {
		if (it.domain == Capic && domain == Capic && !it.isRef)
			return "&" + name
		if (it.domain == Capic && domain == SdBus && it.isRef) {
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "&" + name + "_int"
				case FBasicTypeId::FLOAT:       "&" + name + "_double"
				case FBasicTypeId::INT8:        "&" + name + "_uint8_t"
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		if (it.domain == SdBus && domain == SdBus && !it.isRef) {
			return switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "&" + name + "_int"
				case FBasicTypeId::FLOAT:       "&" + name + "_double"
				case FBasicTypeId::INT8:        "&" + name + "_uint8_t"
				case FBasicTypeId::INT16,
				case FBasicTypeId::INT32,
				case FBasicTypeId::INT64,
				case FBasicTypeId::UINT8,
				case FBasicTypeId::UINT16,
				case FBasicTypeId::UINT32,
				case FBasicTypeId::UINT64,
				case FBasicTypeId::DOUBLE:      "&" + name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		}
		throw new UnsupportedOperationException("FIXME: Unsupported symbol transformation")
	}


	static def asPrintfFormat(Iterable<Symbol> it) '''
		«IF empty»void«ELSE»«FOR s : it SEPARATOR ', '»«s.name»=%«s.type.asPrintfSig»«ENDFOR»«ENDIF»'''


	static def asPrintfSig(FTypeRef it) {
		if (predefined == FBasicTypeId.UNDEFINED)
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		switch (predefined) {
			case FBasicTypeId::BOOLEAN:     "d"
			case FBasicTypeId::FLOAT:       "g"
			case FBasicTypeId::INT8:        "\" PRId8 \""
			case FBasicTypeId::INT16:       "\" PRId16 \""
			case FBasicTypeId::INT32:       "\" PRId32 \""
			case FBasicTypeId::INT64:       "\" PRId64 \""
			case FBasicTypeId::UINT8:       "\" PRIu8 \""
			case FBasicTypeId::UINT16:      "\" PRIu16 \""
			case FBasicTypeId::UINT32:      "\" PRIu32 \""
			case FBasicTypeId::UINT64:      "\" PRIu64 \""
			case FBasicTypeId::DOUBLE:      "g"
			default: throw new IllegalArgumentException("Unsupported basic type " + predefined.toString)
		}
	}


	static def asSdBusSig(Iterable<Symbol> it) '''
		"«FOR s : it»«s.type.asSdBusSig»«ENDFOR»"'''


	static def asSdBusSig(FTypeRef it) {
		if (predefined == FBasicTypeId.UNDEFINED)
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		switch (predefined) {
			case FBasicTypeId::BOOLEAN:     "b"
			case FBasicTypeId::INT8:        "y"
			case FBasicTypeId::INT16:       "n"
			case FBasicTypeId::INT32:       "i"
			case FBasicTypeId::INT64:       "x"
			case FBasicTypeId::UINT8:       "y"
			case FBasicTypeId::UINT16:      "q"
			case FBasicTypeId::UINT32:      "u"
			case FBasicTypeId::UINT64:      "t"
			case FBasicTypeId::FLOAT:       "d"
			case FBasicTypeId::DOUBLE:      "d"
			default: throw new IllegalArgumentException("Unsupported basic type " + predefined.toString)
		}
	}

}
