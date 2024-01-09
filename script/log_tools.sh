#!/bin/bash
#
# Copyright © 2023 Quintor B.V.
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
# Copyright © 2023 Quintor B.V.
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
# BCLD Log Tools
# Similar to BCLD Echo Tools, but instead of console output, the BCLD Log
# Tools can be used for loading output into the journal so it can be
# exported into bcld.log or through Rsyslog.
#
# ENVs
TAG="RUN-CLIENT"

## Levels
EMERGENCY=0
ALERT=1
CRITICAL=2
ERROR=3
WARNING=4
NOTICE=5
INFO=6
DEBUG=7

# Functions
## Function to output line if found
function output_line () {
    if [[ -f ${1} ]]; then
        cat "${1}"
    else
        echo "${1} not found!"
    fi
}

## Function to output empty line to journal
function log_whitespace () {
    echo | /usr/bin/logger -t "${TAG}"
}

## Function to improve log readability
function log_header () {
    /usr/bin/logger -t "${TAG}" "──────────────────────────────┤ ${1} ├──────────────────────────────"
}

## Function to add 1 line to journal
function log_line () {
    /usr/bin/logger -t "${TAG}" "${1}"
}

## Function to add first item to journal
function log_first () {
    /usr/bin/logger -t "${TAG}" "╭── ${1}"
}

## Function to add 1 item to journal
function log_item () {
    /usr/bin/logger -t "${TAG}" "├── ${1}"
}

## Function to add last item to journal
function log_last () {
    /usr/bin/logger -t "${TAG}" "╰── ${1}"
}

## Function to output error line
function file_missing () {
    /usr/bin/logger -t "${TAG}" -p ${ERROR} "${1} does not exist!"
}

## Function to output file once if found
function output_file () {
    if [[ -f ${1} ]]; then
        log_whitespace
        /usr/bin/logger -t "${TAG}" "──  ${1}"
        /usr/bin/cat "${1}" | /usr/bin/logger -t "${TAG}"
        log_whitespace
    else
        file_missing "${1}"
    fi
}

## Function to sudo output file once if found
function sudo_output_file () {
    if [[ -f ${1} ]]; then
        log_whitespace
        /usr/bin/logger -t "${TAG}" "──  ${1}"
        /usr/bin/sudo /usr/bin/cat "${1}" | /usr/bin/logger -t "${TAG}"
        log_whitespace
    else
        file_missing "${1}"
    fi
}

## Function to follow output of log file if found
function follow_file () {
    if [[ -f ${1} ]]; then
        log_whitespace
        /usr/bin/logger -t "${TAG}" "──  ${1}"
        /usr/bin/tail -f "${1}" | /usr/bin/logger -t "${TAG}" &
        log_whitespace
    else
        log_whitespace
        file_missing "${1}"
        log_whitespace
    fi
}
