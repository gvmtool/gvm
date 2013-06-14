#!/bin/bash

#
#   Copyright 2012 Marco Vermeulen
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

function gvm {
	#
	# Various sanity checks and default settings
	#
	__gvmtool_default_environment_variables

	mkdir -p "${GVM_DIR}"

	if [[ "$GVM_FORCE_OFFLINE" == "true" || ( "$1" == "offline" && "$2" == "enable" ) ]]; then
		BROADCAST_LIVE=""
	else
		BROADCAST_LIVE=$(curl -s "${GVM_SERVICE}/broadcast/${GVM_VERSION}")
	fi

	if [[ -z "${BROADCAST_LIVE}" && "${GVM_ONLINE}" == "true" && "$1" != "offline" ]]; then
		echo "${OFFLINE_BROADCAST}"
	fi

	if [[ -n "${BROADCAST_LIVE}" && "${GVM_ONLINE}" == "false" ]]; then
		echo "${ONLINE_BROADCAST}"
	fi

	if [[ -z "${BROADCAST_LIVE}" ]]; then
		GVM_ONLINE="false"
		GVM_AVAILABLE="false"
	else
		GVM_ONLINE="true"
	fi


	__gvmtool_check_upgrade_available
	if [[ "${UPGRADE_AVAILABLE}" == "true" && "$1" != "broadcast" && "$1" != "selfupdate" ]]; then
		echo "${BROADCAST_LIVE}"
		echo ""
	else
		__gvmtool_update_broadcast "$1"
	fi

	# Load the gvm config if it exists.
	if [ -f "${GVM_DIR}/etc/config" ]; then
		source "${GVM_DIR}/etc/config"
	fi

    command="$1"
    candidate="$2"
    shift; shift

 	# no command provided
	if [[ -z "$command" ]]; then
		__gvmtool_help
		return 1
	fi

    case "$command" in
        ls)
            command="list";;
        h)
            command="help";;
        v)
            command="version";;
        u)
            command="use";;
        remove)
            command="uninstall";;
        cur)
            command="current";;
        def)
            command="default";;
        groovy) # assumes the command use, if ommitted
            command="use"; candidate="groovy";;
        grails)
            command="use"; candidate="grails";;
        gradle)
            command="use"; candidate="gradle";;
        lazybones)
            command="use"; candidate="lazybones";;
        vertx)
            command="use"; candidate="vertx";;
    esac

	# Check if it is a valid command
	CMD_FOUND=""
	CMD_TARGET="${GVM_DIR}/src/gvm-$command.sh"
	if [[ -f "${CMD_TARGET}" ]]; then
		CMD_FOUND="${CMD_TARGET}"
	fi

	# Check if it is a sourced function
	CMD_TARGET="${GVM_DIR}/ext/gvm-$command.sh"
	if [[ -f "${CMD_TARGET}" ]]; then
		CMD_FOUND="${CMD_TARGET}"
	fi

	# couldn't find the command
	if [[ -z "${CMD_FOUND}" ]]; then
		echo "Invalid command: $command"
		__gvmtool_help
	fi

	# Check whether the candidate exists
	if [[ -n "$candidate" && "$command" != "offline" && -z $(echo ${GVM_CANDIDATES[@]} | grep -w "$candidate") ]]; then
		echo -e "\nStop! $candidate is not a valid candidate."
		return 1
	fi

	if [[ "$command" == "offline" &&  -z "$candidate" ]]; then
		echo -e "\nStop! Specify a valid offline mode."
	elif [[ "$command" == "offline" && ( -z $(echo "enable disable" | grep -w "$candidate")) ]]; then
		echo -e "\nStop! $candidate is not a valid offline mode."
	fi

	# Check whether the command exists as an internal function...
	#
	# NOTE Internal commands use underscores rather than hyphens,
	# hence the name conversion as the first step here.
	CONVERTED_CMD_NAME=$(echo "$command" | tr '-' '_')

	# Execute the requested command
	if [ -n "${CMD_FOUND}" ]; then
		# It's available as a shell function
		__gvmtool_"${CONVERTED_CMD_NAME}" "$candidate" $@
	fi
}
