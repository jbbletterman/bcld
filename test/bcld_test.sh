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
# BCLD Test
# Script for implementing useful functions in BCLD TEST images

# In TEST, this has not been sourced yet, 
# because we're not running `startup.sh` (again)
source '/usr/bin/echo_tools.sh'

# ENVs
export BCLD_VERBOSE=1
export NSSDB="${HOME}/.pki/nssdb"

# VARs
ENV_FILE="/etc/environment"
BCLD_ENV="${HOME}/BCLD_ENVs"

# FUNCTIONS

## Function to check audio devices
function BCLD_AUDIO () {
	/usr/bin/lspci -v | /usr/bin/grep -A7 -i 'audio'
	/usr/bin/echo
	/usr/bin/aplay --list-devices
}

## Function to display battery in TEST console
function BCLD_BAT () {
        # Check laptop battery, if present
		if [[ -d /sys/class/power_supply/BAT0 ]]; then
			list_item_pass "Laptop battery: $(/usr/bin/cat /sys/class/power_supply/BAT0/capacity)"
		fi
}

## Function to check this script
function BCLD_CMDs () {
	declare -F | /usr/bin/grep -v 'command_not_found_handle' | /usr/bin/awk '{ print $3 }'
}

## Function to display BCLD certificates
function BCLD_CERTs () {
    CA_HASH="$(/usr/bin/openssl x509 -in /etc/ssl/certs/ca.crt -noout -hash)"
	CA_DATE="$(/usr/bin/openssl x509 -in /etc/ssl/certs/ca.crt -noout -enddate | /usr/bin/cut -d '=' -f2)"

    CERT_HASH="$(/usr/bin/openssl x509 -in /etc/ssl/certs/bcld.crt -noout -hash)"
	CERT_DATE="$(/usr/bin/openssl x509 -in /etc/ssl/certs/bcld.crt -noout -enddate | /usr/bin/cut -d '=' -f2)"
	
	list_header 'Checking BCLD certificates'
	list_item "CA certificate: ${CA_HASH}"
	list_item "EXPIRES: ${CA_DATE}"
	list_entry
	/usr/bin/openssl x509 -in /etc/ssl/certs/ca.crt -noout -subject
	list_catch
	list_item "Client certificate: ${CERT_HASH}"
	list_item "EXPIRES: ${CERT_DATE}"
	list_entry
	/usr/bin/openssl x509 -in /etc/ssl/certs/bcld.crt -noout -subject
	list_catch
	list_item 'Checking NSSDB certificates...'
	list_entry
	/usr/bin/certutil -d "sql:${NSSDB}" -L
	list_catch
	list_exit
	/usr/bin/echo
}

## Function to display BCLD keys
function BCLD_KEYs () {
	KEY_STATE="$(/usr/bin/openssl rsa -in /etc/ssl/certs/bcld.key -noout -check)"
	
	list_header 'Checking BCLD keys'
	list_item "Client key: ${KEY_STATE}"
	list_entry
	/usr/bin/certutil -d "sql:${NSSDB}" -K
	list_catch
	list_exit
	/usr/bin/echo
}

## Function to display BCLD variables
function BCLD_ENVs () {
	/usr/bin/echo
	/usr/bin/printenv | /usr/bin/grep '^BCLD' | /usr/bin/sort
	/usr/bin/echo
}

## Function to check default target
function BCLD_FAO () {
	/usr/bin/echo "{\"url\":\"https://"${1:-$BCLD_FAO}"/facet-player-assessment/player/afname/control\",\"protocol\":\"https:\",\"hostAndPort\":\""${1:-$BCLD_FAO}"\",\"hostname\":\""${1:-$BCLD_FAO}"\",\"port\":\"\"}" > /opt/remotelogging/input.json
}

## Function to check default target
function BCLD_JRN () {
	/usr/bin/journalctl -f --no-pager
}

## Function to logout after a few seconds
function logout_timer () {
	last_item "Relogging for changes to take effect..."
	/usr/bin/sleep 5s && logout
}

## Function to add ENVs
function BCLD_PARAM () {
	 /usr/bin/echo "${1}=${2}" | /usr/bin/sudo /usr/bin/tee -a "${ENV_FILE}"
	 list_header "ADDED NEW ENV: ${1}=${2}"
	 logout_timer
}

## Alias for BCLD_ENVs
function BCLD_PARAMs () {
	 BCLD_ENVs
}

## Function to quickly swap out URL
function BCLD_URL () {
	 BCLD_PARAM BCLD_URL "${1}"
}

