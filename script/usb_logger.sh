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
# USB Logger
# Script for automatic offloading the BCLD journal to a USB device.

source '/bin/log_tools.sh'

# ENVs
BCLD_USB='/dev/disk/by-label/BCLD-USB'
MOUNT_LOCATION='/media/BCLD-USB'
USB_LOG_FILE="${MOUNT_LOCATION}/bcld.log"

# FUNCTIONS

## Function to umount if mounted
function clear_mount () {
    if [[ $(/usr/bin/mount -l | cut -d ' ' -f3 | grep -Ec "^${1}$") -gt 0 ]]; then
        log_line "Unmounting ${1}..."
        /usr/bin/umount -lfq "${1}" &> /dev/null
    else
        log_line "Cannot unmount ${1}: not mounted..."
    fi
}


## Function to dump logs to mounted BCLD-USB if bcld.log can be found
function dump_logs() {
	if [[ -f "${USB_LOG_FILE}" ]]; then
		log_line "${USB_LOG_FILE} found! Writing log to file..."
		/usr/bin/journalctl --no-pager &> "${USB_LOG_FILE}"
		/usr/bin/journalctl --no-pager -f &>> "${USB_LOG_FILE}"
	else
		# Unmount USB if it has no bcld.log and continue back to loop
		log_line "No USB log file found on BCLD-USB, unmounting..."
		clear_mount "${MOUNT_LOCATION}"
	fi
}

## Function to mount if BCLD_USB was found
function mount_BCLD_USB () {
	
	# Sleep for udev to translate labels
	/usr/bin/sleep 1s
	
	if [[ -b "${BCLD_USB}" ]]; then
		log_line "Mounting BCLD-USB..."
		/usr/bin/mount "${BCLD_USB}" "${MOUNT_LOCATION}" &> /dev/null
		dump_logs
	else
		# Continue back to the loop
		log_line "BCLD-USB not found!"
	fi
}


# EXE

## Write logging to any file that is currently on BCLD-USB named bcld.log
mount_BCLD_USB

## Monitor for changes in /dev/disk
# Infinite loop that only responds to disks by-label, only on CREATE, and only on BCLD-USB tags
# This is so BCLD-USB can be reconnected for logging
/usr/bin/inotifywait --monitor --recursive --quiet "$(/usr/bin/dirname ${BCLD_USB} )" -e create --include "BCLD-USB*" |
    while read dir action file; do
        log_line 'BCLD-USB DETECTED!!!'
        log_line "${file} appeared in ${dir} by ${action}, attempting mount..."
		mount_BCLD_USB
    done
