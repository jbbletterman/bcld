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
# BCLD Startup
# Very essential script for the BCLD client, which contains most of the
# configurations necessary before booting the online webkiosk.
#
# This script is the heart of BCLD and where BCLD will boot the Chromium
# Node webapp after configuring the network, audio, video and other
# hardware settings.
#
#set -x
BCLD_TEST='/usr/bin/bcld_test.sh'

# Load TEST package OR trap inside RELEASE/DEBUG
if [[ "${BCLD_MODEL}" == 'test' ]] \
    && [[ -f "${BCLD_TEST}" ]]; then
	# If TEST, load package
	source '/usr/bin/bcld_test.sh'
else
	# If not TEST, trap
	trap '' SIGHUP SIGINT SIGQUIT SIGTERM SIGTSTP
fi

# Imports
source '/usr/bin/echo_tools.sh'

# ENVs
if [[ $(/usr/bin/apt-cache show "${BCLD_RUN}" | /usr/bin/wc -l) -gt 0 ]]; then
    # If BCLD_RUN is a DEB, grab version
    export BCLD_APP_VERSION="$(/usr/bin/apt-cache show "${BCLD_RUN}" | /usr/bin/grep 'Version:' | cut -d ' ' -f2) (${BCLD_RUN})"
else
    # If BCLD_RUN is an AppImage, grab version from name
    export BCLD_APP_VERSION="$(/usr/bin/echo ${BCLD_APP} | /usr/bin/cut -d '_' -f2)"

fi

export BCLD_KERNEL_VERSION="$(/usr/bin/uname -r)"
export BCLD_VERSION_STRING="$(/usr/bin/cat /VERSION)"

# VARs
TAG="RUN-LIVE"

## Paths
CDROM="/dev/cdrom"
DHCP_LEASE="/var/lib/dhcp/dhclient.leases"
MACHINE_ID='/etc/machine-id'
SROM="/dev/sr0"
XT_DIR="${HOME}/xterm"
QT_CONFIG="${HOME}/.config/qutebrowser/config.py"

## Parameters
APP_DEBUG_PORT='12253'
CLIENT_DEBUG_PORT='2253'
CMD_LINE=$(/usr/bin/cat /proc/cmdline)
PACTL_DEFAULT_VOL=125
PACTL_DEFAULT_REC=100
VENDORLESS_PARAM='c.url.start_pages'


## PACTL scans sinks 20 times before it continues, each scan has a 1s sleep timer
PACTL_SCANS='20'
## SCAN_TRIES before giving up on LAN, or shutting down after WLAN
SCAN_TRIES='3'

# FUNCTIONS

## Function to create directories with root permission
function prep_dir () {
    if [[ ! -d ${1} ]]; then
        list_item "${1} does not exist yet! Creating..."
        /usr/bin/sudo /usr/bin/mkdir -pv "${1}" || exit
    fi    
}

## Function to lazy force umounts if mounted
function lf_umount () {
    if [[ $(/usr/bin/mount -l | /usr/bin/grep -c "${1}") -gt 0 ]]; then
        list_item "${1} mounted! Unmounting..."
        /usr/bin/sudo /usr/bin/umount -lf "${1}"
    fi    
}

## To set machine-id
function set_machine_id () {
    
    ## Set only if empty
    if [[ ! -f /etc/machine-id ]] || [[ "$(/usr/bin/cat /etc/machine-id | /usr/bin/wc -l)" -eq 0 ]]; then
        print_item "MACHINE_ID not set! Setting: "
        /usr/bin/systemd-machine-id-setup || exit 1

        export BCLD_MACHINE_ID="$(/usr/bin/cat ${MACHINE_ID})"
    fi
}

## Set hostname
function bcld_set_hostname () {
	list_item "Changing hostname to ${1}..."
			
	# New hostname
	/usr/bin/hostnamectl set-hostname "${1}"
	
	/usr/bin/sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 ${1}/" /etc/hosts &> /dev/null
	/usr/bin/sudo sed -i "s/127.0.1.1 //" /etc/hosts &> /dev/null
	
	# New hostname requires relog
	last_item "Relogging with new hostname..." && logout
}

## To set hostname with BCLD_VENDOR
function reset_bcld_hostname () {

	# Set hostname using selected vendors
	# A relog is needed for sudo's to proceed
	# Only needs to relog if hostname is the default

	# Do this only if the hostname is 'localhost.localdomain'
	if [[ "$(/usr/bin/hostname)" == 'localhost.localdomain' ]]; then

        list_item 'Configuring hostname...'

		# First, find a random MAC address on the system, filter virtual interfaces
		BCLD_MAC_RANDOM="$(/usr/bin/find /sys/devices/* -type f -name 'address' | /usr/bin/grep 'net' | /usr/bin/grep -v -m1 'lo')"

		# Change hostname only if a device is found
		if [[ -f "${BCLD_MAC_RANDOM}" ]]; then

			# Pick hostname based on MAC
			list_item "Physical interfaces detected..."

			# ENVs
			BCLD_HASH="$(/usr/bin/sed "s/://g" "${BCLD_MAC_RANDOM}")"
			BCLD_HOST="${BCLD_VENDOR}-${BCLD_HASH}"

			bcld_set_hostname "${BCLD_HOST}"
		else
			# Pick different hostname if no MAC interface
			list_item "No physical interfaces detected... Using machine-id."

			# ENVs
			BCLD_ID="$(/usr/bin/cat /etc/machine-id | /usr/bin/cut -c 1-12)"
			BCLD_HOST="${BCLD_VENDOR}-${BCLD_ID}"

			bcld_set_hostname "${BCLD_HOST}"
		fi
	else
		# If the default hostname is changed, keep it
		list_item_pass "Hostname already appears to be changed: $(/usr/bin/hostname)"
	fi
}

