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

##############################################################################
# Use CAPIC++
#
# Defines the following macros for use with CAPIC++:
#
# * CAPICXX_ADD_INTERFACE(name generator [SKELETON])
#   - For Franca interface with given name, define the client and server file
#     lists produced by the specified generator and the make rule to build
#     these files.  Supported generators include CORE and DBUS.
#     For the CORE generator, optionally include generated skeleton files.
#
# Each use of CAPICXX_ADD_INTERFACE creates the following variables that
# can be used to add targets:
#
# * CAPICXX_${name}_${generator}_CLIENT_FILES - list of client-side files
# * CAPICXX_${name}_${generator}_SERVER_FILES - list of server-side files
# * CAPICXX_${name}_${generator}_ALL_FILES - list of all files
#
# This module makes the following simplifying assumptions:
#
# * all fidl/fdepl files for the build are located in one directory;
#   ${CMAKE_CURRENT_SOURCE_DIR}/fidl is used as the default value
#
# * all generated files for the build are located in one directory;
#   ${CMAKE_CURRENT_BINARY_DIR}/src-gen is used as the default value
#
# * fidl files are named after and include the definition of exactly one
#   interface/type collection
#   - searching the fidl/ directory for patterns with the element name will
#     find all generated files related to the element
#
# * interface/type collection names are unique within the fidl/ directory
#   - generated variable names and make rules differ only by ${name}
#
# * code generator executables can be invoked using the names
#   "capic++-{core|dbus}-gen" and their locations are included in PATH
#
# In order to create the list of generated files, the first use of the
# CAPICXX_ADD_INTERFACE invokes the corresponding generator to populate
# CAPICXX_SRCGEN_DIR and uses the latter to compile the file lists for
# individual interfaces.  The generated files are re-used during subsequent
# make invocations.  Any changes in the fidl/fdepl files should be detected by
# make, however, any changes that affect the list of generated files will
# require to wipe the build directory and re-run cmake.
#
# For developer builds, the variables CAPICXX_FIDL_DIR and CAPICXX_SRCGEN_DIR
# can be defined to use project-specific directories for fidl/fdepl and
# generated files.  Additionally, the variables CAPICXX_{CORE|DBUS}_GEN_CMD
# can be defined to support non-standard locations of generator binaries.
##############################################################################


if (NOT CAPICXX_FIDL_DIR)
    set(CAPICXX_FIDL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/fidl)
endif()
if (NOT CAPICXX_SRCGEN_DIR)
    set(CAPICXX_SRCGEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/src-gen)
endif()
message(STATUS "CAPICXX_FIDL_DIR     = \"${CAPICXX_FIDL_DIR}\"")
message(STATUS "CAPICXX_SRCGEN_DIR   = \"${CAPICXX_SRCGEN_DIR}\"")

if (NOT CAPICXX_CORE_GEN_CMD)
    set(CAPICXX_CORE_GEN_CMD capic++-core-gen)
endif()
if (NOT CAPICXX_DBUS_GEN_CMD)
    set(CAPICXX_DBUS_GEN_CMD capic++-dbus-gen)
endif()
message(STATUS "CAPICXX_CORE_GEN_CMD = \"${CAPICXX_CORE_GEN_CMD}\"")
message(STATUS "CAPICXX_DBUS_GEN_CMD = \"${CAPICXX_DBUS_GEN_CMD}\"")


# Specify options to use by particular generators.
# Currently, only the CORE generator must be told to generate skeletons,
# so leave options for other generators unset.
#
set(CAPICXX_CORE_GEN_OPTIONS "-sk")


