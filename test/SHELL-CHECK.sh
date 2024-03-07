#!/bin/bash
#
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
# SHELL-CHECK
# Script for ShellCheck automation

# Function to add to SHELL_REPORT
function append_report () {
    /usr/bin/echo -e "${1}" | /usr/bin/tee -a "${SHELL_REPORT}"
}

# Function to output description if too long
# 1: warn, error id
# 2: description
function output_desc () {

    if [[ $(/usr/bin/echo "${2}" | /usr/bin/wc -l) -eq 1 ]]; then
        append_report " - ${1}: ${2}"
    else
        append_report " - ${1}:"
        append_report_silent '\n```'
        append_report "${2}"
        append_report_silent '```\n'
    fi
}

function append_report_silent () {
    /usr/bin/echo -e "${1}" >> "${SHELL_REPORT}"
}

if [[ -x /usr/bin/shellcheck ]] && [[ -f ./test/00_BCLD-BUILD.bats ]]; then
    SHELL_REPORT='./test/SHELL-REPORT.md'
    
    /usr/bin/echo -e '\n# Starting BCLD ShellCheck' | /usr/bin/tee "${SHELL_REPORT}"
    
    append_report_silent '\n```'
    
    # Make necessary directories
    /usr/bin/mkdir -p "$(/usr/bin/dirname ${SHELL_REPORT})"
    
    /usr/bin/find . -type f \
        -name "*.sh" \
        -not \( -path './chroot/*' -o -path './modules/*' \) \
        -exec shellcheck -S warning {} \; >> "${SHELL_REPORT}"
        
    append_report_silent '```\n'

    # Warnings
    SHELL_WARN="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(warning)')"

    append_report "\n# ShellCheck Warnings: ${SHELL_WARN}"

    ## If ShellCheck finds warnings...    
    if [[ ${SHELL_WARN} -gt 0 ]]; then
        append_report '\n## Common warnings found:\n'
        
        COMMON_WARNINGS="$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(warning)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u | /usr/bin/awk '{$1=$1};1')"
        
        for warn in ${COMMON_WARNINGS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${warn}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/sort -u)"
            
            output_desc "${warn}" "${description}"
        done 
    fi
    
    # ERRORS
    SHELL_ERROR="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c '(error)')"
    
    append_report "\n# ShellCheck ERRORS: ${SHELL_ERROR}"
    
    ## If ShellCheck finds errors...    
    if [[ ${SHELL_ERROR} -gt 0 ]]; then
        append_report '\n## Common ERRORS found!:\n'
        
        COMMON_ERRORS=$(/usr/bin/cat ${SHELL_REPORT} | /usr/bin/grep '(error)' | /usr/bin/awk '{ print $2 }' | /usr/bin/sort -u)
        
        for error in ${COMMON_ERRORS}; do
            
            description="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep "${error}" | /usr/bin/grep -v 'https' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
            
            output_desc "${error}" "${description}"
        done

        exit 1    
    fi

    append_report "# ShellCheck report: ${SHELL_REPORT}"

else
    /usr/bin/echo 'ShellCheck could not be found!'
    exit 1
fi
