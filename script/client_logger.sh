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
# BCLD Client Logger
# This script populates the Journal with logging information.
# This journal can then be exported to USB or over Rsyslog.

source '/bin/log_tools.sh'

## VARs
DMI_SMBIOS="$(/usr/bin/sudo /usr/sbin/dmidecode -t bios)"
DMI_SYSTEM="$(/usr/bin/sudo /usr/sbin/dmidecode -t bios)"
FREE_DISK="$(/usr/bin/df -h)"
FREE_MEM="$(/usr/bin/free -hl --mega)"
HW_ARCH="$(/usr/bin/uname --hardware-platform)"
IP_ADDRESS="$(/usr/sbin/ip -d addr)"
IP_LINK="$(/usr/sbin/ip -d link)"
IP_ROUTE="$(/usr/sbin/ip -d route)"
KERNEL_NAME="$(/usr/bin/uname --kernel-name)"
KERNEL_RELEASE="$(/usr/bin/uname --kernel-release)"
KERNEL_VERSION="$(/usr/bin/uname --version)"
LS_BLK="$(/usr/bin/lsblk)"
LS_MODULES="$(/usr/sbin/lsmod)"
LS_USB="$(/usr/bin/lsusb --tree --verbose)"
MACHINE_ARCH="$(/usr/bin/uname --machine)"
NM_CHANNEL="$(/usr/bin/nmcli -p -f all c)"
NM_GENERIC="$(/usr/bin/nmcli -p -f all g)"
NM_RADIO="$(/usr/bin/nmcli -p -f all r)"
NM_WIFI_LIST="$(/usr/bin/nmcli -p -f all dev wifi list)"
NODE_NAME="$(/usr/bin/uname --nodename)"
OS="$(/usr/bin/uname --operating-system)"
PACKAGES="$(/usr/bin/dpkg --get-selections | /usr/bin/grep install | /usr/bin/awk '{ print $1 }')"
PACMDUMP="$(/usr/bin/pacmd dump)"
PCI_MACHINE="$(/usr/bin/lspci -mmv)"
PCI_VERBOSE="$(/usr/bin/lspci -vvv)"
PROC_ARCH="$(/usr/bin/uname --processor)"
TOP_CPU="$(/usr/bin/top -b -d 0 -n 1 -o %CPU | /usr/bin/head -n 30)"
TOP_MEM="$(/usr/bin/top -b -d 0 -n 1 -o %MEM | /usr/bin/head -n 30)"

## NSSDB
NSSDB_CERTS="$(/usr/bin/certutil -d "sql:/home/${BCLD_USER}/.pki/nssdb" -L)"

## Files
ASOUND_CARDS="/proc/asound/cards"
ASOUND_DEVICES="/proc/asound/devices"
ASOUND_MODULES="/proc/asound/modules"
CMD_LINE="/proc/cmdline"
CPU_INFO="/proc/cpuinfo"
DNS="/etc/resolv.conf"
MACHINE_ID="/etc/machine-id"
VERSION="/VERSION"

### Dirs
LOG_DIR="/var/log"

### Log Files
ALTERNATIVES="${LOG_DIR}/alternatives.log"
PLYMOUTH_LOG="${LOG_DIR}/boot.log"
BOOTSTRAP_LOG="${LOG_DIR}/bootstrap.log"
CASPER_LOG="${LOG_DIR}/casper.log"


## pactl does not work inside a VM
if [[ $(/usr/bin/systemd-detect-virt) == 'none' ]]; then
    # This will fail in VM
    ALSA_CARDS="$(/usr/bin/aplay -l)"
fi

## EXE

# Basic info logging
log_whitespace
log_header "Basic information"
log_first "App Version: ${BCLD_APP_VERSION}"
log_item "BCLD Version: $(output_line ${VERSION})"
log_item "System ID: $(output_line ${MACHINE_ID})"
log_last "Boot configuration: $(output_line ${CMD_LINE})"
log_whitespace

# ENVs
log_whitespace
log_header "BCLD ENVs"
log_line "$(/usr/bin/env | /usr/bin/sort | grep -v 'SECRET' )"
log_whitespace

# Uname
log_whitespace
log_header "Uname information"
log_first "Kernel name: ${KERNEL_NAME}"
log_item "Node name: ${NODE_NAME}"
log_item "Kernel release: ${KERNEL_RELEASE}"
log_item "Machine arch: ${MACHINE_ARCH}"
log_item "Processor arch: ${PROC_ARCH}"
log_item "Platform arch: ${HW_ARCH}"
log_item "Operating system: ${OS}"
log_last "Kernel version: ${KERNEL_VERSION}"
log_whitespace

# Firmware
log_whitespace
log_header "Firmware (SMBIOS) information"
log_line "── System:"
log_line "${DMI_SYSTEM}"
log_whitespace
log_line "── BIOS:"
log_line "${DMI_SMBIOS}"

# CPU
log_whitespace
log_header "Processor information"
output_file "${CPU_INFO}"

# Processes
log_whitespace
log_header "Running processes"
log_whitespace
log_line "── By CPU:"
log_line "${TOP_CPU}"
log_whitespace
log_line "── By memory:"
log_line "${TOP_MEM}"
log_whitespace