## Function to take key/value from CMD_LINE, and change it to whatever we need.
function readparam () {
    
    # Loop through CMD_LINE.
    for KERNEL_PARAM in ${CMD_LINE}; do
        
        # Match whatever we are looking for.
        if [[ $KERNEL_PARAM == "${2}"* ]]; then
            # Strip that value and give it to a new export.
            KERNEL_PARAM=$(/usr/bin/echo "${KERNEL_PARAM}" | /usr/bin/sed 's/=/ /')
            IFS=' ' read -r NAME VALUE <<< "${KERNEL_PARAM}"
            export "${1}"="${VALUE}"
            break
        fi
    done
}

## Function to read BCLD_VENDOR Parameter
function read_vendor_param() {

	# Set BCLD_VENDOR with parameter
	readparam "${VENDOR_PARAM}" "${VENDOR_ALIAS}"
	
	# Set BCLD_VENDOR if no parameter
	if [[ -z "${BCLD_VENDOR}" ]]; then
	    
	    list_item 'BCLD_VENDOR not set...'
		
		# If BCLD App found, default to 'facet'
		if [[ -x /opt/deb-app-afname ]]; then
		    list_item 'Setting to default: FACET'
		    export BCLD_VENDOR='facet'
	    else
	        # Without a Facet Chrome app, we are likely running Vendorless BCLD
	        list_item 'BCLD App not found, setting to: VENDORLESS BCLD'
		    export BCLD_VENDOR='vendorless'
		fi
	else
		# Display used BCLD_VENDOR parameter
		list_item_pass "Setting BCLD_VENDOR to ${BCLD_VENDOR^^}!"
	fi
	
}

## Function to read every BCLD Boot Parameter
function read_all_params() {

	list_item 'Reading all BCLD boot parameters'

	### Afname
	readparam "${AFNAME_PARAM}" "${AFNAME_ALIAS}"
	readparam "${MOUSE_PARAM}" "${MOUSE_ALIAS}"
	readparam "${SHUTDOWN_PARAM}" "${SHUTDOWN_ALIAS}"
	readparam "${VENDOR_PARAM}" "${VENDOR_ALIAS}"
	readparam "${ZOOM_PARAM}" "${ZOOM_ALIAS}"

	### Audio
	readparam "${AUDIO_ALSA_SINK_PARAM}" "${AUDIO_ALSA_SINK_ALIAS}"
	readparam "${AUDIO_ALSA_PORT_PARAM}" "${AUDIO_ALSA_PORT_ALIAS}"
	readparam "${AUDIO_COMBINE_PARAM}" "${AUDIO_COMBINED_SINK_ALIAS}"
	readparam "${AUDIO_RECORD_PARAM}" "${AUDIO_RECORDING_ALIAS}"
	readparam "${AUDIO_RESTORE_PARAM}" "${AUDIO_RESTORE_ALIAS}"
	readparam "${AUDIO_SINK_PARAM}" "${AUDIO_DEFAULT_SINK_ALIAS}"
	readparam "${AUDIO_SOURCE_PARAM}" "${AUDIO_DEFAULT_SOURCE_ALIAS}"
	readparam "${AUDIO_VOLUME_PARAM}" "${AUDIO_DEFAULT_PLAYBACK_ALIAS}"

	### Display
	readparam "${DISPLAY_BRIGHTNESS_PARAM}" "${DISPLAY_BRIGHTNESS_ALIAS}"
	readparam "${DISPLAY_PRESET_PARAM}" "${DISPLAY_PRESET_ALIAS}"
	readparam "${DISPLAY_RESOLUTION_PARAM}" "${DISPLAY_RESOLUTION_ALIAS}"
	readparam "${DISPLAY_ROTATE_PARAM}" "${DISPLAY_ROTATE_ALIAS}"
	readparam "${DISPLAY_SCALE_PARAM}" "${DISPLAY_SCALE_ALIAS}"

	### Network
	readparam "${DEFAULT_INTERFACE_PARAM}" "${DEFAULT_INTERFACE_ALIAS}"
	#readparam "${DNSSEC_PARAM}" "${DNSSEC_ALIAS}"
	readparam "${WIFI_PSK_PARAM}" "${WIFI_PSK_ALIAS}"
	readparam "${WIFI_SSID_PARAM}" "${WIFI_SSID_ALIAS}"
	readparam "${WOL_DISABLED_PARAM}" "${WOL_DISABLED_ALIAS}"
	readparam "${WWAN_ENABLED_PARAM}" "${WWAN_ENABLED_ALIAS}"
	
	#### EDUROAM
	readparam "${WIFI_EAP_AUTH_PARAM}" "${WIFI_EAP_AUTH_ALIAS}"
	#readparam "${WIFI_EAP_DOMAIN_PARAM}" "${WIFI_EAP_DOMAIN_ALIAS}"
	readparam "${WIFI_EAP_METHOD_PARAM}" "${WIFI_EAP_METHOD_ALIAS}"
	readparam "${WIFI_EAP_PASSWD_PARAM}" "${WIFI_EAP_PASSWD_ALIAS}"
	readparam "${WIFI_EAP_USER_PARAM}" "${WIFI_EAP_USER_ALIAS}"
}

