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
# BCLD File Operations
# File operations for BCLD using echo_tools.sh
# Some operations are so important, that they must fail with an exit, because we cannot continue without these operations

source './script/echo_tools.sh'
source './config/BUILD.conf'

# Prepare directory
function prep_dir () {
    if [[ ! -d ${1} ]]; then
        list_item "${1} does not exist yet! Creating..."
        /usr/bin/mkdir -p "${1}"
        else
        list_item "${1} already exists! Ignoring..."
    fi    
}

## Function to copy a configuration file
function copy_file {
    if [[ -f ${1} ]]; then
	    list_item "Copying file $(basename "${1}")..."
	    /usr/bin/cp ${1} ${2}
    else
    	list_item "File does not exist!"
    	exit 1
    fi
}

## Function to copy a configuration directory
function copy_directory {
    if [[ -d ${1} ]]; then
		list_item "Copying directory $(basename "${1}")..."
		/usr/bin/cp -r ${1} ${2}
	else
		list_item "Directory does not exist!"
		exit 1
    fi
}

## Function to copy a configuration directory
function copy_recursively {
    if [[ -d ${1} ]]; then
		list_item "Copying recursively $(basename "${1}")..."
		/usr/bin/cp -r ${1}/* ${2}
	else
		list_item "Files do not exist!"
		exit 1
    fi
}

# Substitute file, overwrite
function subst_file () {
    if [[ -f ${1} ]]; then
        list_item "Substituting $(/usr/bin/basename "${2}")..."
        /usr/bin/envsubst < "${1}" > "${2}"
    else
        list_item "Substitute file does not exist!"
        exit 1
    fi    
}

# Substitute file, do not overwrite
function subst_file_add () {
    if [[ -f ${1} ]]; then
        list_item "Substituting $(/usr/bin/basename "${2}")..."
        /usr/bin/envsubst < "${1}" >> "${2}"
    else
        list_item "Substitute file does not exist!"
        exit 1
    fi    
}

# Function to delete file which already exists
function reset_file () {
    base_name=$(basename "${1}")
    if [[ -f "${1}" ]]; then
        list_item "${base_name} already exists! Deleting ${base_name}..."
        /usr/bin/rm -f "${1}"
    fi
}

# Function to delete file if it exists with description
#   1: PATH
#   2: DESC
function delete_file () {
    if [[ -f ${1} ]]; then
        list_item "Deleting file: ${1} (${2})..."
        /usr/bin/rm -f ${1}
    else
        list_item "Cannot delete ${1}: File does not exist..."
    fi
}

# Function to delete existing directory if it exists with description
function delete_dir () {
    if [[ -d ${1} ]]; then
        list_item "Deleting directory: ${1} (${2})..."
        /usr/bin/rm -rf ${1}
    else
        list_item "Cannot delete ${1}: Directory does not exist..."
    fi    
}

# Function to clean up environment
function clean_chroot () {
    
    list_item "Cleaning up chroot..."
    
    # Chroot
    if [[ -d "${CHROOT_DIR}" ]]; then
        list_item "${CHROOT_DIR} already exists, clearing contents..."
        /usr/bin/rm -rf ${CHROOT_DIR}/*
    else
        list_item "Chroot does not exist yet, creating..."
        prep_dir "${CHROOT_DIR}"
    fi 
}

# Function to check if ISO artifact is present
function check_iso_file () {

    export ISO_NAME="bcld.iso"

    if [[ -f "$(pwd)/artifacts/${ISO_NAME}" ]]; then
        list_item_pass "bcld.iso found!"
    else
        list_item_fail "ISO-artifact missing!" 
        on_failure
    fi

}

# Function to check size of image or fail
function check_img_size () {

    list_item "Checking: ${1}..."

    # Vars
    IMG_THRESH=1000000 # Threshold in KB
    IMG_SIZE="$(/usr/bin/du "${1}" | /usr/bin/awk ' {print $1} ')"
    IMG_SIZE_HUMAN="$(/usr/bin/du -h "${1}" | /usr/bin/awk ' {print $1} ')"
    
    # Compare
    if [[ ${IMG_SIZE} -gt ${IMG_THRESH} ]]; then
	    list_item_pass "Size: ${IMG_SIZE_HUMAN}"
	    on_completion
    else
	    list_item_fail "WARNING: SMALL BCLD-IMG (${IMG_SIZE_HUMAN})!"
	    on_failure
    fi    
}

# Function to let Bamboo clean up ./chroot if possible, otherwise clean normally
function chown_bamboo () {
    # Only clean if Bamboo doesn't exist (trigger on error)
    /usr/bin/chown --recursive bamboo:bamboo ./chroot &> /dev/null
}

# Function to remove old artifacts
function clean_art () {

    list_item "Cleaning up old artifacts..."
    
	art_count=$(/usr/bin/find "${ART_DIR}" -mindepth 1 -maxdepth 1 -type f | wc -l)
    
    if [[ -d "$ART_DIR" ]] && [[ "${art_count}" -gt 0 ]]; then
        # If the directory exists, and isn't empty, clear it.
        list_item "Removing old artifacts from ${ART_DIR}..."
        list_entry
        /usr/bin/rm -fv ${ART_DIR}/*
    else
        # If there is no match, then it means there are no artifacts yet.
        list_item "No older artifacts detected."
    fi
}

# Function to umount if mounted
function clear_mount () {
    if [[ $(/usr/bin/mount -l | cut -d ' ' -f3 | grep -Ec "^${1}$") -gt 0 ]]; then
        list_item "Unmounting ${1}..."
        /usr/bin/umount -lfq "${1}"
    else
        list_item "Cannot unmount ${1}: not mounted..."
    fi
}

# Function for cleaning up after the IMG generation
function clear_loop_devs () {
	list_item "Detaching loop devices..."
    /usr/sbin/losetup --detach-all
}
