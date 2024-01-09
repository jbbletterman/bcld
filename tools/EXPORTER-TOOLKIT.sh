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
# Exporter Toolkit
# Collection of functions to work with BCLD files
TAG='BEX-KIT'

PROJECT_DIR=$(/usr/bin/dirname "$(/usr/bin/dirname "$(/usr/bin/readlink -f ${BASH_SOURCE})")")

source "${PROJECT_DIR}/config/BUILD.conf"
source "${PROJECT_DIR}/script/echo_tools.sh"

# Function to create some default export directories and mounts
function base_export () {
	MOUNT_DIR=$(/usr/bin/mktemp -d --suffix=_BCLD_IMGMOUNT) || exit 1
	
	FULL_PATH="$(/usr/bin/readlink -f "${1}")"
	LOOP_DEV="$(/usr/bin/sudo /usr/sbin/losetup --show --partscan --find "${1}")"
	
	list_item "Base export configurations completed for ${2}!"
}

# Function to cleanup after base_export
function base_cleanup () {
	/usr/bin/sudo /usr/bin/umount -lf "${MOUNT_DIR}"
	/usr/bin/sudo /usr/sbin/losetup -D
	/usr/bin/sudo /usr/bin/rm -rf "${MOUNT_DIR}"
	list_item "Cleanup completed for ${1}."
}

# Function to easily unpack all files from a BCLD IMG
function img_export () {
	if [[ ${1} ]]; then 


		# Vars
		base_export "${1}" "${TAG}"
		IMG_EXPORT="$(/usr/bin/echo "${FULL_PATH}" | /usr/bin/cut -d '.' -f1)"
		
		list_item "↻ Starting IMG Exporter"
		list_entry

		/usr/bin/sudo /usr/bin/mount "${LOOP_DEV}p2" "${MOUNT_DIR}"
		/usr/bin/sudo /usr/bin/mkdir "${IMG_EXPORT}"
		/usr/bin/sudo /usr/bin/rsync -ahHAX --info=progress2 ${MOUNT_DIR}/* "${2:-$IMG_EXPORT}" 
		list_catch
		list_item "IMG export complete!"
		
		base_cleanup "${TAG}"
	elif [[ ! -f /usr/bin/rsync ]]; then
		on_failure "Please install rsync..."
	else
		on_failure "Please provide an image..."
	fi
}

# Function to easily unpack BCLD-ISO from IMG-file
function iso_export () {
	if [[ ${1} ]]; then 

		# Vars
		base_export "${1}" "${TAG}"
		ISO_EXPORT="$(/usr/bin/echo "${FULL_PATH}" | /usr/bin/cut -d '.' -f1)"
		
		list_item "↻ Starting ISO Exporter"
		list_entry

		/usr/bin/sudo /usr/bin/mount -o loop "${LOOP_DEV}" "${MOUNT_DIR}"
		/usr/bin/sudo /usr/bin/rsync -ahHA --info=progress2 ${MOUNT_DIR}/* "${2:-$ISO_EXPORT}"
		list_catch
		list_item "ISO export complete!"

		base_cleanup "${TAG}"
	else
		on_failure "\nPlease provide an image..."
	fi
}

# Function to fully export a BCLD IMG-file
function double_export () {
	list_item "⇆ Starting Double Export..."
	img_export "${1}"
	iso_export "${IMG_EXPORT}/bcld.iso"
	list_item "Double export finished!"
}

# Function to fully export a BCLD IMG-file
function full_export () {
	list_header "⇊ Full Export..."
	double_export "${1}"
	list_item "Starting unsquashfs..."
	list_entry
	/usr/bin/sudo /usr/bin/unsquashfs -d bcld-chroot "${ISO_EXPORT}/casper/filesystem.squashfs"
	list_catch
	on_completion "FULL export finished!"
}

# Function to export PXE files from a BCLD-IMG
function pxe_export () {
	list_item "Starting PXE Export..."
	double_export "${1}"
	list_entry
	/usr/bin/sudo /usr/bin/rsync -ahHAX --info=progress2 ${IMG_EXPORT}/bcld/casper/{initrd,vmlinuz} "${IMG_EXPORT}"
	list_catch
	# Make files accessible to PXE
	/usr/bin/sudo /usr/bin/chmod 644 ${IMG_EXPORT}/{initrd,vmlinuz}
	/usr/bin/sudo /usr/bin/rm -rf "${IMG_EXPORT}/bcld" "${IMG_EXPORT}/bcld.cfg"
	list_item "PXE export fininished!"
}

# Function to test if BCLD image was recently downloaded
function wget_link () {
    
    list_item "Checking BCLD downloads..."
	
	if [[ -f "${FILE_NAME}" ]]; then
		list_item "File exists! Skipping download..."
	else
		list_item "Starting BCLD download..."
		/usr/bin/sudo /usr/bin/wget "${1}"
		list_item "BCLD download complete!"
	fi
}

# Function to easily bootstrap BCLD from a URL for PXE
function pxe_bootstrap () {
	if [[ ${1} ]]; then 

		list_header "↧ PXE Bootstrap"

		# Vars
		FILE_NAME="$(/usr/bin/basename "${1}")"
		BASENAME="$(/usr/bin/echo "${FILE_NAME//.img/}")"
		
		BCLD_KERNEL="${BASENAME}/vmlinuz"
		BCLD_RAMFS="${BASENAME}/initrd"
		BCLD_ISO="${BASENAME}/bcld.iso"

		# Old PXE cleanup
		if [[ -f ${BCLD_KERNEL} ]] \
			|| [[ -f ${BCLD_RAMFS} ]] \
			|| [[ -f ${BCLD_ISO} ]]; then
			/usr/bin/rm -f "${BCLD_KERNEL}" "${BCLD_RAMFS}" "${BCLD_ISO}"
			list_item "Older PXE artifacts removed!"
		else
			list_item "No PXE artifacts found!"
		fi

		# Getting the IMG-file
		wget_link "${1}" || exit

		pxe_export "${FILE_NAME}"
		
		
		on_completion "PXE bootstrap finished!"
	else
		on_failure "Please provide a download link..."
	fi
}

# Function to check total size of BCLD filesystem
function du_export () {
    list_item "Checking BCLD file system size (sorted)..."
    list_entry
	/usr/bin/du --max-depth=1 -h "${1}" | /usr/bin/sort -r --human-numeric-sort
	list_catch
	# Check largest libraries in /usr
	list_item "Checking largest system libraries (bigger than 1MB)..."
	list_entry
	/usr/bin/du --max-depth=1 -h -t 1M "${1}/usr/lib" | /usr/bin/sort -r --human-numeric-sort
	list_catch
}