# Memory
log_whitespace
log_header "Free memory"
log_line "${FREE_MEM}"
log_whitespace

# USB
log_whitespace
log_header "USB devices"
log_line "${LS_USB}"
log_whitespace

# PCI
log_whitespace
log_header "PCI Devices"
log_whitespace
log_line "── Machine readable"
log_line "${PCI_MACHINE}"
log_whitespace
log_line "── Verbose"
log_line "${PCI_VERBOSE}"
log_whitespace

# NSS Database
log_whitespace
log_header "NSS Database"
log_line "Stored certificates:"
log_line "${NSSDB_CERTS}"
log_whitespace
log_line "Stored keys:"
log_line "${NSSDB_KEYS}"
log_whitespace

# Network Info
log_whitespace 
log_header "Listing network information"
log_whitespace
log_first "Default interface: ${BCLD_IF}"
log_item "MAC address: ${BCLD_MAC}"
log_item "IP address: ${BCLD_IP}"
log_item "Speed: ${BCLD_SPEED} Mb/s"
log_item "Download: ${BCLD_DOWNLOAD} B/s"

# Packet loss, has to be checked runtime
TX_DROPPED="$(/usr/bin/netstat --statistics | /usr/bin/grep 'outgoing packets dropped' | /usr/bin/awk '{ print $1 }')"
RX_PACKETS="$(/usr/bin/netstat --statistics | /usr/bin/grep 'total packets received' | /usr/bin/awk '{ print $1 }')"
RX_DISCARDED="$(/usr/bin/netstat --statistics | /usr/bin/grep 'incoming packets discarded' | /usr/bin/awk '{ print $1 }')"

PACKET_LOSS="$(( TX_DROPPED + RX_DISCARDED ))"

if [[ ${PACKET_LOSS} -eq 0 ]]; then
	log_last 'No packets lost so far!'
else
	log_last "Current packet loss: ${PACKET_LOSS} of ${RX_PACKETS}"
fi

log_whitespace
log_line '── IP (link):'
log_line "${IP_LINK}"
log_whitespace
log_line '── IP (address):'
log_line "${IP_ADDRESS}"
log_whitespace
log_line "── IP (route):"
log_line "${IP_ROUTE}"
log_whitespace
log_line "── Network Manager information:"
log_line "${NM_GENERIC}"
log_line "${NM_CHANNEL}"
log_line "${NM_RADIO}"
log_whitespace
log_line "── Wifi networks:"
log_line "${NM_WIFI_LIST}"
log_whitespace
log_line "── DNS:"
output_file "${DNS}"
log_whitespace

# Audio
log_whitespace
log_header "Getting audio information"
log_whitespace
log_line "── ALSA Cards:"
output_file "${ASOUND_CARDS}"
log_whitespace
log_line "── ALSA devices:"
output_file "${ASOUND_DEVICES}"
log_whitespace
log_line "── ALSA modules:"
output_file "${ASOUND_MODULES}"
log_whitespace
log_line "── PLAYBACK Audio Devices:"
log_line "${ALSA_CARDS}"
log_whitespace
log_line "── PulseAudio dump:"
log_line "${PACMDUMP}"
log_whitespace

# Bootstrap
#log_header "Bootstrap"
#output_file "${BOOTSTRAP_LOG}"
#log_whitespace

# DPKG
log_header "Packages"
log_line "${PACKAGES}"
log_whitespace

# Casper
log_header "Casper logs"
output_file "${CASPER_LOG}"
log_whitespace
log_header "Casper MD5check"
output_file "${BCLD_MD5CHECK}"

# Boot, the only file to require sudo
log_header "Plymouth log"
sudo_output_file "${PLYMOUTH_LOG}"
log_whitespace

# Alternatives
log_header "Alternatives"
output_file "${ALTERNATIVES}"
log_whitespace

# Overall info
log_whitespace
log_header "Listing kernel modules"
log_line "${LS_MODULES}"
log_whitespace
log_whitespace 
log_header "Listing block devices"
log_line "${LS_BLK}"
log_whitespace
log_whitespace 
log_header "Listing file system size"
log_line "${FREE_DISK}"
log_whitespace

# Openbox
# Must create empty file before we can follow it
if [[ ! -f ${OPENBOX_LOG} ]]; then
    mkdir -p "$(/usr/bin/dirname "${OPENBOX_LOG}")"
    /usr/bin/echo -e "# Openbox logs\n" >> "${OPENBOX_LOG}"
fi

log_whitespace
log_header "Openbox"
output_file "${OPENBOX_LOG}"
follow_file "${OPENBOX_LOG}"
log_whitespace

# Dump generated logs to local target first
# Then, follow the new entries (with X11 info)
log_header "Journal"
log_line "Dumping journal to ${BCLD_LOG}"
/usr/bin/journalctl --no-pager | /usr/bin/sudo /usr/bin/tee "${BCLD_LOG}" &> /dev/null
/usr/bin/journalctl --no-pager -f | /usr/bin/sudo /usr/bin/tee -a "${BCLD_LOG}" &> /dev/null &