# CAPICXX_get_files_by_pattern(result generator [pattern1 pattern2 ...])
# Verify if the directory ${CAPICXX_SRCGEN_DIR} exists and is already populated.
# Otherwise run the code generator of the specified backend {CORE|DBUS}
# for all files found in ${CAPICXX_FIDL_DIR}.  Set result to the list of files
# in ${CAPICXX_SRCGEN_DIR} that match the patterns.
#
function(CAPICXX_get_files_by_pattern result generator)
    file(
        GLOB _all_fidl_files
        LIST_DIRECTORIES false
        ${CAPICXX_FIDL_DIR}/*.fidl
        ${CAPICXX_FIDL_DIR}/*.fdepl
    )
    if (NOT (generator STREQUAL CORE OR generator STREQUAL DBUS))
        message(SEND_ERROR
            "Function CAPICXX_get_files() failed due to missing or
            unsupported generator \"${generator}"
        )
    elseif (NOT EXISTS ${CAPICXX_FIDL_DIR})
        message(SEND_ERROR "Cannot find fidl directory \"${CAPICXX_FIDL_DIR}\"")
    elseif (NOT _all_fidl_files)
        message(SEND_ERROR "Cannot find any fidl/fdepl files in \"${CAPICXX_FIDL_DIR}\"")
    else()
        if (NOT EXISTS ${CAPICXX_SRCGEN_DIR})
            message(STATUS "Creating src-gen directory \"${CAPICXX_SRCGEN_DIR}\"")
            file(MAKE_DIRECTORY ${CAPICXX_SRCGEN_DIR})
            # This is needed since the directory will be populated unrelated
            # to any target dependencies
            set_directory_properties(PROPERTIES
                ADDITIONAL_MAKE_CLEAN_FILES
                "${CAPICXX_SRCGEN_DIR}"
            )
        endif()
        if (${generator} STREQUAL CORE)
            set(_generator_command "${CAPICXX_CORE_GEN_CMD}")
            set(_generator_options ${CAPICXX_CORE_GEN_OPTIONS})
            set(_generator_marker ".core")
        elseif (${generator} STREQUAL DBUS)
            set(_generator_command "${CAPICXX_DBUS_GEN_CMD}")
            set(_generator_options ${CAPICXX_DBUS_GEN_OPTIONS})
            set(_generator_marker ".dbus")
        endif()
        if (NOT EXISTS ${CAPICXX_SRCGEN_DIR}/${_generator_marker})
            message(STATUS
                "Generating ${generator} files in \"${CAPICXX_SRCGEN_DIR}\"")
            execute_process(
                COMMAND ${_generator_command}
                ${_generator_options} -d ${CAPICXX_SRCGEN_DIR} ${_all_fidl_files}
                OUTPUT_VARIABLE _generator_output
                ERROR_VARIABLE _generator_output
                RESULT_VARIABLE _generator_result
            )
            if (_generator_result)
                message(SEND_ERROR
                    "Command \"${_generator_command}\" failed with result\n
                    ${_generator_result}\nand output:\n${_generator_output}"
                )
            else()
                file(WRITE ${CAPICXX_SRCGEN_DIR}/${_generator_marker} "")
            endif()
        endif()
        foreach (_pattern ${ARGN})
            list(APPEND _patterns_with_path "${CAPICXX_SRCGEN_DIR}/${_pattern}")
        endforeach()
        file(GLOB_RECURSE _result ${_patterns_with_path})
        set(${result} ${_result} PARENT_SCOPE)
    endif()
endfunction()


# CAPICXX_GET_CORE_CLIENT_PATTERNS(result name)
# For the interface with given name, set result to the patterns of file names
# that are produced by CORE generator for use by clients.
#
macro(CAPICXX_GET_CORE_CLIENT_PATTERNS result name)
    set(${result}
        "${name}.*"
        "${name}Proxy*.*"
    )
endmacro()


# CAPICXX_GET_CORE_SERVER_PATTERNS(result name [SEKELETON])
# For the interface with given name, set result to the patterns of file names
# that are produced by CORE generator for use by servers.  Optionally, include
# the skeleton files.
#
macro(CAPICXX_GET_CORE_SERVER_PATTERNS result name)
    set(${result}
        "${name}.*"
        "${name}Stub.*"
    )
    if ("x${ARGN}" STREQUAL "xSKELETON")
        set(${result}
            ${${result}}
            "${name}StubDefault.*"
        )
    endif()
endmacro()


# CAPICXX_GET_DBUS_CLIENT_PATTERNS(result name)
# For the interface with given name, set result to the patterns of file names
# that are produced by DBUS generator for use by clients.
#
macro(CAPICXX_GET_DBUS_CLIENT_PATTERNS result name)
    set(${result}
        "${name}DBusProxy.*"
        "${name}DBusDeployment.*"
    )
endmacro()


# CAPICXX_GET_DBUS_SERVER_PATTERNS(result name)
# For the interface with given name, set result to the patterns of file names
# that are produced by DBUS generator for use by servers.
#
macro(CAPICXX_GET_DBUS_SERVER_PATTERNS result name)
    set(${result}
        "${name}DBusStubAdapter.*"
        "${name}DBusDeployment.*"
    )
endmacro()


# CAPICXX_get_files(result name generator role [SKELETON])
# For the interface with given name, set result to the list of files that are
# produced by the specified generator (CORE or DBUS) for a particular role
# (CLIENT or SERVER).  Optionally, include skeleton files for CORE CLIENTS.
#
function(CAPICXX_get_files result name generator role)
    if (NOT (generator STREQUAL CORE OR generator STREQUAL DBUS))
        message(SEND_ERROR
            "Function CAPICXX_get_files_ex() failed due to unsupported value
            of generator argument \"${generator}\""
        )
    elseif (NOT (role STREQUAL CLIENT OR role STREQUAL SERVER))
        message(SEND_ERROR
            "Function CAPICXX_get_files_ex() failed due to unsupported value
            of role argument \"${role}\""
        )
    else()
        if (generator STREQUAL CORE AND role STREQUAL CLIENT)
            CAPICXX_GET_CORE_CLIENT_PATTERNS(_patterns ${name} ${ARGN})
        elseif (generator STREQUAL CORE AND role STREQUAL SERVER)
            CAPICXX_GET_CORE_SERVER_PATTERNS(_patterns ${name} ${ARGN})
        elseif (generator STREQUAL DBUS AND role STREQUAL CLIENT)
            CAPICXX_GET_DBUS_CLIENT_PATTERNS(_patterns ${name} ${ARGN})
        elseif (generator STREQUAL DBUS AND role STREQUAL SERVER)
            CAPICXX_GET_DBUS_SERVER_PATTERNS(_patterns ${name} ${ARGN})
        endif()
        CAPICXX_get_files_by_pattern(_result ${generator} ${_patterns})
        set(${result} ${_result} PARENT_SCOPE)
    endif()
endfunction()


# CAPICXX_ADD_INTERFACE(name generator [SKELETON])
# For Franca interface with given name, define the client and server file
# lists produced by the specified generator and the make rule to build these
# files.  Supported generators include CORE and DBUS.
# For the CORE generator, optionally include generated skeleton files.
#
macro(CAPICXX_ADD_INTERFACE name generator)
    CAPICXX_get_files(
        CAPICXX_${name}_${generator}_CLIENT_FILES
        ${name} ${generator} CLIENT ${ARGN}
    )
    CAPICXX_get_files(
        CAPICXX_${name}_${generator}_SERVER_FILES
        ${name} ${generator} SERVER ${ARGN}
    )
    set(CAPICXX_${name}_${generator}_ALL_FILES
        ${CAPICXX_${name}_${generator}_CLIENT_FILES}
        ${CAPICXX_${name}_${generator}_SERVER_FILES}
    )
    # Generator will produce a rule for each entry, so remove duplicates
    list(REMOVE_DUPLICATES CAPICXX_${name}_${generator}_ALL_FILES)
    add_custom_command(
        OUTPUT ${CAPICXX_${name}_${generator}_ALL_FILES}
        COMMAND ${CAPICXX_${generator}_GEN_CMD}
            -d ${CAPICXX_SRCGEN_DIR}
            ${CAPICXX_${generator}_GEN_OPTIONS}
            ${CAPICXX_FIDL_DIR}/${name}.fidl
        DEPENDS ${CAPICXX_FIDL_DIR}/${name}.fidl
    )
    message(STATUS
        "CAPICXX_${name}_${generator}_CLIENT_FILES =
        \"${CAPICXX_${name}_${generator}_CLIENT_FILES}\"")
    message(STATUS
        "CAPICXX_${name}_${generator}_SERVER_FILES =
        \"${CAPICXX_${name}_${generator}_SERVER_FILES}\"")
    message(STATUS
        "CAPICXX_${name}_${generator}_ALL_FILES    =
        \"${CAPICXX_${name}_${generator}_ALL_FILES}\"")
endmacro()