## Function for switching parameters on or off during session
function BCLD_PARAM_SWITCH () {
	if [[ -n "${1}" ]]; then
	
		list_header "Switching parameter: ${1}"
		if [[ "$(/usr/bin/grep -c "${1}" "${ENV_FILE}")" -gt 0 ]]; then
			PARAM_VALUE=$(/usr/bin/grep "${1}" "${ENV_FILE}" | cut -d '=' -f2)    
			list_item_pass "Parameter detected! Value: ${PARAM_VALUE}"
			
			if [[ ${PARAM_VALUE} -eq 1 ]]; then
				/usr/bin/sudo /usr/bin/sed -i "s|${1}=1|${1}=0|g" "${ENV_FILE}"
				last_item 'Set to 0' && logout_timer
			elif [[ ${PARAM_VALUE} -eq 0 ]]; then
				/usr/bin/sudo /usr/bin/sed -i "s|${1}=0|${1}=1|g" "${ENV_FILE}"
				last_item 'Set to 1' && logout_timer
			fi

		else
			list_item "${1} parameter not detected."
			list_item_pass "Initializing to \"disabled\"..."
			echo "${1}=0" | /usr/bin/sudo /usr/bin/tee -a ${ENV_FILE} && logout_timer
		fi
	fi
}

## Function to check BCLD logs
function BCLD_LOGs () {
	/usr/bin/pager /var/log/bcld.log
}

## Function to check Xorg logs
function BCLD_X_LOGs () {
	/usr/bin/cat ${HOME}/.local/share/xorg/Xorg.0.log | /usr/bin/grep -E 'EE|WW'
}

## Fast remount
function BCLD_MOUNT () {
	/usr/bin/sudo /usr/bin/mount /dev/disk/by-label/BCLD-USB /mnt
	cd /mnt || exit
	/usr/bin/ls
}

## Function to display NSSDB status in TEST console
function BCLD_NSSDB () {
    if [[ -d "${NSSDB}" ]]; then
        # Check NSSDB settings
	    # ENVs
	    FACET_DOM='facet.onl'
	    WFT_DOM='duo.nl'
		    
		# Check certificate
	    if [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -L | /usr/bin/grep -c "${FACET_DOM}")" -gt 0 ]]; then
	    	print_cert "${FACET_DOM}"
	    elif [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -L | /usr/bin/grep -c "${WFT_DOM}")" -gt 0 ]]; then
	    	print_cert "${WFT_DOM}"
    	else
			list_item_fail 'CERT ERROR!'
		fi
		
		# Check key        
	    if [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -K | /usr/bin/grep -c "${FACET_DOM}")" -gt 0 ]]; then
	    	print_key "${FACET_DOM}"
	    elif [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -K | /usr/bin/grep -c "${WFT_DOM}")" -gt 0 ]]; then
	    	print_key "${WFT_DOM}"
		else
			list_item_fail 'KEY ERROR!'
	    fi
    else
		list_item_fail "NSSDB not found! Are you running vendorless?"
    fi
}

## Function to get or set BCLD recording level
function BCLD_REC () {
	if [[ ${1} ]]; then
		/usr/bin/pactl set-source-volume @DEFAULT_SOURCE@ "${1}%"
	else
		/usr/bin/pactl get-source-volume @DEFAULT_SOURCE@
	fi
}

## Function to check broken services
function BCLD_SERVICES () {
	list_item 'Listing broken services:'
	list_entry
	/usr/bin/systemctl list-units --type=service --state=failed
}

## Function to check default target
function BCLD_TRG () {
	/usr/bin/systemctl get-default
}

## Function to check all targets
function BCLD_TRGs () {
	/usr/bin/systemctl list-units --type target -all
}

## Function to isolate target
function BCLD_TRGt () {
	/usr/bin/systemctl isolate "${1}.target"
}


## Function to follow BCLD-USB status
function BCLD_USB () {
	/usr/bin/journalctl -u BCLD-USB -f
}

## Function to get or set BCLD volume
function BCLD_VOL () {
	if [[ ${1} ]]; then
		/usr/bin/pactl set-sink-volume @DEFAULT_SINK@ "${1}%"
	else
		/usr/bin/pactl get-sink-volume @DEFAULT_SINK@
	fi
}

## Check if WOL supported
function BCLD_WOL () {
	if  [[ $(/usr/bin/sudo /usr/sbin/ethtool "${BCLD_IF}" | /usr/bin/grep -c 'Supports Wake-on') -gt 0 ]]; then
		WOL_MODE="$(/usr/bin/sudo /usr/sbin/ethtool "${BCLD_IF}" | /usr/bin/grep 'Wake-on' | /usr/bin/grep -v 'Supports')"
		list_item_pass "Wake-On-LAN supported! Currently set to: $(/usr/bin/echo ${WOL_MODE} | /usr/bin/tr -d ' ')"
	else
		list_item_fail "Wake-On-LAN IS NOT supported!"
	fi
}

# Output certificate
function print_cert () {
	list_item_pass "Certificate OK: ${1}"
}

# Output key
function print_key () {
	list_item_pass "Key OK: ${1}"
}

## Function to check Secure Boot
function check_sb_state () {
    if [[ "$(/usr/bin/mokutil --sb-state)" ]]; then
        /usr/bin/echo
        /usr/bin/mokutil --sb-state | /usr/bin/grep 'SecureBoot'
        /usr/bin/echo
    fi
}