# Function to execute casper-md5check manually
function BCLD_MD5CHECK () {
	
	if [[ -f "${BCLD_MD5CHECK}" ]]; then
	    list_item "Casper MD5check has passed, check ${BCLD_MD5CHECK}!"
	else
	    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
	        list_item "Running casper-md5check..."
		    list_entry
		    /usr/bin/sudo /usr/lib/casper/casper-md5check /cdrom /cdrom/md5_file | /usr/bin/tee "${BCLD_MD5CHECK}"
		    list_catch
	    else
		    /usr/bin/sudo /usr/lib/casper/casper-md5check /cdrom /cdrom/md5_file > "${BCLD_MD5CHECK}"
		    list_item "Casper $(/usr/bin/cat "${BCLD_MD5CHECK}" | /usr/bin/grep 'Check finished:')"
	    fi
    fi
}

# Function to umount important directories
function bcld_umount () {
	
	# Alternative Casper (if Plymouth not working)
	# Can only be done right before unmounting
	BCLD_MD5CHECK
	
	list_item "Unmounting necessary devices"
	lf_umount /cdrom
	lf_umount /media/BCLD-USB
	lf_umount "${CDROM}"
	lf_umount "${SROM}"
	list_item_pass "It is now safe to remove BCLD-USB (if bcld.log is not present)."
	/usr/bin/sleep 3s
}

# Function to to load Realtek kernel modules
function realtek_modules () {
	if [[ "$(/usr/bin/dpkg -l | /usr/bin/grep 'r8168-dkms' | /usr/bin/wc -l)" -gt 0 ]]; then
		list_item 'Realtek 8168 detected!'
		list_item_pass 'Using Realtek 8168!'
	else
		list_item_pass 'Using Realtek 8821ce (default)'
	fi
}

# Function to check for Nvidia kernel modules
function nvidia_modules () {

    NVIDIA_MODULES="$(/usr/bin/find /lib/modules/"$(/usr/bin/uname -r)"/kernel/ -maxdepth 1 -type d -name 'nvidia*' | /usr/bin/wc -l)"

    if [[ ${NVIDIA_MODULES} -gt 0 ]]; then
        
        silent_item_pass 'Nvidia modules installed...'
        export BCLD_NVIDIA='installed'
        
        if [[ $(/usr/bin/lsmod | /usr/bin/grep -c 'nvidia') -gt 0 ]]; then
            silent_item_pass 'Nvidia modules loaded!'
            export BCLD_NVIDIA='loaded'
            
            if [[ -x /usr/bin/nvidia-smi ]] && [[ -x /usr/bin/nvidia-detector ]]; then
                    if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
                        list_item_pass 'Nvidia driver detected!'
                        list_entry
                        /usr/bin/sudo nvidia-smi
                        list_catch
                    else
                        list_item_pass "Nvidia driver detected: $(/usr/bin/nvidia-detector)"
                    fi
                    export BCLD_NVIDIA='detected'
            else
                list_item_fail "Unable to detect Nvidia driver!"
                export BCLD_NVIDIA='undetected'
            fi
            
        else
            list_item_fail 'Nvidia modules could not be loaded!'
            export BCLD_NVIDIA='not loaded'
        fi
    fi
}

