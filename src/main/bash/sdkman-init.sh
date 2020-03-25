#!/usr/bin/env bash

#
#   Copyright 2017 Marco Vermeulen
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

# set env vars if not set
if [ -z "${SDKMAN_VERSION}" ]; then
	export SDKMAN_VERSION='@SDKMAN_VERSION@'
fi

if [ -z "${SDKMAN_CANDIDATES_API}" ]; then
	export SDKMAN_CANDIDATES_API='@SDKMAN_CANDIDATES_API@'
fi

if [ -z "${SDKMAN_DIR}" ]; then
	export SDKMAN_DIR="${HOME}/.sdkman"
fi

# infer platform
SDKMAN_PLATFORM="$(uname)"
if [[ "${SDKMAN_PLATFORM}" == 'Linux' ]]; then
	if [[ "$(uname -m)" == 'i686' ]]; then
		SDKMAN_PLATFORM+='32'
	else
		SDKMAN_PLATFORM+='64'
	fi
fi
export SDKMAN_PLATFORM

case "${SDKMAN_PLATFORM}" in
CYGWIN*)
	platform='cygwin'
	;;
Darwin*)
	platform='darwin'
	;;
SunOS*)
	platform='solaris'
	;;
FreeBSD*)
	platform='freebsd'
	;;
*)
	platform="${SDKMAN_PLATFORM}"
	;;
esac

# Determine shell
shell_name="$(ps -o comm= -p $$)"
shell_name="${shell_name##*[[:cntrl:][:punct:][:space:]]}"

# Source sdkman module scripts and extension files.
#
# Extension files are prefixed with 'sdkman-' and found in the ext/ folder.
# Use this if extensions are written with the functional approach and want
# to use functions in the main sdkman script. For more details, refer to
# <https://github.com/sdkman/sdkman-extensions>.
OLD_IFS="${IFS}"
IFS=$'\n'
scripts=($(find "${SDKMAN_DIR}/src" "${SDKMAN_DIR}/ext" -type f -name 'sdkman-*'))
for f in "${scripts[@]}"; do
	source "${f}"
done
IFS="${OLD_IFS}"
unset OLD_IFS scripts f

# Load the sdkman config if it exists.
if [ -f "${SDKMAN_DIR}/etc/config" ]; then
	source "${SDKMAN_DIR}/etc/config"
fi

# Create upgrade delay file if it doesn't exist
if [[ ! -f "${SDKMAN_DIR}/var/delay_upgrade" ]]; then
	touch "${SDKMAN_DIR}/var/delay_upgrade"
fi

# set curl connect-timeout and max-time
if [[ -z "${sdkman_curl_connect_timeout}" ]]; then sdkman_curl_connect_timeout=7; fi
if [[ -z "${sdkman_curl_max_time}" ]]; then sdkman_curl_max_time=10; fi

# set curl retry
if [[ -z "${sdkman_curl_retry}" ]]; then sdkman_curl_retry=0; fi

# set curl retry max time in seconds
if [[ -z "${sdkman_curl_retry_max_time}" ]]; then sdkman_curl_retry_max_time=60; fi

# set curl to continue downloading automatically
if [[ -z "${sdkman_curl_continue}" ]]; then sdkman_curl_continue='true'; fi

# Read list of candidates and set array
SDKMAN_CANDIDATES_CACHE="${SDKMAN_DIR}/var/candidates"
SDKMAN_CANDIDATES_CSV=$(< "${SDKMAN_CANDIDATES_CACHE}")
__sdkman_echo_debug "Setting candidates csv: ${SDKMAN_CANDIDATES_CSV}"
if [[ "${shell_name}" == 'zsh' ]]; then
	READ_ARRAY_OPT='-A'
else
	READ_ARRAY_OPT='-a'
fi
IFS=',' read "${READ_ARRAY_OPT}" SDKMAN_CANDIDATES <<< "${SDKMAN_CANDIDATES_CSV}"

export SDKMAN_CANDIDATES_DIR="${SDKMAN_DIR}/candidates"

for candidate_name in "${SDKMAN_CANDIDATES[@]}"; do
	candidate_dir="${SDKMAN_CANDIDATES_DIR}/${candidate_name}/current"
	if [[ -d "${candidate_dir}" ]]; then
		__sdkman_export_candidate_home "${candidate_name}" "${candidate_dir}"
		__sdkman_prepend_candidate_to_path "${candidate_name}"
	fi
done
unset candidate_name candidate_dir
export PATH
