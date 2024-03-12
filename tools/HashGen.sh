#!/bin/bash
#
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
# BCLD HashGen
# Script for generating hashes of all important files in 
# the BCLD repository.

if [[ -f "$(pwd)/tools/HashGen.sh" ]]; then
	source './script/echo_tools.sh'
	source './config/BUILD.conf'
	
	TAG="TOOL-HASHGEN"

	list_header "Initializing BCLD Hash Generator"
else
    /usr/bin/echo -e "\nPlease run ${0} inside BCLD project directory!"
    exit 1
fi

# Functions
## Function to add a single hash to main hash file
function add_file_hash () {
	if [[ -f "${1}" ]]; then
		list_item "Adding FILE: ${1}"
		/usr/bin/md5sum "${1}"  >> "${BCLD_MD5}"
	else
		/usr/bin/echo "FILE ${1} does not exist!"
		exit 1
	fi
}

## Function to add hashes to main hash file
function add_dir_hash () {
	if [[ -d "${1}" ]]; then
		list_item "Adding DIR: ${1}"
		/usr/bin/find "${1}" \
		    -maxdepth 1 \
		    -type f \
		    -exec /usr/bin/md5sum {} >> ${BCLD_MD5} \;
	else
		/usr/bin/echo "DIR ${1} does not exist!"
		exit 1
	fi
}

## Function to add all hashes within a directory to the main hash file
function add_rec_hash () {
	if [[ -d "${1}" ]]; then
		list_item "Adding DIRs: ${1}"
		/usr/bin/find "${1}" \
		    -type f \
		    -exec /usr/bin/md5sum {} >> ${BCLD_MD5} \;
	else
		/usr/bin/echo "DIR ${1} does not exist!"
	fi
}

## Function to populate hash file
function generate_bcld_md5 () {

	# Delete any old artifacts
	if [[ -f "${BCLD_MD5}" ]]; then
		list_item "Removing old ${BCLD_MD5}..."
		rm -f "${BCLD_MD5}"
	fi
	
	list_item "Generating new ${BCLD_MD5}..."

    add_rec_hash ./.github
    add_rec_hash ./assets
    add_rec_hash ./config
    add_rec_hash ./tools
    add_dir_hash ./script
    add_dir_hash ./tools/bcld-repo-manager
    add_dir_hash .
    add_file_hash ./image/ISO/isolinux/isolinux.bin
    add_file_hash ./image/ISO/isolinux/isolinux.cfg
    add_file_hash ./image/ISO/README.diskdefines
    add_file_hash ./test/00_BCLD-BUILD.bats
    add_file_hash ./test/BCLD-BATS.sh
    add_file_hash ./test/bcld_test.sh
    add_file_hash ./test/common-setup
    add_file_hash ./test/SHELL-CHECK.sh
    
    /usr/bin/cat "${BCLD_MD5}" | /usr/bin/sort -u -k 2 > "${BCLD_MD5}".1
    /usr/bin/mv "${BCLD_MD5}".1 "${BCLD_MD5}"

}

## Function to hash the hash file
function top_bcld_md5 () {

	TOP_MD5='./test/md5sum'

	# Delete any old artifacts
	if [[ -f "${TOP_MD5}" ]]; then
		list_item "Removing old ${TOP_MD5}..."
		rm -f "${TOP_MD5}"
	fi
	
	list_item "Generating new ${TOP_MD5}..."
	/usr/bin/md5sum "${BCLD_MD5}"  > "${TOP_MD5}"
    
	list_item "Finished, check ${TOP_MD5}..."
}

## Function to update meta infos inside README.md
function update_readme () {

    BCLD_README='./README.md'

    KERNEL_STRING="$(/usr/bin/cat "${BCLD_README}" | /usr/bin/grep '\*\*BCLD Kernel\*\*' | /usr/bin/cut -d ':' -f2)"
    VERSION_STRING="$(/usr/bin/cat "${BCLD_README}" | /usr/bin/grep '\*\*BCLD Version\*\*' | /usr/bin/cut -d ':' -f2)"

    list_item "Updating kernel info: ${BCLD_README}"
    /usr/bin/sed -i "s/${KERNEL_STRING}/ ${KERNEL_VERSION}/" "${BCLD_README}"
    
    list_item "Updating version info: ${BCLD_README}"
    /usr/bin/sed -i "s/${VERSION_STRING}/ ${BCLD_VERSION_STRING}/" "${BCLD_README}"
}

generate_bcld_md5
top_bcld_md5
update_readme
on_completion
exit
