#!/bin/bash

source /usr/bin/echo_tools.sh

TAG='RUN-LIVE'

SUM_ALIAS=('rd.emergency' 'emergency' 'rd.rescue' 'rescue' 'single' 's' 'S' ' 1 ' ' 2 ' ' 3 ' ' 4 ')

# FUNCTIONS

## Flash graphics from a directory
function dir_flasher () {
	/usr/bin/sudo /usr/bin/bash -c "/usr/bin/startx /home/${BCLD_USER}/trap_shutdown/trap_shutdown.sh ${1}"
}

## Trap input and sleep while shutting down
function trap_shutdown () {
    trap '' SIGHUP SIGINT SIGQUIT SIGTERM SIGTSTP
    /usr/bin/clear
    list_header 'EMERGENCY SHUTDOWN'
    
    case "${1}" in
        net)
            list_item "Reason: Unable to connect to any networks!"
            ;;
        param)
            list_item "Reason: Illegal parameter detected!: ${2}"
            ;;
        snd)
            list_item "Reason: Unable to detect any sound cards"
            ;;
        virt)
            list_item "Reason: Virtualization detected!"
            ;;
        *)
            list_item "Reason: unknown!"
            ;;
    esac
    
    list_item_fail 'This is prohibited, shutting BCLD down in 5 seconds...'
	list_entry
	dir_flasher "${1}"
    ( /usr/bin/sleep 5 && /usr/bin/sudo /usr/sbin/shutdown -P now & ) > /dev/null 2>&1
}

# EXE

# Do not allow Single User Mode
for s in "${SUM_ALIAS[@]}"; do

	HITS=$(/usr/bin/cat /proc/cmdline | /usr/bin/grep -wc "${s}")
	
	if [[ ${HITS} -gt 0 ]]; then
		trap_shutdown 'net' "${s}"
		break
	fi
done

# Exit if we detect a VM in RELEASE
if [[ $(/usr/bin/systemd-detect-virt) != 'none' ]]; then

    # Do not allow VM in RELEASE
    if [[ ${BCLD_MODEL} == 'release' ]] \
    	|| [[ $(/usr/bin/grep -ci 'release' /VERSION) -gt 0 ]] \
    	|| [[ $(/usr/bin/hostname | /usr/bin/cut -d '-' -f2 | grep -ci 'release' ) -gt 0 ]]; then
		
		# Shutdown whenever any of these contain 'release'
        trap_shutdown 'virt'
    else
        # Ignore VM-check in other BCLD_MODELs
        list_header 'Virtualization detected, but running in TEST!'
        list_item_pass 'Ignoring...'
        list_exit
    fi
fi

# Force graphical.target to prevent Grub from forcing rescue.target
# This will quickly disconnect all targets and reconnect them
#/usr/bin/systemctl isolate 'graphical.target' #may render remote connections useless

# Check host conditions
if [[ -f "${BCLD_STARTUP_SCRIPT}" ]] \
    && [[ "$(whoami)" == "${BCLD_USER}" ]]; then
        # Default session
        if [[ -z "${DISPLAY}" ]] \
            && [[ "$(tty)" == '/dev/tty1' ]]; then
            source "${BCLD_STARTUP_SCRIPT}" # | logger -t "${TAG}"
            
        # Remote session
        elif [[ "$(tty)" == *"/dev/pts/"* ]] \
        	&& [[ "${BCLD_MODEL}" == 'test' ]]; then
            # DISPLAY does not have to be set when connecting remotely.
            # This will always be a remote session in TEST
            # Add BCLD_REMOTE
            export BCLD_REMOTE='true'
            list_header "Remote login"
            last_item "Loading test tools..."
                        
            # Must manually source test package
            source /usr/bin/bcld_test.sh
            
            # Reset using test pkg
            reset_terminal
        fi
    
else
    list_header "Unable to launch application!"
    list_item "DISPLAY: \"${DISPLAY}\""
    list_item "BCLD_USER must be \"${BCLD_USER}\": \"$(whoami)\""
    list_item "tty: \"$(tty)\""
    last_item "BCLD_STARTUP_SCRIPT: \"${BCLD_STARTUP_SCRIPT}\""
fi
