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

TAG='BATS-TEST'

# Use in working directory
if [[ -f ./test/BCLD-BATS.sh ]]; then
	

	if [[ -n ${BCLD_MODEL} ]]; then

		BATS_BIN='./modules/bats-core/bin/bats'
        BATS_TEST=./test/00_BCLD-BUILD.bats
		BATS_REPORT='./test/BATS-REPORT.txt'
		BATS_SUCCESS='./test/BATS-SUCCESS'
		


		# BATS TEST
        /usr/bin/touch "${BATS_REPORT}"
        /usr/bin/mkdir -p ./artifacts
		list_header 'Starting BCLD Bash Automated Testing System' | /usr/bin/tee "${BATS_REPORT}"
		list_item "# $(/usr/bin/basename "${BATS_TEST}")" | /usr/bin/tee --append "${BATS_REPORT}"
		list_entry | /usr/bin/tee --append "${BATS_REPORT}"

		# Broken in GitHub Workflow
		("${BATS_BIN}" "${BATS_TEST}" | /usr/bin/tee --append "${BATS_REPORT}") || on_failure
		
		list_header 'Checking BCLD-BATS-TEST results...'
		
		# Create fake artifact to trick CI/CD into failing if BATS fails
		if [[ -f "${BATS_REPORT}" ]]; then
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
		fi
		
	else
		list_item_fail 'Please set BCLD_MODEL'
		on_failure
	fi
	
else

	echo -e "\nPlease run inside BCLD directory!"
	exit 1

fi