## Function to detect MAC and IP after BCLD_IF has been set and connection has been made
function ip_link () {
        if [[ -n "${BCLD_IF}" ]]; then
        	
        	list_item 'Fetching MAC and IP addresses...'
			
			if [[ -n "${BCLD_URL}" ]]; then
			    # Only perform network check on BCLD_URL (trusted)
			    list_item_pass "Performing network check on: \"${BCLD_URL}\""
			    export BCLD_DOWNLOAD="$(/usr/bin/curl -s -o /dev/null -w '%{speed_download}' "${BCLD_URL}")"
			fi
			
			export BCLD_IP="$(/usr/sbin/ip address | /usr/bin/grep "${BCLD_IF}" | /usr/bin/grep inet | /usr/bin/awk '{ print $2 }' | /usr/bin/cut -d '/' -f1 | /usr/bin/head -n 1)"
		    export BCLD_MAC="$(/usr/sbin/ip link show "${BCLD_IF}" | /usr/bin/grep link | /usr/bin/awk '{ print $2 }')"
		    export BCLD_SPEED="$(/usr/sbin/ip a | /usr/bin/grep "${BCLD_IF}" | /usr/bin/grep 'qlen' | /usr/bin/awk '{print $NF}')"
			
			BCLD_DISCARDED="$(/usr/bin/netstat --statistics | /usr/bin/grep 'incoming packets discarded' | /usr/bin/awk '{ print $1 }')"
			BCLD_DROPPED="$(/usr/bin/netstat --statistics | /usr/bin/grep 'outgoing packets dropped' | /usr/bin/awk '{ print $1 }')"
			
			PACKET_LOSS="$(( BCLD_DROPPED + BCLD_DISCARDED ))"
	    else
        	list_item 'Unable to fetch MAC and IP addresses, check BCLD_IF!'
	    fi
}

## Function to set BCLD_IF to wireless if still empty
function set_bcld_wireless () {
	# If BCLD_IF is still empty, it means we're going wireless
	if [[ -z "${BCLD_IF}" ]]; then   
		list_item "Setting default wireless interface..."
		export BCLD_IF="$(/usr/bin/basename $(/usr/bin/find /sys/class/ieee80211/*/device/net -mindepth 1 -maxdepth 1 -type d | /usr/bin/head -n 1))"
	fi
}

## Function to set BCLD_EAP_AUTH if still empty
function set_EAP_AUTH () {
	if [[ -z "${BCLD_EAP_AUTH}" ]]; then   
		export BCLD_EAP_AUTH='mschapv2'
	fi
	
	list_item "Setting default EAP authentication method: ${BCLD_EAP_AUTH}"
}

## Function to connect to PSK
function connect_psk () {

	detect_lan # Always prioritize LAN
	
	# Only connect to PSK if LAN failed
	if [[ ! -s "${DHCP_LEASE}" ]]; then
		list_item 'Attempting to connect (WPA-PSK)'
		
		list_entry
		/usr/bin/nmcli device wifi connect "${ssid_decoded}" password "$(/usr/bin/echo "${BCLD_PSK}" | /usr/bin/base64 -d)"
		list_catch
		
		# This method requires BCLD_IF
		set_bcld_wireless
		
		connect_wifi "${BCLD_IF}"
	fi

}

## Function to connect to EAP
function connect_eap () {

	detect_lan # Always prioritize LAN

	# Only connect to EAP if LAN failed
	if [[ ! -s "${DHCP_LEASE}" ]]; then
    	list_item 'Attempting to connect (WPA-EAP)...'
    	
		# This method requires BCLD_IF and BCLD_EAP_AUTH
		set_bcld_wireless
		set_EAP_AUTH

		/usr/bin/nmcli con add \
			type wifi \
			con-name 'eduroam' \
			ifname "${BCLD_IF}" \
			ssid "${ssid_decoded}" \
			wifi-sec.key-mgmt "wpa-eap" \
			802-1x.identity "$(/usr/bin/echo "${BCLD_EAP_USER}" | /usr/bin/base64 -d)" \
			802-1x.password "$(/usr/bin/echo "${BCLD_EAP_PW}" | /usr/bin/base64 -d)" \
			802-1x.eap "${BCLD_EAP_METHOD}" \
			802-1x.phase2-auth "${BCLD_EAP_AUTH}"

		/usr/bin/nmcli connection up 'eduroam'
		
		connect_wifi "${BCLD_IF}"
	fi

}

## Function to connect to LAN, if no other lease
function connect_lan () {

	attempt=1
	
	# Only do this if there is no DHCP lease yet
	while [[ ! -s "${DHCP_LEASE}" ]] \
		&& [[ "$(/usr/bin/grep -cs 'interface' "${DHCP_LEASE}")" -eq 0 ]]; do
		
		list_item "Attempting to establish wired connection on: ${1} (attempt: #${attempt})"
		/usr/bin/sudo /usr/sbin/dhclient "${1}" &> /dev/null
		((attempt++))
		
		# Break out after SCAN_TRIES
		if [[ "${attempt}" -eq "${SCAN_TRIES}" ]]; then
			list_item_fail "Tried ${attempt} times... Giving up."
			break
		fi
	done
		
}

## Function to detect LAN, if more than 1
function detect_lan () {
	list_item 'Checking wired interfaces...'
	
	WIRED_IF="$(/usr/bin/find /sys/class/net/ -name "en*" -exec basename {} \;)"
	
	if [[ $(/usr/bin/echo "${WIRED_IF}" | /usr/bin/wc -l) -gt 1 ]]; then
		
		for interface in ${WIRED_IF}; do
			connect_lan "${interface}"
		done
		
	else
		connect_lan "${WIRED_IF}"
	fi
}

