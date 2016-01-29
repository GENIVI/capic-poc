#!/bin/sh

# SPDX license identifier: MPL-2.0
# Copyright (C) 2016, Visteon Corp.
# Author: Pavel Konopelko, pkonopel@visteon.com
#
# This file is part of Common API C
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), version 2.0.
# If a copy of the MPL was not distributed with this file,
# you can obtain one at http://mozilla.org/MPL/2.0/.
# For further information see http://www.genivi.org/.

# Test script to verify that the source code generated from the
# reference Franca interfaces matches hand-written reference code.

# Directory where this test script is residing.
TESTHOME_DIR="$(dirname $(readlink -f $0))"
# Reference code directory.
REFERENCE_DIR="${TESTHOME_DIR}/../ref"
# Directories to store intermediate artifacts:
TEMPORARY_DIR="/tmp/capic-poc-test"
# - code generated from reference .fidl files
GENERATED_DIR="${TEMPORARY_DIR}/src-gen"
# - code files with normalized formatting
FORMATTED_DIR="${TEMPORARY_DIR}/compare"
# The number of lines occupied by the header at the file beginning.
# These lines are excluded from the comparison.
REFERENCE_HEADER=14
GENERATED_HEADER=3
# Path to the code generator binary.
GENERATOR="${TESTHOME_DIR}/../tools/org.genivi.capic.core.product/target/products/org.genivi.capic.core.product/linux/gtk/x86_64/capic-core-gen"

normalize_format() {
    clang-format -style=LLVM "${REFERENCE_DIR}/$1" \
        | tail -n +${REFERENCE_HEADER} - >"${FORMATTED_DIR}/ref/$(basename $1)"
    clang-format -style=LLVM "${GENERATED_DIR}/$(basename $1)" \
        | tail -n +${GENERATED_HEADER} - >"${FORMATTED_DIR}/gen/$(basename $1)"
}

echo "Comparing generated CAPIC code against reference code..."

rm -rf "${TEMPORARY_DIR}"
mkdir -p "${TEMPORARY_DIR}"

# Adjust working directory since CAPIC generator will create files there.
cd "${TEMPORARY_DIR}"
"${GENERATOR}" \
    "${REFERENCE_DIR}/simple/Calculator.fidl" \
    "${REFERENCE_DIR}/game/Ball.fidl" \
    "${REFERENCE_DIR}/smartie/Smartie.fidl" \
    >/dev/null
cd - >/dev/null

mkdir -p "${FORMATTED_DIR}/ref"
mkdir -p "${FORMATTED_DIR}/gen"

normalize_format "simple/src-gen/client-Calculator.h"
normalize_format "simple/src-gen/client-Calculator.c"
normalize_format "simple/src-gen/server-Calculator.h"
normalize_format "simple/src-gen/server-Calculator.c"
normalize_format "game/src-gen/client-Ball.h"
normalize_format "game/src-gen/client-Ball.c"
normalize_format "game/src-gen/server-Ball.h"
normalize_format "game/src-gen/server-Ball.c"
normalize_format "smartie/src-gen/client-Smartie.h"
normalize_format "smartie/src-gen/client-Smartie.c"
normalize_format "smartie/src-gen/server-Smartie.h"
normalize_format "smartie/src-gen/server-Smartie.c"

diff -w "${FORMATTED_DIR}/ref" "${FORMATTED_DIR}/gen"

if [ $? = "0" ]; then
    echo "PASS"
    exit 0
else
    echo "FAIL"
    exit 1
fi
