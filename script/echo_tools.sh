#!/bin/bash
#
# Copyright © 2024 Quintor B.V.
#
# BCLD is gelicentieerd onder de EUPL, versie 1.2 of
# – zodra ze zullen worden goedgekeurd door de Europese Commissie -
# latere versies van de EUPL (de "Licentie");
# U mag BCLD alleen gebruiken in overeenstemming met de licentie.
# U kunt een kopie van de licentie verkrijgen op:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Tenzij vereist door de toepasselijke wetgeving of overeengekomen in
# schrijven, wordt software onder deze licentie gedistribueerd
# gedistribueerd op een "AS IS"-basis,
# ZONDER ENIGE GARANTIES OF VOORWAARDEN, zowel
# expliciet als impliciet.
# Zie de licentie voor de specifieke taal die van toepassing is
# en de beperkingen van de licentie.
#
#
# Copyright © 2024 Quintor B.V.
#
# BCLD is licensed under the EUPL, Version 1.2 or 
# – as soon they will be approved by the European Commission -
# subsequent versions of the EUPL (the "Licence");
# You may not use BCLD except in compliance with the Licence.
# You may obtain a copy of the License at:
#
# https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
#
# Unless required by applicable law or agreed to in
# writing, software distributed under the License is
# distributed on an "AS IS" basis,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied.
# See the License for the specific language governing
# permissions and limitations under the License.
# 
#
# BCLD Echo Tools
# These functions are used throughout the entire BCLD build 
# process. They are also used within the BCLD client itself.
# The BCLD Echo Tools help to output console information in a 
# human-readable matter, during a build as well as run time.
#
# Function to echo last item of a list
function last_item () {
    /usr/bin/echo "    └────╼ ${1}"
    /usr/bin/echo
}

# Function to echo as list item
function list_item () {
    /usr/bin/echo "    ├────╼ ${1}"
}

# Function to printf as list item
function print_item () {
    /usr/bin/printf "    ├────╼ ${1}"
}

# Function to echo a checked item
function list_item_pass () {
    /usr/bin/echo "    ├─(+)╼ ${1}"
}

# Function to echo a failed item
function list_item_fail () {
    /usr/bin/echo "    ├─[-]╼ ${1}"
    /usr/bin/logger -t "BCLD-ERROR" "${1}"
}

# Function to improve log readability
function list_header () {
    /usr/bin/echo -e "\n    ┌──┤ [${BCLD_CODE_NAME} ${BCLD_PATCH}:${BCLD_MODEL:-${0}}] ${BCLD_VERSION_STRING}"

    # If the MACHINE_ID is known and accessible, use it in the header
    if [[ -n "${BCLD_HOST}" ]]; then
        /usr/bin/echo "    ├──┤ [${TAG}] ${BCLD_HOST}"
        /usr/bin/echo "    │"
        /usr/bin/echo "    ├──┤ ${1}"
        /usr/bin/echo "    │"
    else
        /usr/bin/echo "    ├──┤ [${TAG}] ${1}"
        /usr/bin/echo "    │"
    fi
}

# Function to enter output
function list_entry () {
    /usr/bin/echo "   ─┴─"
}

# Function to close section
function list_exit () {
    /usr/bin/echo "    ╽"
    /usr/bin/echo
}

# Function for white line
function list_line () {
    /usr/bin/echo "    │"
}

# Function which combines list_item with list_line
function list_line_item () {
    list_line
    list_item "${1}"
}

# Function to catch lists
function list_catch () {
    /usr/bin/echo "   ─┬─"
}

# Function to list header if verbose
function silent_header () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_header "${1}"
    fi
}

# Function to list item if verbose
function silent_item () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_item "${1}"
    fi
}

# Function to check a silent item
function silent_item_pass () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_item_pass "${1}"
    fi
}

# Function to fail a silent item
function silent_item_fail () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_item_fail "${1}"
    fi
}

# Function to list last item if verbose
function silent_last () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	last_item "${1}"
    fi
}

# Function to list entry if verbose
function silent_entry () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_entry
    fi
}

# Function to catch list if verbose
function silent_catch () {
    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    	list_catch
    fi
}

# Function to feature important parameter, if present
function header_param () {
	if [[ -n ${1} ]]; then
		list_header "${2}: ${1}"
	fi
}

# Function to list important parameter, if present
function list_param () {
	if [[ -n ${1} ]]; then
		/usr/bin/printf "%-50s %-50s\n" "    ├─(+)╼ ${2}:" "${1}"
	else
		/usr/bin/printf "%-50s %-50s\n" "    ├─(-)╼ ${2}" "NOT AVAILABLE"
	fi
}

#  Function to list last parameter in list, if present
function last_param () {
	if [[ -n ${1} ]]; then
		last_item "${2}: ${1}"
	else
		last_item "${2} is NOT set!"
	fi
}

# Function to display ascii logo
function ascii_logo () {
    /usr/bin/echo
    /usr/bin/echo '        ____   ______ __     ____'
    /usr/bin/echo '       / __ ) / ____// /    / __ \'
    /usr/bin/echo '      / __  |/ /    / /    / / / /'
    /usr/bin/echo '     / /_/ // /___ / /___ / /_/ /'
    /usr/bin/echo '    /_____/ \____//_____//_____/'
    /usr/bin/echo
    /usr/bin/echo
}

# Function to trigger successful feedback
function on_completion () {
    /usr/bin/echo '    │'
    /usr/bin/echo '    │'
    /usr/bin/echo "    ├─(+)─╢█ █ █ ║ ${TAG} COMPLETE!"
    /usr/bin/echo "    ├─────╢ █ █ █║ Environment: (${0})"
    /usr/bin/echo "    ├─────╢█ █ █ ║ Completed on: $(/usr/bin/date +'%Y-%m-%d %T')"
    /usr/bin/echo '    ╽'
    /usr/bin/echo
}

# Function to trigger successful feedback
function on_failure () {
    /usr/bin/echo '    │'
    /usr/bin/echo '    │'
    /usr/bin/echo "    ├─[-]─╢ ░ ░ ░║ ${TAG} FAILED!!!"
    /usr/bin/echo "    ├─────╢░ ░ ░ ║ Date: $(/usr/bin/date +'%Y-%m-%d %T')"
    /usr/bin/echo '    ╽'
    /usr/bin/echo
    exit 1
}

# Function to verify ENV or fail
function verify_ENV () {
	list_item "${1} is not allowed to be empty..."
    last_item "Enable ${1} in BUILD.conf, environment or Bamboo settings!"
    on_failure
}

# Function to check ENV or fail
function check_req_env () {

    if [[  -v "${1}" ]] && [[ -n "$(/usr/bin/printenv "${1}")" ]]; then
		list_item_pass "${1} is set."
	else
		list_item_fail "Please check ${1} before continuing!"
		on_failure
	fi
}

# Function to check optional ENVs
function check_opt_env () {

    if [[  -v "${1}" ]] && [[ -n "$(/usr/bin/printenv "${1}")" ]]; then
		list_item_pass "${1} is set."
	else
		list_item "${1} is not set, but optional, skipping..."
	fi
}