## Function to connect to WiFi, if no other lease
function connect_wifi () {
	# Initiate DHCP on selected interface
	if [[ -n ${1} ]]; then
	
		attempt=1

		# Only do this if there is no DHCP lease yet
		while [[ ! -s "${DHCP_LEASE}" ]]; do
			list_item "Attempting to establish WiFi connection on: ${1} (attempt: #${attempt})"
			/usr/bin/sudo /usr/sbin/dhclient "${1}" &> /dev/null
			((attempt++))
			
			# Break out after SCAN_TRIES
			if [[ "${attempt}" -eq "${SCAN_TRIES}" ]]; then
				list_item_fail "Tried ${attempt} times... Giving up."
				break
    		fi
			
		done
	fi
}

## Function to display established connection
function connect_establish () {

	# Set BCLD_IF if it exists
	export BCLD_IF="$(/usr/sbin/ip route | /usr/bin/grep -v 'linkdown' | /usr/bin/grep -m1 'default' | /usr/bin/awk '{ print $5 }')"

	# If there is no DHCP_LEASE AND no BCLD_IF, shutdown
	if [[ ! -s "${DHCP_LEASE}" ]] && [[ -z "${BCLD_IF}" ]]; then
		list_item_fail "Unable to connect to any networks!"
		last_item
		trap_shutdown 'net'
	else
		# Display BCLD_IF
		list_item_pass "Connection established on: ${BCLD_IF}"

		# Detect MAC and IP for connection for BCLD_IF
		ip_link
	fi
}

## Function to enable Wake-on-LAN (if supported)
function enable_wol () {

	if [[ -n "${BCLD_IF}" ]]; then
		
		list_item 'Default interface found for WOL...'
		
		# Check if WOL is supported and enable only when so
		if  [[ $(/usr/bin/sudo /usr/sbin/ethtool "${BCLD_IF}" | /usr/bin/grep -c 'Supports Wake-on') -gt 0 ]]; then

			list_item_pass "Wake-on-LAN supported on: ${BCLD_IF}" 
			
			/usr/bin/sudo /usr/sbin/ethtool --change "${BCLD_IF}" wol g && list_item 'Wake-on-LAN enabled!'

		else
			list_item_fail "Wake-on-LAN is not supported on this system..."
		fi

	else
		list_item_fail "No default interface for WOL..."
	fi
}

## Function that loops through the sinks in SINKS_JSON and lists them on the screen
function detect_sinks_and_ports () {

    COUNT_DETECTED_SINKS="$(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq length)"
    SINK_ENTRIES="$(( $(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq length) -1))"

    # List counted sinks if not empty
    if [[ -n "${COUNT_DETECTED_SINKS}" ]]; then
    	list_item "${COUNT_DETECTED_SINKS} sinks detected."
    fi

    SINK_INDEX=0
    while [[ "${SINK_INDEX}" -le "${SINK_ENTRIES}" ]]; do

        # Get sink name
        SINK_NAME="$(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq -r ".[${SINK_INDEX}] | .name")"
        list_item "Sink detected: ${SINK_NAME}"
        
        # Get number of port entries
        PORT_NUM="$(( $(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq ".[${SINK_INDEX}] | .ports" | /usr/bin/jq length) -1))"

        PORT_INDEX=0
        while [[ "${PORT_INDEX}" -le "${PORT_NUM}" ]]; do
        
            # Get port name
            PORT_NAME="$(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq -r ".[${SINK_INDEX}] | .ports | .[${PORT_INDEX}] | .name")"
            
            list_item_pass "Port detected: ${PORT_INDEX}: ${PORT_NAME}"
            
            (( PORT_INDEX++ ))
        done

        (( SINK_INDEX++ ))
    done
}

## Function to launch, enables users to read feedback if too fast
function launch () {
	last_item 'Launching BCLD...'
	(/usr/bin/sleep 3s) && /usr/bin/bash -c "${BCLD_LAUNCH_COMMAND}"
}

## Function to start app
function init_app () {

    # The app must be installed
    if [[ -x $(/usr/bin/which "${BCLD_RUN}") ]]; then
        
        if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
    		# Set BCLD_LAUNCH_COMMAND (verbose)
        	export BCLD_LAUNCH_COMMAND="startx openbox-session"
    	else
    		# Set BCLD_LAUNCH_COMMAND (hide)
    		export BCLD_LAUNCH_COMMAND="startx openbox-session &> /dev/null"
        fi
        
        if [[ "${BCLD_MODEL}" == 'test' ]] \
            && [[ -f "${BCLD_TEST}" ]]; then
	    	# TEST needs to save ENVs for other TTYs (remote)
	    	write_ENVs
	    	
	    	# Only TEST can escape the app and reset the terminal
	    	launch
	        reset_terminal
        else
            # If not TEST, launch the app normally but shutdown if it halts
            launch
            /usr/sbin/poweroff
        fi

    else
        list_item_fail "App not found!"
        last_item "Please check contents of /opt..."
    fi
}

