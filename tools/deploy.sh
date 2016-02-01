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

# Script to populate the content of the update site with a new version
# of re-distributable standalone generators and binary plugins.

# Directory where this script is residing.
TOOLS_HOME_DIR="$(dirname $(readlink -f "$0"))"
# Directory where the generator product binaries are built.
GENERATOR_BUILD_DIR="${TOOLS_HOME_DIR}/org.genivi.capic.core.product/target/products/org.genivi.capic.core.product"
# Temporary directory used to re-package the generator artifacts.
PACKAGING_DIR="/tmp/capic-poc-gen"
# Directory where the update site repository is built.
UPDATESITE_BUILD_DIR="${TOOLS_HOME_DIR}/org.genivi.capic.core.updatesite/target/repository"

print_usage_exit() {
    echo "Usage: $0 [-f|--force] <version> <target-dir>"
    echo "Where <version> is in <major>.<minor>.<patch> format and"
    echo "<target-dir> is the destination for deployed artifacts."
    echo "Use --force to overwrite already existing deployment directories."
    exit 1
}

############################################################################
# Process options and arguments
############################################################################
if [ "$1" = "-f" -o "$1" = "--force" ]; then
    force_opt=yes
    version_arg="$2"
    deployhome_dir="$3"
else
    force_opt=no
    version_arg="$1"
    deployhome_dir="$2"
fi

if [ -z "$version_arg" -o -z "$deployhome_dir" ]; then
    echo "Missing argument(s)"
    print_usage_exit
fi

VERSION_REGEX='^\([0-9][0-9]*\)\.\([0-9][0-9]*\)\.\([0-9][0-9]*\)$'
if [ -z $(echo "$version_arg" | sed -n "/${VERSION_REGEX}/p") ]; then
    echo "Illegal version format: '${version_arg}'"
    print_usage_exit
fi
major=$(expr 0 + $(echo "$version_arg" | sed -e "s/${VERSION_REGEX}/\1/"))
minor=$(expr 0 + $(echo "$version_arg" | sed -e "s/${VERSION_REGEX}/\2/"))
patch=$(expr 0 + $(echo "$version_arg" | sed -e "s/${VERSION_REGEX}/\3/"))

if [ ! -d "$deployhome_dir" ]; then
    echo "Target directory '${deployhome_dir}' does not exist"
    print_usage_exit
fi
deployhome_dir="$(readlink -f "${deployhome_dir}")"

generator_dir="${deployhome_dir}/generator/${major}.${minor}/${major}.${minor}.${patch}"
updatesite_root_dir="${deployhome_dir}/updatesite"
updatesite_parent_dir="${updatesite_root_dir}/${major}.${minor}"
updatesite_dir="${updatesite_parent_dir}/${major}.${minor}.${patch}"

if [ \( -d "${generator_dir}" -o -d "${updatesite_dir}" \) -a $force_opt = "no" ]; then
    echo "Target directory(s) already exist--use --force to overwrite"
    exit
fi

echo "Deploying CAPIC binary artifacts to the update site repository..."

############################################################################
# Deploy generators
############################################################################

# $deployhome_dir/
# +-- generator/
#     +-- N.M/
#     |   +-- N.M.i/
#     |   |   +-- capic-core-gen.zip
#     |   +-- N.M.j/
#     |   ...
#     +-- P.Q/
#     |   +-- P.Q.x/
#     |   +-- P.Q.y/
#     |   ...
#     ...

rm -rf "${PACKAGING_DIR}"
mkdir -p "${PACKAGING_DIR}"

# Copy all overlapping directories to create their superset
cp -r "${GENERATOR_BUILD_DIR}/win32/win32/x86/configuration" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/win32/win32/x86/plugins" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/win32/win32/x86_64/configuration" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/win32/win32/x86_64/plugins" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86/configuration" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86/plugins" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86_64/configuration" "${PACKAGING_DIR}"
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86_64/plugins" "${PACKAGING_DIR}"

# Copy linux x86_64 versions of platform-independent artifacts
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86_64/features" "${PACKAGING_DIR}"

# Copy linux x86_64 versions of overlapping artifacts
cp -r "${GENERATOR_BUILD_DIR}/linux/gtk/x86_64/configuration" "${PACKAGING_DIR}"
cp "${GENERATOR_BUILD_DIR}/linux/gtk/x86_64/artifacts.xml" "${PACKAGING_DIR}"

