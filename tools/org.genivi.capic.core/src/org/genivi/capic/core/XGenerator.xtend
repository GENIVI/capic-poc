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
import org.franca.core.franca.FTypeRef

class XGenerator {

	def generateInterface(FInterface api) '''

		#ifndef INCLUDED_«api.name.toUpperCase»
		#define INCLUDED_«api.name.toUpperCase»

		#include <stdint.h>


		#ifdef __cplusplus
		extern "C" {
		#endif

		«FOR m : api.methods»
		int «api.name»_«m.name»(«m.generateInArgs»«IF !m.inArgs.empty && !m.outArgs.empty», «ENDIF»«m.generateOutArgs»);
		«ENDFOR»


		#ifdef __cplusplus
		}
		#endif

		#endif /* !INCLUDED_«api.name.toUpperCase» */
	'''


	def generateInArgs(FMethod it) '''
		«FOR a : inArgs SEPARATOR ', '»«a.type.generateTypeSignatureIn»«a.name»«ENDFOR»'''


	def generateOutArgs(FMethod it) '''
		«FOR a : outArgs SEPARATOR ', '»«a.type.generateTypeSignatureOut»«a.name»«ENDFOR»'''


	def generateTypeSignatureIn(FTypeRef it) {
		switch (predefined) {
			case FBasicTypeId::STRING,
			case FBasicTypeId::BYTE_BUFFER: "const " + generateTypeSignature
			default: generateTypeSignature
		}
	}


	def generateTypeSignatureOut(FTypeRef it) {
		generateTypeSignature + "*"
	}


	def generateTypeSignature(FTypeRef it) {
		if (predefined != null) {
			switch (predefined) {
				case FBasicTypeId::BOOLEAN:     "int "
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
				case FBasicTypeId::STRING:      "char *"
				case FBasicTypeId::BYTE_BUFFER: "char *"
				default: throw new IllegalArgumentException("Unsupported basic type " + predefined.toString)
			}
		} else {
			throw new UnsupportedOperationException("Derived and Integer types are not supported")
		}
	}

}
