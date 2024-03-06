#!/bin/bash
# Script to check for licenses within repository

if [[ -f ./test/LICENSE-CHECK.sh ]]; then
    
    # Source external tools
    source ./config/BUILD.conf
    source ./script/echo_tools.sh
    #source ./script/file_operations.sh
    
    TAG='LICENSE-CHECK'

    list_header 'Starting LICENSE-CHECK'
    
    # VAR    
    IGNORE_STRING='.git|.md|artifacts|assets|cert|config|image|log|modules|-REPORT'
    MATCH_STRING='European Union Public License'
    FAIL_STRING='UNKNOWN'

    DETECTED="$(/usr/bin/licensecheck -r "${PWD}" -i "${IGNORE_STRING}" \
        | /usr/bin/grep "${MATCH_STRING}" | /usr/bin/cut -d ':' -f1)"
    
    UNKNOWN="$(/usr/bin/licensecheck -r "${PWD}" -i "${IGNORE_STRING}" \
        | /usr/bin/grep "${FAIL_STRING}" | /usr/bin/cut -d ':' -f1)"
        
    PASSNUM="$(/usr/bin/echo "${DETECTED}" | /usr/bin/wc -w)"
    FAILNUM="$(/usr/bin/echo "${UNKNOWN}" | /usr/bin/wc -w)"
    
    # DETECTED
    list_item "Files with \"${MATCH_STRING}\": ${PASSNUM}"
    if [[ "${PASSNUM}" -gt 0 ]]; then
        for detected in ${DETECTED}; do
            list_item_pass "$(/usr/bin/basename "${detected}")"
        done
    fi
    
    # UNKNOWN
    list_line_item "Files with \"${FAIL_STRING}\" licenses: ${FAILNUM}"
    if [[ "${FAILNUM}" -gt 0 ]]; then
        for unknown in ${UNKNOWN}; do
            list_item_fail "$(/usr/bin/basename "${unknown}")"
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
