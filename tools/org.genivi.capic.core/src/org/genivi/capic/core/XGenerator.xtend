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
package org.genivi.capic.core

import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FTypedElement
import org.franca.core.franca.FTypeRef

class XGenerator {

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
		typedef void (*cc_«api.name»_«m.name»_reply_t)(«api.clientTypeSignature» *instance«m.replyOutArguments»);
		«ENDIF»
		«ENDFOR»

		«FOR m : api.methods»
		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance«m.inArguments»«m.outArguments»);
		«IF !m.fireAndForget»
		int cc_«api.name»_«m.name»_async(«api.clientTypeSignature» *instance«m.inArguments», cc_«api.name»_«m.name»_reply_t callback);
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
		#include <capic/backend.h>
		#include <capic/dbus-private.h>
		#include <capic/log.h>


		«api.clientTypeSignature» {
			struct cc_instance *instance;
			void *data;
			«FOR m : api.methods»
			«IF !m.fireAndForget»
			cc_«api.name»_«m.name»_reply_t «m.name»_reply_callback;
			sd_bus_slot *«m.name»_reply_slot;
			«ENDIF»
			«ENDFOR»
		};

		«FOR m : api.methods»
		«IF m.isFireAndForget»

		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance)
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
			result = sd_bus_message_append(message, «m.inSignaturesAsDBus»«m.inArgumentsAsDBusWrite»);
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

		int cc_«api.name»_«m.name»(«api.clientTypeSignature» *instance«m.inArguments»«m.outArguments»)
		{
			int result = 0;
			struct cc_instance *i;
			sd_bus_message *message = NULL;
			sd_bus_message *reply = NULL;
			sd_bus_error error = SD_BUS_ERROR_NULL;
			«FOR a : m.outArgs»
			«IF a.type.predefined == FBasicTypeId::BOOLEAN»
			int «a.name»_int;
			«ELSEIF a.type.predefined == FBasicTypeId::INT8»
			uint8_t «a.name»_uint8_t;
			«ELSEIF a.type.predefined == FBasicTypeId::FLOAT»
			double «a.name»_double;
			«ENDIF»
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
				i->backend->bus, i->service, i->path, i->interface, "«m.name»", &error, &reply, «m.inSignaturesAsDBus»«m.inArgumentsAsDBusWrite»);
			if (result < 0) {
				CC_LOG_ERROR("unable to call method: %s\n", strerror(-result));
				goto fail;
			}
			result = sd_bus_message_read(reply, «m.outSignaturesAsDBus»«m.outArgumentsAsDBus»);
			if (result < 0) {
				CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
				goto fail;
			}
			«FOR a : m.outArgs»
			«IF a.type.predefined == FBasicTypeId::BOOLEAN»
			*«a.name» = !!«a.name»_int;
			«ELSEIF a.type.predefined == FBasicTypeId::INT8»
			*«a.name» = (int8_t) «a.name»_uint8_t;
			«ELSEIF a.type.predefined == FBasicTypeId::FLOAT»
			*«a.name» = (float) «a.name»_double;
			«ENDIF»
			«ENDFOR»
			CC_LOG_DEBUG("returning «m.outArgumentsAsDBusLogFormat»\n"«m.outArgumentsAsDBusLog»);

		fail:
			sd_bus_error_free(&error);
			reply = sd_bus_message_unref(reply);
			message = sd_bus_message_unref(message);

			return result;
		}

		static int cc_«api.name»_«m.name»_reply_thunk(CC_IGNORE_BUS_ARG sd_bus_message *message, void *userdata, sd_bus_error *ret_error)
		{
			int result = 0;
			sd_bus *bus;
			«api.clientTypeSignature» *ii = («api.clientTypeSignature» *) userdata;
			«FOR a : m.outArgs»
			«IF a.type.predefined == FBasicTypeId::BOOLEAN»
			int «a.name»_int;
			«ELSEIF a.type.predefined == FBasicTypeId::INT8»
			uint8_t «a.name»_uint8_t;
			«ELSEIF a.type.predefined == FBasicTypeId::FLOAT»
			double «a.name»_double;
			«ELSE»
			«a.type.typeSignature»«a.name»;
			«ENDIF»
			«ENDFOR»

			CC_LOG_DEBUG("invoked cc_«api.name»_«m.name»_reply_thunk()\n");
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
			result = sd_bus_message_read(message, «m.outSignaturesAsDBus»«m.outArgumentsAsDBusThunk»);
			if (result < 0) {
				CC_LOG_ERROR("unable to get reply value: %s\n", strerror(-result));
				goto finish;
			}
			CC_LOG_DEBUG("invoking callback in cc_«api.name»_«m.name»_reply_thunk()\n");
			CC_LOG_DEBUG("with «m.outArgumentsAsDBusLogFormat»\n"«m.outArgumentsAsDBusReply»);
			ii->«m.name»_reply_callback(ii«m.outArgumentsAsDBusReply»);
			result = 1;

		finish:
			ii->«m.name»_reply_callback = NULL;
			ii->«m.name»_reply_slot = sd_bus_slot_unref(ii->«m.name»_reply_slot);

			return result;
		}

		int cc_«api.name»_«m.name»_async(«api.clientTypeSignature» *instance«m.inArguments», cc_«api.name»_«m.name»_reply_t callback)
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
			result = sd_bus_message_append(message, «m.inSignaturesAsDBus»«m.inArgumentsAsDBusWrite»);
			if (result < 0) {
				CC_LOG_ERROR("unable to append message method arguments: %s\n", strerror(-result));
				goto fail;
			}

			result = sd_bus_call_async(
				i->backend->bus, &instance->«m.name»_reply_slot, message, &cc_«api.name»_«m.name»_reply_thunk,
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
		typedef int (*cc_«api.name»_«m.name»_t)(«api.serverTypeSignature» *instance«m.inArguments»«m.outArguments»);
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
			const struct cc_server_«api.name»_impl *impl;
			struct sd_bus_slot *vtable_slot;
		};

		«FOR m : api.methods»

		static int cc_«api.name»_«m.name»_thunk(CC_IGNORE_BUS_ARG sd_bus_message *m, void *userdata, sd_bus_error *error)
		{
			int result = 0;
			«api.serverTypeSignature» *ii = («api.serverTypeSignature» *) userdata;
			«FOR a : m.inArgs»
			«IF a.type.predefined == FBasicTypeId::BOOLEAN»
			int «a.name»_int;
			«ELSEIF a.type.predefined == FBasicTypeId::INT8»
			uint8_t «a.name»_uint8_t;
			«ELSEIF a.type.predefined == FBasicTypeId::FLOAT»
			double «a.name»_double;
			«ELSE»
			«a.type.typeSignature»«a.name»;
			«ENDIF»
			«ENDFOR»
			«FOR a : m.outArgs»
			«a.type.typeSignature»«a.name»;
			«ENDFOR»

			CC_LOG_DEBUG("invoked cc_«api.name»_«m.name»_thunk()\n");
			assert(m);
			assert(ii && ii->impl);
			CC_LOG_DEBUG("with path='%s'\n", sd_bus_message_get_path(m));

			result = sd_bus_message_read(m, «m.inSignaturesAsDBus»«m.inArgumentsAsDBusThunk»);
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
			result = ii->impl->«m.name»(ii«m.inArgumentsAsDBusReply»«m.outArgumentsAsDBusImpl»);
			if (result < 0) {
				CC_LOG_ERROR("failed to execute method: %s\n", strerror(-result));
				sd_bus_error_setf(error, SD_BUS_ERROR_FAILED, "method implementation failed with error=%d", result);
				sd_bus_reply_method_error(m, error);
				return result;
			}
			«IF !m.fireAndForget»
			result = sd_bus_reply_method_return(m, «m.outSignaturesAsDBus»«m.outArgumentsAsDBusWrite»);
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
			SD_BUS_METHOD("«m.name»", «m.inSignaturesAsDBus», «m.outSignaturesAsDBus», &cc_«api.name»_«m.name»_thunk, «IF m.fireAndForget»SD_BUS_VTABLE_METHOD_NO_REPLY«ELSE»0«ENDIF»),
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


	def clientTypeSignature(FInterface it) '''
		struct cc_client_«it.name»'''


	def clientHeaderGuard(FInterface it) '''
		INCLUDED_CLIENT_«it.name.toUpperCase»'''


	def clientMethodPrefix(FInterface it) '''
		cc_client_«it.name»'''


	def serverTypeSignature(FInterface it) '''
		struct cc_server_«it.name»'''


	def serverImplTypeSignature(FInterface it) '''
		struct cc_server_«it.name»_impl'''


	def serverHeaderGuard(FInterface it) '''
		INCLUDED_SERVER_«it.name.toUpperCase»'''


	def serverMethodPrefix(FInterface it) '''
		cc_server_«it.name»'''


	def inArguments(FMethod it) '''
		«FOR a : inArgs», «a.type.typeSignatureIn»«a.name»«ENDFOR»'''


	def outArguments(FMethod it) '''
		«FOR a : outArgs», «a.type.typeSignatureOut»«a.name»«ENDFOR»'''


	def replyOutArguments(FMethod it) '''
		«FOR a : outArgs», «a.type.typeSignatureIn»«a.name»«ENDFOR»'''


	def typeSignatureIn(FTypeRef it) {
		typeSignature
	}


	def typeSignatureOut(FTypeRef it) {
		typeSignature + "*"
	}


	def typeSignature(FTypeRef it) {
		if (predefined != null) {
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
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def inArgumentsAsDBusWrite(FMethod it) '''
		«FOR a : inArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusWrite»«ENDFOR»'''


	def outArgumentsAsDBusWrite(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusWrite»«ENDFOR»'''


	def outArgumentsAsDBus(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.outArgumentAsDBus»«ENDFOR»'''


	def inArgumentsAsDBusThunk(FMethod it) '''
		«FOR a : inArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusThunk»«ENDFOR»'''


	def outArgumentsAsDBusThunk(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusThunk»«ENDFOR»'''


	def inArgumentsAsDBusReply(FMethod it) '''
		«FOR a : inArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusReply»«ENDFOR»'''


	def outArgumentsAsDBusReply(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.argumentAsDBusReply»«ENDFOR»'''


	def outArgumentsAsDBusImpl(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.outArgumentAsDBusImpl»«ENDFOR»'''


	def outArgumentsAsDBusLog(FMethod it) '''
		«FOR a : outArgs BEFORE ', ' SEPARATOR ', '»«a.outArgumentAsDBusLog»«ENDFOR»'''


	def outArgumentsAsDBusLogFormat(FMethod it) '''
		«IF outArgs.empty»void«ELSE»«FOR a : outArgs SEPARATOR ', '»«a.outArgumentAsDBusLogFormat»«ENDFOR»«ENDIF»'''


	def argumentAsDBusWrite(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "(int) " + name
				case FBasicTypeId::FLOAT:       "(double) " + name
				case FBasicTypeId::INT8:        "(uint8_t) " + name
				case FBasicTypeId::INT16:       name
				case FBasicTypeId::INT32:       name
				case FBasicTypeId::INT64:       name
				case FBasicTypeId::UINT8:       name
				case FBasicTypeId::UINT16:      name
				case FBasicTypeId::UINT32:      name
				case FBasicTypeId::UINT64:      name
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def outArgumentAsDBus(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "&" + name + "_int"
				case FBasicTypeId::FLOAT:       "&" + name + "_double"
				case FBasicTypeId::INT8:        "&" + name + "_uint8_t"
				case FBasicTypeId::INT16:       name
				case FBasicTypeId::INT32:       name
				case FBasicTypeId::INT64:       name
				case FBasicTypeId::UINT8:       name
				case FBasicTypeId::UINT16:      name
				case FBasicTypeId::UINT32:      name
				case FBasicTypeId::UINT64:      name
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def argumentAsDBusThunk(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "&" + name + "_int"
				case FBasicTypeId::FLOAT:       "&" + name + "_double"
				case FBasicTypeId::INT8:        "&" + name + "_uint8_t"
				case FBasicTypeId::INT16:       "&" + name
				case FBasicTypeId::INT32:       "&" + name
				case FBasicTypeId::INT64:       "&" + name
				case FBasicTypeId::UINT8:       "&" + name
				case FBasicTypeId::UINT16:      "&" + name
				case FBasicTypeId::UINT32:      "&" + name
				case FBasicTypeId::UINT64:      "&" + name
				case FBasicTypeId::DOUBLE:      "&" + name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def argumentAsDBusReply(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "!!" + name + "_int"
				case FBasicTypeId::FLOAT:       "(float) " + name + "_double"
				case FBasicTypeId::INT8:        "(int8_t) " + name + "_uint8_t"
				case FBasicTypeId::INT16:       name
				case FBasicTypeId::INT32:       name
				case FBasicTypeId::INT64:       name
				case FBasicTypeId::UINT8:       name
				case FBasicTypeId::UINT16:      name
				case FBasicTypeId::UINT32:      name
				case FBasicTypeId::UINT64:      name
				case FBasicTypeId::DOUBLE:      name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def outArgumentAsDBusImpl(FTypedElement it) '''
		&«name»'''


	def outArgumentAsDBusLog(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     "(int) *" + name
				case FBasicTypeId::FLOAT:       "*" + name
				case FBasicTypeId::INT8:        "*" + name
				case FBasicTypeId::INT16:       "*" + name
				case FBasicTypeId::INT32:       "*" + name
				case FBasicTypeId::INT64:       "*" + name
				case FBasicTypeId::UINT8:       "*" + name
				case FBasicTypeId::UINT16:      "*" + name
				case FBasicTypeId::UINT32:      "*" + name
				case FBasicTypeId::UINT64:      "*" + name
				case FBasicTypeId::DOUBLE:      "*" + name
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def outArgumentAsDBusLogFormat(FTypedElement it) {
		if (type.predefined != null) {
			switch (type.predefined) {
				case FBasicTypeId::BOOLEAN:     name + "=%d"
				case FBasicTypeId::FLOAT:       name + "=%g"
				case FBasicTypeId::INT8:        name + "=%d"
				case FBasicTypeId::INT16:       name + "=%d"
				case FBasicTypeId::INT32:       name + "=%d"
				case FBasicTypeId::INT64:       name + "=%d"
				case FBasicTypeId::UINT8:       name + "=%u"
				case FBasicTypeId::UINT16:      name + "=%u"
				case FBasicTypeId::UINT32:      name + "=%u"
				case FBasicTypeId::UINT64:      name + "=%u"
				case FBasicTypeId::DOUBLE:      name + "=%g"
				default: throw new IllegalArgumentException("Unsupported basic type " + type.predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}


	def inSignaturesAsDBus(FMethod it) '''
		"«FOR a : inArgs»«a.type.typeSignatureAsDBus»«ENDFOR»"'''


	def outSignaturesAsDBus(FMethod it) '''
		"«FOR a : outArgs»«a.type.typeSignatureAsDBus»«ENDFOR»"'''


	def typeSignatureAsDBus(FTypeRef it) {
		if (predefined != null) {
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
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}

}