# Copy and rename platform-specific artifacts
buildBaseLinux="${GENERATOR_BUILD_DIR}/linux/gtk/x86"
buildBaseWindows="${GENERATOR_BUILD_DIR}/win32/win32/x86"
packagingBase="${PACKAGING_DIR}/capic-core-gen"
cp "${buildBaseLinux}/capic-core-gen" "${packagingBase}-linux-x86"
cp "${buildBaseLinux}/capic-core-gen.ini" "${packagingBase}-linux-x86.ini"
cp "${buildBaseLinux}_64/capic-core-gen" "${packagingBase}-linux-x86_64"
cp "${buildBaseLinux}_64/capic-core-gen.ini" "${packagingBase}-linux-x86_64.ini"
cp "${buildBaseWindows}/eclipsec.exe" "${packagingBase}-windows-x86.exe"
cp "${buildBaseWindows}/capic-core-gen.ini" "${packagingBase}-windows-x86.ini"
cp "${buildBaseWindows}_64/eclipsec.exe" "${packagingBase}-windows-x86_64.exe"
cp "${buildBaseWindows}_64/capic-core-gen.ini" "${packagingBase}-windows-x86_64.ini"

# Create a zip archive with generator files
cd "${PACKAGING_DIR}" >/dev/null
mkdir -p "${generator_dir}"
rm -rf "${generator_dir}"/*
zip -FSr "${generator_dir}/capic-core-gen.zip" *
cd - >/dev/null

############################################################################
# Deploy updatesite
############################################################################

# $deployhome_dir/
#     updatesite_root_dir
#         updatesite_parent_dir
#             updatesite_dir
# +-- updatesite/
#     +-- compositeArtifacts.xml
#     +-- compositeContent.xml
#     +-- N.M/
#     |   +-- compositeArtifacts.xml
#     |   +-- compositeContent.xml
#     |   +-- N.M.i/
#     |   |   +-- artifacts.jar
#     |   |   +-- content.jar
#     |   |   +-- features/
#     |   |   +-- plugins/
#     |   +-- N.M.j/
#     |   ...
#     +-- P.Q/
#     |   +-- P.Q.x/
#     |   +-- P.Q.y/
#     |   ...
#     ...

# Create compositeArtifacts.xml and compositeContent.xml in $1
# and include $2 as the sole child.
create_composite_files() {
    cat >"$1/compositeArtifacts.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?compositeMetadataRepository version="1.0.0"?>
<repository name="GENIVI Common API C Update Site"
    type="org.eclipse.equinox.internal.p2.artifact.repository.CompositeArtifactRepository"
    version="1.0.0">
  <properties size="1">
    <property name="p2.timestamp" value="${timestamp}"/>
  </properties>
  <children size="1">
    <child location="$2"/>
  </children>
</repository>
EOF
    cat >"$1/compositeContent.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?compositeMetadataRepository version="1.0.0"?>
<repository name="GENIVI Common API C Update Site"
    type="org.eclipse.equinox.internal.p2.metadata.repository.CompositeMetadataRepository"
    version="1.0.0">
  <properties size="1">
    <property name="p2.timestamp" value="${timestamp}"/>
  </properties>
  <children size="1">
    <child location="$2"/>
  </children>
</repository>
EOF
}

# Create missing child directory $2 when needed and update
# compositeArtifacts.xml and compositeContent.xml in the parent
# directory $1 to reflect the changes.  Full path names are
# expected for both arguments.
update_metadata() {
    if [ ! -d "$2" ]; then
        echo "DEBUG: create $2"
        mkdir -p "$2"
        child_name="$(basename "$2")"
        if [ ! -f "$1/compositeArtifacts.xml" -o \
               ! -f "$1/compositeContent.xml" ]; then
            echo "DEBUG: create $1/compositeArtifacts+Content.xml"
            create_composite_files "$1" "${child_name}"
        else
            echo "DEBUG: update timestamp and child in $1/compositeArtifacts+Content.xml"
            child_count=$(expr 1 + $(grep -o '<children size="[0-9]*">' \
                    "$1/compositeArtifacts.xml" \
                | grep -o '[0-9]*'))
            sed -si \
                -e 's/\(name="p2.timestamp" value="\)[0-9]*"\/>/\1'"${timestamp}"'"\/>/' \
                -e 's/<children size="\([0-9]*\)">/<children size="'"${child_count}"'">/' \
                -e 's/\(^[ ]*<\/children>\)/    <child location="'"${child_name}"'"\/>\n\1/' \
                "$1/compositeArtifacts.xml" \
                "$1/compositeContent.xml"
        fi
    else
        echo "DEBUG: update timestamp in $1/compositeArtifacts+Content.xml"
        sed -si \
            -e 's/\(name="p2.timestamp" value="\)[0-9]*"\/>/\1'"${timestamp}"'"\/>/' \
            "$1/compositeArtifacts.xml" \
            "$1/compositeContent.xml"
    fi
}

timestamp=$(date +%s)000

update_metadata "${updatesite_root_dir}" "${updatesite_parent_dir}"
update_metadata "${updatesite_parent_dir}" "${updatesite_dir}"

rm -rf "${updatesite_dir}"/*
cp -r "${UPDATESITE_BUILD_DIR}"/* "${updatesite_dir}"