# EXE
## Configurations
list_header "Configuring BCLD"

## PACTL
list_item "Waiting for Pulse daemon to start"
print_item "Scanning sound cards (please wait)"

# pactl does not work inside a VM
if [[ $(/usr/bin/systemd-detect-virt) == 'none' ]]; then
    # Give systems time to start Pulse Audio
    for scan in $(/usr/bin/seq 1 20); do
        /usr/bin/pactl get-default-sink | /usr/bin/grep -qv null && break
        /usr/bin/printf "." && /usr/bin/sleep 1s
    done

    # When started, we can now use Pulse Audio controls
    export BCLD_SINKS="$(/usr/bin/pactl list short sinks  | /usr/bin/awk '{ print $2 }' )"
    
    # If no BCLD_SINKS can be found, or if PA sets it to (auto_)null, trap_shutdown with snd
    if [[ -z "${BCLD_SINKS}" ]] \
        || [[ "${BCLD_SINKS}" == 'null' ]] \
        || [[ "${BCLD_SINKS}" == 'auto_null' ]]; then
        trap_shutdown 'snd'
    else
        /usr/bin/echo
        list_item_pass "Sinks detected: ${BCLD_SINKS}"
    fi
    # SINKS found with pactl and output in JSON. Used throughout code
    SINKS_JSON="$(/usr/bin/pactl --format json list sinks)"
else
    /usr/bin/echo
    list_item_fail "Virtual machine detected, skipping..."
fi

# This is allowed to detect 0 sinks when running inside VM
export SINKS_NUM=$(/usr/bin/echo "${BCLD_SINKS}" | /usr/bin/wc -l)

## Read BCLD_VERBOSE first
readparam "${VERBOSE_PARAM}" "${VERBOSE_ALIAS}"

## Read BCLD_VENDOR next
read_vendor_param

## Machine-id
set_machine_id # Set machine-id

## Set hostname using BCLD_VENDOR and relog (need machine-id)
reset_bcld_hostname

## Source bcld_vendor.sh script for BCLD_OPTS and NSSDB exports using BCLD_VENDOR
source /usr/bin/bcld_vendor.sh

## Read the rest of the parameters here.
read_all_params

## Check Realtek modules, requires sudos and BCLD_REALTEK
realtek_modules

## Check if running BCLD Nvidia
nvidia_modules

## ALTERNATE MODES
if [[ ${BCLD_MODEL} != 'release' ]]; then
    # If not RELEASE, enable DEBUG port (also for TEST)

    export BCLD_OPTS="${BCLD_OPTS} --remote-debugging-port=${APP_DEBUG_PORT}"

	# Check if CLIENT_DEBUG_PORT in use
    if [[ $(/usr/bin/ss -ptln | /usr/bin/grep -c ${CLIENT_DEBUG_PORT}) -eq 0 ]]; then
        list_item "Setting remote port: ${CLIENT_DEBUG_PORT}"
        /usr/bin/socat TCP-Listen:${CLIENT_DEBUG_PORT},fork TCP:127.0.0.1:${APP_DEBUG_PORT} &
        list_item "Remote port set!"
    fi

fi

## Allow password only for TEST, since only TEST has SSH
if [[ "${BCLD_MODEL}" == 'test' ]] \
    && [[ -f "${BCLD_TEST}" ]]; then
    /usr/bin/sudo /usr/sbin/usermod --password "$(/usr/bin/echo ${BCLD_SECRET} | openssl passwd -1 -stdin)" "${BCLD_USER}"
fi

### Generic Configurations

#### Set local time
list_item "Setting RTC to local time..."
/usr/bin/sudo /usr/bin/timedatectl set-local-rtc 1

#### Darken XTerm output unless enabled
if [[ ${BCLD_VERBOSE} -eq 1 ]]; then
	# Use alternate config for BCLD_VERBOSE
	list_item_pass "BCLD_VERBOSE set to: ${BCLD_VERBOSE}"
	/usr/bin/cp "${XT_DIR}/XTerm.white" "${HOME}/XTerm"
else
	# Use default config without BCLD_VERBOSE
	list_item "BCLD_VERBOSE set to: ${BCLD_VERBOSE}"
	/usr/bin/cp "${XT_DIR}/XTerm.black" "${HOME}/XTerm"
fi

#### Configure BCLD Big Mouse
if [[ "${BCLD_MOUSE}" -eq 1 ]] && [[ -f "${HOME}/big-cursor.pcf.gz" ]]; then
	list_item_pass "Setting BCLD Big Mouse: ${BCLD_MOUSE}"
    /usr/bin/cp "${HOME}/big-cursor.pcf.gz" /usr/share/fonts/X11/misc/cursor.pcf.gz && list_item 'BCLD Big Mouse enabled!'
fi


