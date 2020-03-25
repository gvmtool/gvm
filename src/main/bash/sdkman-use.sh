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

function __sdk_use {
	__sdkman_validate_non_blank_argument_counts "sdk ${COMMAND}" 2 0 'candidate' 'version' "${@}" || return 1

	local candidate version install

	candidate="${1}"
	__sdkman_validate_candidate "${candidate}" || return 1

	version="${2}"
	__sdkman_determine_version "${candidate}" "${version}" || return 1

	if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" ]]; then
		__sdkman_echo_red "\nStop! ${candidate} ${VERSION} is not installed."
		return 1
	fi

	# Just update the *_HOME and PATH for this shell.
	__sdkman_set_candidate_home "${candidate}" "${VERSION}"

	# Replace the current path for the candidate with the selected version.
	case "${platform}" in
	solaris) export PATH=$(echo "${PATH}" | gsed -r "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/([^/]+)!${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}!g") ;;
	darwin)  export PATH=$(echo "${PATH}" |  sed -E "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/([^/]+)!${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}!g") ;;
	*)       export PATH=$(echo "${PATH}" |  sed -r "s!${SDKMAN_CANDIDATES_DIR}/${candidate}/([^/]+)!${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}!g") ;;
	esac

	if [[ ! -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/current" ]]; then
		__sdkman_echo_green "Setting ${candidate} version ${VERSION} as default."
		__sdkman_link_candidate_version "${candidate}" "${VERSION}"
	fi

	__sdkman_echo_green "\nUsing ${candidate} version ${VERSION} in this shell."
}
