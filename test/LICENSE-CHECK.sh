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
# LICENSE-CHECK
# Script to check for licenses within repository

if [[ -f ./test/LICENSE-CHECK.sh ]]; then
    
    # Source external tools
    source ./config/BUILD.conf
    source ./script/echo_tools.sh
    #source ./script/file_operations.sh
    
    TAG='LICENSE-CHECK'

    list_header 'Starting LICENSE-CHECK'
    
    # VAR    
    IGNORE_STRING='.git|.md|artifacts|assets|cert|chroot|config|image|log|modules|-REPORT'
    MATCH_STRING='European Union Public License'
    FAIL_STRING='UNKNOWN'

    DETECTED="$(/usr/bin/licensecheck -r "${PWD}" -i "${IGNORE_STRING}" \
        | /usr/bin/grep "${MATCH_STRING}" | /usr/bin/cut -d ':' -f1)"
    
    # Leave out COPYING as it is unable to detect EUPL
    UNKNOWN="$(/usr/bin/licensecheck -r "${PWD}" -i "${IGNORE_STRING}" \
        | /usr/bin/grep "${FAIL_STRING}" | /usr/bin/grep -v 'COPYING' | /usr/bin/cut -d ':' -f1)"
        
    PASSNUM="$(/usr/bin/echo "${DETECTED}" | /usr/bin/wc -w)"
    FAILNUM="$(/usr/bin/echo "${UNKNOWN}" | /usr/bin/wc -w)"
    
    # DETECTED
    list_item "Files with \"${MATCH_STRING}\": ${PASSNUM}"
    if [[ "${PASSNUM}" -gt 0 ]]; then
        for detected in ${DETECTED}; do
            list_item_pass "${detected}"
        done
    fi
    
    # UNKNOWN
    list_line_item "Files with \"${FAIL_STRING}\" licenses: ${FAILNUM}"
    if [[ "${FAILNUM}" -gt 0 ]]; then
        for unknown in ${UNKNOWN}; do
            list_item_fail "${unknown}"
        done
        list_line_item 'Please supply all BCLD scripts of the appropriate EUPL license!'
        on_failure
    else
        list_item_pass 'No missing licenses found'
        on_completion
    fi
else

	echo -e "\nPlease run inside BCLD directory!"
	exit 1

fi