### Vendor Configurations
if [[ ${BCLD_VENDOR} == 'vendorless' ]]; then
    # Vendor features don't work without the BCLD app
    # Unset BCLD_OPTS if running Vendorless BCLD    
    unset 'BCLD_OPTS'
    
    # Configure Vendorless URL if not set
    if [[ "$(/usr/bin/grep -c "${VENDORLESS_PARAM}" "${QT_CONFIG}")" -eq 0 ]]; then
        if [[ -n "${BCLD_URL}" ]]; then
            list_item "Adding BCLD_URL to BCLD_OPTS..."
            list_entry
	        /usr/bin/echo -e "${VENDORLESS_PARAM} = \"${BCLD_URL}\"" | /usr/bin/tee -a "${QT_CONFIG}"
	        list_catch
        else
            list_item "Using default BCLD URL..."
            list_entry
            /usr/bin/echo -e "${VENDORLESS_PARAM} = \"${BCLD_DEFAULT_URL}\"" | /usr/bin/tee -a "${QT_CONFIG}"
            list_catch
        fi
    fi
else
    # Configure BCLD Overwrite URL
    if [[ -n "${BCLD_URL}" ]]; then
	    export BCLD_OPTS="${BCLD_OPTS} --facet-overwrite-url=${BCLD_URL}"
	    list_item_pass "BCLD_URL added to BCLD_OPTS"
    fi

    # Configure BCLD Zoom
    if [[ "${BCLD_ZOOM}" -eq 1 ]]; then
	    export BCLD_OPTS="${BCLD_OPTS} --zoom"
	    list_item_pass "ZOOM added to BCLD_OPTS"
    fi

    # Configure BCLD Shutdown Timer
    if [[ "${BCLD_SHUTDOWN}" -gt 0 ]]; then
	    export BCLD_OPTS="${BCLD_OPTS} --shutdown-timer=${BCLD_SHUTDOWN}"
	    list_item_pass "SHUTDOWN added to BCLD_OPTS"
    fi
fi

### Show BCLD_OPTS
list_item "Current BCLD_OPTS: ${BCLD_OPTS}"

## Audio settings

### Reload Alsa to fix potential problems with module latency
if [[ ${BCLD_ALSA_RESTORE} -eq 1 ]]; then
	list_item "Restoring ALSA configuration..."
	list_entry
	/usr/bin/sudo /usr/sbin/alsactl restore
	list_catch
fi

### Detect sinks
detect_sinks_and_ports

### Sink (always exclusive)
if [[ ${BCLD_SINK} ]]; then
    list_item "Setting BCLD audio sink..."
    /usr/bin/pactl set-default-sink "${BCLD_SINK}" \
        || list_item "BCLD_SINK: ${BCLD_SINK} not found!"
    unset BCLD_COMBINE
fi

### Combined sinks
if [[ ${BCLD_COMBINE} = 1 ]]; then
    
    list_item "Combining BCLD sinks..."
    
    /usr/bin/pactl load-module module-combine-sink sink_name=combined
    /usr/bin/pacmd set-default-sink combined
fi

### ALSA configurations

# check if BCLD_ALSA_SINK and BCLD_ALSA_PORT contain a value
if [[ ! -z "${BCLD_ALSA_SINK}" ]] && [[ ! -z "${BCLD_ALSA_PORT}" ]]; then
    SINK_INDEX=0
    
    # check for SINK and PORT combinations
    # this is to prevent overriding the SINK and PORT when PXE booting
    while [[ "${SINK_INDEX}" -le "${SINK_ENTRIES}" ]]; do

        if [[ $(/usr/bin/echo ${SINKS_JSON} | /usr/bin/jq -r ".[${SINK_INDEX}] | .name") == "${BCLD_ALSA_SINK}" ]]; then
            
            # We are in the correct sink
            PORT_INDEX=0
            PORT_ENTRIES="$(( $(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq ".[${SINK_INDEX}] | .ports" | jq length) -1))"
            while [[ "${PORT_INDEX}" -le "${PORT_ENTRIES}" ]]; do

                if [[ $(/usr/bin/echo "${SINKS_JSON}" | /usr/bin/jq -r ".[${SINK_INDEX}] | .ports | .[${PORT_INDEX}] | .name") == "${BCLD_ALSA_PORT}" ]]; then
                    # Port exists in this sink, forcing alsa to use this sink now.
                    /usr/bin/pacmd set-sink-port "${BCLD_ALSA_SINK}" "${BCLD_ALSA_PORT}"
                fi
                
            (( PORT_INDEX++ ))
            done
        fi
        
        (( SINK_INDEX++ ))
    done
fi

### Output
if [[ ${BCLD_VOL} ]]; then
    list_item "Setting BCLD output volume: ${BCLD_VOL}%"

	# Use overamplication for pactl (boost over 100%)
    BCLD_VOL_EDIT=$(( "${BCLD_VOL}" * "${PACTL_DEFAULT_VOL}" / 100 ))
    /usr/bin/pactl set-sink-volume @DEFAULT_SINK@ "${BCLD_VOL_EDIT}%"
