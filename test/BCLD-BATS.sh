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
# BCLD BATS
# Bash Automated Testing System (BATS) for BCLD builds

# Set ENVs in Bamboo settings below!

#!/bin/bash
# Script to easily move all artifacts to ./opt
set -e
#set -x

# Source external tools
source ./config/BUILD.conf
source ./script/echo_tools.sh
source ./script/file_operations.sh

TAG='SHELL-CHECK'

list_header 'Starting BCLD ShellCheck'
if [[ -x /usr/bin/shellcheck ]] && [[ -x ./ISO-builder.sh ]]; then
    
    SHELL_REPORT='./artifacts/SHELL-REPORT.txt'
    
    SHELL_ERROR="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c 'error')"
    SHELL_WARN="$(/usr/bin/cat "${SHELL_REPORT}" | /usr/bin/grep -c 'warning')"
    
	# Make necessary directories
	prep_dir "$(/usr/bin/dirname ${SHELL_REPORT})"
    
    /usr/bin/find . -type f -name "*.sh" -exec shellcheck -S warning {} \; > "${SHELL_REPORT}"
    
    list_item "ShellCheck Errors: ${SHELL_ERROR}"
    list_item "ShellCheck Warnings: ${SHELL_WARN}"
    list_item "ShellCheck report: ${SHELL_REPORT}"
    
    if [[ ${SHELL_ERROR} -gt 0 ]]; then
        list_item_fail 'ShellCheck found errors!'
        on_failure
    else
        on_completion    
    fi
    
    
else
    last_item_fail 'ShellCheck could not be found!'
    on_failure
fi

TAG='BATS-TEST'

# Use in working directory
if [[ -f ./test/BCLD-BATS.sh ]]; then
	

	if [[ -n ${BCLD_MODEL} ]]; then
	

        BATS_1=./test/01_PER-BUILD.bats
        BATS_2=./test/02_POST-BUILD.bats
		BATS_BIN='./modules/bats-core/bin/bats'
		BATS_REPORT='./artifacts/BATS-REPORT.txt'
		BATS_SUCCESS='./artifacts/BATS-SUCCESS'
		
		list_header 'Starting BCLD Bash Automated Testing System'


		# Add title
		list_header "# $(/usr/bin/basename ./test/01_PER-BUILD.bats)" | /usr/bin/tee --append "${BATS_REPORT}"
		list_item 'This may take a while, a BCLD test build is running in the background...'
		list_entry
		("${BATS_BIN}" "${BATS_1}" | /usr/bin/tee --append "${BATS_REPORT}") || on_failure
		
		list_header "# $(/usr/bin/basename ./test/02_POST-BUILD.bats)" | /usr/bin/tee --append "${BATS_REPORT}"
		list_entry
		("${BATS_BIN}" "${BATS_1}" | /usr/bin/tee --append "${BATS_REPORT}") || on_failure
		
		list_header 'Checking BCLD-BATS-TEST results...'
		
		# Create fake artifact to trick Bamboo into failing if BATS fails
		if [[ $(/usr/bin/grep -c 'not ok' "${BATS_REPORT}") -gt 0 ]]; then
			list_item 'BCLD-BATS-TEST failed!'
			last_item "Please review the contents of ${BATS_REPORT}"
			exit 1
		else
			/usr/bin/touch "${BATS_SUCCESS}"
			list_item_pass "${0} completed successfully!"
			last_item "${BATS_SUCCESS} generated..."
			exit
		fi
		
	else
		list_item_fail 'Please set BCLD_MODEL'
		on_failure
	fi
	
else

	echo -e "\nPlease run inside BCLD directory!"
	exit 1

fi
