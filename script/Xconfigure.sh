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
# BCLD X Configure
# Most of the functions in this script have to do with setting graphical
# settings related to the X11 window management system that can run 
# Openbox and start the Chromium webkiosk.
#
# This script takes important BCLD video parameters from bcld.cfg and
# utilizes these to configure the graphical X system.
#
# X configurations, this script starts with Openbox (autostart).
source "/bin/log_tools.sh"

# ENVs
TAG='RUN-GRAPHICS'

/usr/bin/echo -e '\nStarting Xconfigure...\nOutput should not be visible in RELEASE!\n\n'

# Functions
## Function to wait for xbindkeys to start
function wait_xbindkeys () {
     if /usr/bin/pgrep -f 'xbindkeys' > /dev/null; then
        /usr/bin/echo 'xbindkeys started!'
    else
        /usr/bin/echo 'Waiting for xbindkeys...'
        /usr/bin/sleep 1s
    fi
}

## Set BCLD_RESOLUTION and BCLD_TRUE_SCALING based on BCLD_PRESET
function import_preset (){
	if [[ $(/usr/bin/xrandr -q | /usr/bin/grep -ci "${1}") -gt 0 ]]; then
		log_item "Setting preset: ${BCLD_PRESET^^}"
		BCLD_RESOLUTION="${1}"
		BCLD_TRUE_SCALING=${2}
	else
		log_item "Preset not found or resolution not supported!"
	fi
}

## Translate BCLD_BRIGHTNESS to BCLD_TRUE_BRIGHTNESS
function true_brightness (){
    BCLD_TRUE_BRIGHTNESS="$(/usr/bin/bc <<< "scale=2; ${1}/100")"
}

## Translate BCLD_SCALING to BCLD_TRUE_SCALING
function true_scaling (){
    BCLD_TRUE_SCALING="$(/usr/bin/bc <<< "scale=2; (200-${1})/100")"
}

# Logging
log_whitespace

log_header "Configuring X settings"

log_first 'Checking keyboard settings...'

# Bindings

## Xkbmap for disabling TTY switching
/usr/bin/setxkbmap -option srvrkeys:none

## Escaping
if [[ "${BCLD_MODEL}" != 'debug' ]]; then
    # Always load xmodmap and xbindkeys for RELEASE and TEST
    /usr/bin/xmodmap "${HOME}/.xmodmap"   # config file for disabling key mappings
    /usr/bin/xbindkeys -f "${HOME}/.xbindkeysrc"   # daemon with config file for disabling custom key combinations
    
    # Check if xbindkeys was started, take 10s max
    for n in $(/usr/bin/seq 1 10); do

        wait_xbindkeys # Output status or wait 1s

        # If started, break out immediately
        if /usr/bin/pgrep -f 'xbindkeys' > /dev/null; then
            break
        fi
    done
    
    if ! /usr/bin/pgrep -f 'xbindkeys' > /dev/null; then
        /usr/bin/echo 'xbindkeys could not be started!'
        log_item 'xbindkeys could not be started!'
    fi

else
    # Xkbmap for allowing escape in DEBUG
    /usr/bin/setxkbmap -option terminate:ctrl_alt_bksp
fi

log_item 'Checking BCLD boot parameters...'

## Mouse button swap
if [[ "${BCLD_VENDOR}" == 'vendorless' ]]; then
    # Since M2 is already disabled in Vendorless BCLD, always swap M2 and M3
    # This allows for the usage of tabs on laptops
    # xmodmap will automatically detect the current mouse and only change the appropriate buttons
    /usr/bin/echo -e "\nVendorless BCLD detected!" 
    /usr/bin/echo "Swapping mouse buttons 2 and 3..." 
    /usr/bin/xmodmap -e "pointer = 1 3 2"
fi

## Check if DISPLAY is set
if [[ -z ${DISPLAY} ]]; then
    /usr/bin/echo -e "\nDISPLAY is not set!" 
    /usr/bin/echo "Cannot launch BCLD app. Exiting..."
    exit 1
fi

## Detect default display
export BCLD_DISPLAY="$(/usr/bin/xrandr | /usr/bin/grep connected | /usr/bin/grep -v disconnected | /usr/bin/awk '{print $1}')"

## X Settings
/usr/bin/xset s off
/usr/bin/xset s noblank
# xset -dpms # Only throwing errors
# xsetroot -grey    # Doesn't really seem to work


# Xrandr configurations
# Only execute these, if the variables are set...
# If not, darkness...
# Must be in all caps
case ${BCLD_PRESET^^} in
	4K)
		import_preset '3840x2160' 0.5
	;;
	1080P)
		import_preset '1920x1080' 1
	;;
	HD+)
		import_preset '1600x900' 1
	;;
	768P)
		import_preset '1368x768' 1
	;;
	XGA)
		import_preset '1280x1024' 1.1
	;;
	*)
		log_item "Preset ${BCLD_PRESET^^} not found..."
	;;
esac

## Configure resolution
if [[ -n "${BCLD_RESOLUTION}" ]] && [[ $(/usr/bin/xrandr -q | /usr/bin/grep -ci "${BCLD_RESOLUTION}") -gt 0 ]]; then
	log_item "Setting resolution: ${BCLD_RESOLUTION,,}"
    /usr/bin/xrandr -s "${BCLD_RESOLUTION,,}"
fi

## Configure rotation
if [[ -n "${BCLD_ROTATION}" ]]; then
	log_item "Setting rotation: ${BCLD_ROTATION,,}"
    /usr/bin/xrandr -o "${BCLD_ROTATION,,}"
fi

## Configure scaling (requires DISPLAY)
if [[ -n "${BCLD_DISPLAY}" ]] && [[ -n "${BCLD_SCALING}" ]]; then
	log_item "Setting scaling: ${BCLD_SCALING}"
    true_scaling "${BCLD_SCALING}" # Generate BCLD_TRUE_SCALING
    /usr/bin/xrandr --output "${BCLD_DISPLAY}" --scale "${BCLD_TRUE_SCALING}" --filter nearest
fi

## Configure brightness (requires DISPLAY)
if [[ -n "${BCLD_DISPLAY}" ]] && [[ -n "${BCLD_BRIGHTNESS}"  ]]; then
	log_item "Setting brightness: ${BCLD_BRIGHTNESS}"
	true_brightness "${BCLD_BRIGHTNESS}" # Generate BCLD_TRUE_BRIGHTNESS
    /usr/bin/xrandr --output "${BCLD_DISPLAY}" --brightness "${BCLD_TRUE_BRIGHTNESS}"
fi

log_last 'X settings configured!'

# For adding XORG logs to the journal
TAG="LOG-GRAPHICS"

# Graphics
log_whitespace
log_header "Getting graphics information"
log_whitespace
log_line "── X-Org:"
output_file "${XORG_USR_LOG}"
log_whitespace
log_line "── XRandR"
log_line "$(/usr/bin/xrandr -d ${DISPLAY} -q)"
log_whitespace
log_line "── XRandR properties:"
log_line "$(/usr/bin/xrandr --props)"
log_whitespace

/usr/bin/echo 'Xconfigure complete!'