else
	# If BCLD_VOL is not set, set default to overamplify
	list_item "Boosting default volume: ${PACTL_DEFAULT_VOL}%"
    /usr/bin/pactl set-sink-volume @DEFAULT_SINK@ "${PACTL_DEFAULT_VOL}%"
fi

### Input
if [[ ${BCLD_SOURCE} ]]; then
    list_item "Setting BCLD audio source..."
    /usr/bin/pactl set-default-source "${BCLD_SOURCE}" \
        || list_item "BCLD_SOURCE: ${BCLD_SOURCE} not found!"
fi

### Recording Volume
if [[ ${BCLD_REC} ]]; then
    list_item "Setting BCLD recording volume: ${BCLD_REC}%"

	# Use overamplication for pactl (boost over 100%)
    BCLD_REC_EDIT=$(( "${BCLD_REC}" * "${PACTL_DEFAULT_REC}" / 100 ))
    /usr/bin/pactl set-source-volume @DEFAULT_SOURCE@ "${BCLD_REC_EDIT}%"
else
	# If BCLD_REC is not set, set default
	list_item "Setting BCLD recording volume to default: ${PACTL_DEFAULT_REC}%"
    /usr/bin/pactl set-source-volume @DEFAULT_SOURCE@ "${PACTL_DEFAULT_REC}%"
fi


## Network

### Always disable WWAN if BCLD_WWAN is NOT equal to 1
# Leave WWAN enabled only if BCLD_WWAN is equal to 1
if [[ "${BCLD_WWAN}" -ne 1 ]]; then
	list_item "Disable WWAN adapter (if present)..."
	/usr/bin/wwan off &> /dev/null
else
    list_item_pass "WWAN parameter detected!: Leaving enabled..."
fi

### Attempt wired connection, then failover to WiFi
if [[ -n ${BCLD_SSID} ]]; then
    
	# Attempt WiFi connection if SSID is set
    list_item "Wireless settings detected..."
    
    ssid_decoded="$(/usr/bin/echo "${BCLD_SSID}" | base64 -d)"
    
    ### Set default interface

	list_item "Setting default wireless interface..."
	    
    conns=0
    attempt=1
    
    # As long as there are no connections, keep trying for SCAN_TRIES.
    while [[ "${conns}" -lt 1 ]]; do
        list_item "Checking wireless networks...(attempt: #${attempt})"
        conns=$(($(/usr/bin/nmcli device wifi list | /usr/bin/wc -l) - 1))
        ((attempt++))

		# Break out after SCAN_TRIES
        if [[ "${attempt}" -eq "${SCAN_TRIES}" ]]; then
        	list_item_fail "Tried ${attempt} times... Giving up."
        	break
    	fi

    done
    
    # If any connections are found, use detected parameters
    if [[ "${conns}" -gt 0 ]]; then
        list_item_pass "Connections found: ${conns}"
        list_entry
        /usr/bin/nmcli device wifi list | /usr/bin/head -11
        list_catch
	    
		# Attempt to connect to SSID
		if [[ $(/usr/bin/nmcli device wifi list | /usr/bin/grep -co "${ssid_decoded}") -gt 0 ]]; then
		list_item_pass "Found selected wireless network: ${ssid_decoded}..."
		
			if [[ -n ${BCLD_PSK} ]]; then
				# Attempt WPA-PSK if parameters are set:
				connect_psk
			elif [[ -n ${BCLD_EAP_METHOD} ]] && [[ -n ${BCLD_EAP_USER} ]] && [[ -n ${BCLD_EAP_PW} ]]; then
				# Attempt PEAP if parameters are set:
				connect_eap
			else
				# Connect to wired if two other methods fail
				detect_lan
		    fi
		    
		else
		    list_item_fail "Selected wireless network '${ssid_decoded}' not available!"
		    # Connect to wired if SSID can't be found
			detect_lan
		fi
		
    else
        list_item_fail "No connections found!"
        # Connect to wired if WiFi is not working
		detect_lan
    fi
else
    # Attempt wired connection if SSID is not set
    list_item "No wireless settings detected..."
	detect_lan
fi

### Shutdown if no leases at all
connect_establish

### Rsyslogger
# TODO Start Rsyslogger before WOL, because it somehow disables it...
# Enable by default
if [[ "${BCLD_RSYSLOG}" == 'true' ]]; then
	list_item_pass "BCLD_RSYSLOG set to \"${BCLD_RSYSLOG}\", enabling!"
	source /usr/bin/log_tools.sh
	log_header 'Rsyslogging enabled!'
	/usr/bin/rsyslogger.sh &
fi

### Wake-on-LAN
# Only do this if BCLD_WOL is not disabled
if [[ "${BCLD_WOL}" -eq 1 ]]; then
	# Never do this more than once
	# Check if an interface is selected
	list_item_pass "WOL parameter detected!"
	/usr/bin/sudo /usr/bin/systemctl --quiet disable --now wol.service && list_item "WOL disabled..."
else
	enable_wol
fi

## Important umounts before logging
bcld_umount

# Startup application
init_app