## Function to perform OpenSCAP OVAL evaluation
function BCLD_OVAL () {
    if [[ -x /usr/bin/oscap ]]; then
        
        OSCAP_REPORT="${HOME}/BCLD_OSCAP_REPORT.html"
        
        list_header 'Starting BCLD OpenSCAP OVAL evaluation'
        
        # Pull OVAL SCAP content from Ubuntu
        list_item 'Getting OVAL content...'
        list_entry
        /usr/bin/curl -O "https://security-metadata.canonical.com/oval/com.ubuntu.$(lsb_release -cs).usn.oval.xml.bz2"
        list_catch
        
        # Unpack
        list_item 'Unpacking OVAL content...'
        /usr/bin/bunzip2 -f "com.ubuntu.$(lsb_release -cs).usn.oval.xml.bz2"
        
        # Generate report
        list_item 'Generating OpenSCAP report, please wait...' && /usr/bin/sleep 2s
        list_entry
        /usr/bin/oscap oval eval --report "${OSCAP_REPORT}" "com.ubuntu.$(lsb_release -cs).usn.oval.xml"
        /usr/bin/sudo /usr/bin/cp -v "${OSCAP_REPORT}" /srv/index.html
        list_catch

        # Host report until cancelled
        list_item_pass "Now hosting OpenSCAP OVAL evaluation on ${BCLD_IP}:8000!"
        cd /srv
        /usr/bin/python3 -m http.server && cd -
    else
        list_item_fail 'Please check if OpenSCAP is installed!'
    fi
}

## Function to reset TEST sessions, RELEASE and DEBUG can never escape the app
function reset_terminal () {

    /usr/bin/reset
    # Show ascii logo
    ascii_logo

    # List Secure Boot state
    check_sb_state
    
    list_header "Resetting terminal"

    list_param "${BCLD_APP_VERSION}" 'App Version'
    list_param "${BCLD_KERNEL_VERSION}" 'Kernel Version'
    list_param "${BCLD_LAUNCH_COMMAND}" 'Launch Command'
    list_param "${BCLD_URL}" 'BCLD Afname URL'
    list_param "${BCLD_OPTS}" 'BCLD options'
    BCLD_NSSDB
    BCLD_BAT
    list_param "${BCLD_IF}" 'Default interface'
    list_param "${BCLD_IP}" 'IP address'
    list_param "${BCLD_MAC}" 'Link address'
    list_param "${BCLD_SPEED}" 'Link speed (Megabytes/s)'
    list_param "${BCLD_DOWNLOAD}" 'Link download (Bytes/s)'
    list_param "${PACKET_LOSS}" 'Packets dropped (so far)'
    
    # List broken services
    BCLD_SERVICES
    
    # List Nvidia state if installed and loaded
    if [[ "${BCLD_NVIDIA}" == 'loaded' ]]; then
        /usr/bin/nvidia-smi
    fi

    list_header "Connect remotely through SSH!: \"ssh -X ${BCLD_USER}@${BCLD_IP}\""
    list_item "To start the app locally, type: \"$BCLD_LAUNCH_COMMAND\""
    last_param "${BCLD_SECRET}" 'Password'
}

## Function to write BCLD_ENVs and update environment
function write_ENVs () {
	
	# Save local ENVs
	list_item "Saving BCLD_ENVs..."
	/usr/bin/printenv | /usr/bin/grep 'BCLD' | /usr/bin/sort -u > "${BCLD_ENV}"
	
	# Add them to /etc/environment
	# Since RELEASE and DEBUG will never respawn a bash shell (kiosk),
	# only TEST uses these (while reconnecing remotely)
	list_entry

	while read ENV_LINE; do
		
		ENV_VALUE=$(/usr/bin/echo "${ENV_LINE}" | /usr/bin/sed 's/=/ /')
        IFS=' ' read -r ENV VALUE <<< "${ENV_VALUE}"
        
		if [[ $(/usr/bin/grep -c "${ENV}" "${ENV_FILE}") -eq 0 ]];then 
			/usr/bin/echo "${ENV}=\"${VALUE}\"" | /usr/bin/sudo /usr/bin/tee -a "${ENV_FILE}" && ((ENVs_NEW++))
		else
			#/usr/bin/echo "  [*] NOT ADDING: ${ENV} (exists)"
			(( ENVs_OLD++ ))
		fi
		
	done <"${BCLD_ENV}"
	
	if [[ ${ENVs_OLD} -gt 0 ]]; then
		/usr/bin/echo "  [x] NOT ADDING: ${ENVs_OLD} EXISTING ENVs!"
	fi
	
	list_catch

	if [[ "${ENVs_NEW}" -gt 0 ]];then
		list_item_pass "Updated ${ENVs_NEW} BCLD_ENVs!"
		unset 'ENVs_NEW'
	else
		list_item "No new BCLD_ENVs..."
	fi
}
