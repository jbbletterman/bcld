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
# BCLD Chroot script
# This script configures the freshly bootstrapped chroot environment
# on the build agent.

set -e

# shellcheck source=./root/BUILD.conf
BUILD_CONF='/root/BUILD.conf'
ECHO_TOOLS='/usr/bin/echo_tools.sh'

source "${ECHO_TOOLS}" \
    && list_item "Echo tools loaded!"

source "${BUILD_CONF}" \
    && list_item "Build config loaded!" \
    && list_entry \
    && /usr/bin/cat "${BUILD_CONF}"

# ENVs
BCLD_ROOT='/root'
BCLD_MOUNT='/media/BCLD-USB'
CHROOT_RM='/opt/remotelogging'
CHSURFACE_APT='/etc/apt/sources.list.d/linux-surface.list'
CHSURFACE_KEY='/etc/apt/trusted.gpg.d/linux-surface.gpg'
SSHD="/etc/ssh/sshd_config.d/10-BCLD.sh"
SUDOERS="/etc/sudoers"

# VARs
BCLD_HOME="/home/${BCLD_USER}"
NSSDB="${BCLD_HOME}/.pki/nssdb"
APP_PKGS="${BCLD_ROOT}/APP"
CHROOT_PKGS="${BCLD_ROOT}/CHROOT"
PKGS_ALL="${BCLD_ROOT}/PKGS_ALL"
LOG_FILE="${BCLD_ROOT}/APT_LOG.log"
REMOVE="${BCLD_ROOT}/REMOVE"
SELECTIONS="${BCLD_ROOT}/selections.conf"

# ENVs
DEB_COUNT=$(/usr/bin/find "${APP_DIR}" -type f -name '*.deb' | wc -l)
DEFAULT_TARGET='graphical'

TAG="RUN-CHROOT"

## Functions

# Function to remove files if they exist
function clear_file () {
    if [[ -f ${1} ]]; then
        list_item "Cleaning up file: ${1}"
        /usr/bin/rm -f "${1}"
    fi
}

# Function to create sudoer
function add_user () {
    /usr/sbin/useradd -rmo \
        --uid 999 \
        --groups adm,cdrom,sudo,dip,plugdev,video \
        --shell /bin/bash \
        --password "${BCLD_SECRET}" \
        "${1}"
    list_item "Added \"${1}\" to 'sudo'..."
    list_item "Added \"${1}\" with GID '999'..."
    list_item "Added \"${1}\" with 'bash' shell..."
    /usr/bin/echo "${1} ALL=(ALL) NOPASSWD:ALL" >> "${SUDOERS}"
    list_item "Added \"${1}\" to sudoers file..."
}

# Set password with OpenSSL
function set_passwd () {
    list_header "Setting user password for: ${1}"
    /usr/sbin/usermod --password "$(/usr/bin/echo "${2}" | openssl passwd -1 -stdin)" "${1}"
}


### Install packages ###

# Add critical packages to bootstrapped image
/usr/bin/apt-get update && /usr/bin/apt-get install -y curl gpg

# Linux Surface repo
/usr/bin/curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc \
    | /usr/bin/gpg --dearmor | /usr/bin/dd of="${CHSURFACE_KEY}"

/usr/bin/echo 'deb [arch=amd64] https://pkg.surfacelinux.com/debian release main' > "${CHSURFACE_APT}"

list_item 'Checking Linux Surface GPG key...'
if [[ -f ${CHSURFACE_KEY} ]] \
    && [[  "$(/usr/bin/wc -l < "${CHSURFACE_KEY}")" -gt 0 ]]; then
    list_item_pass "Linux Surface GPG key found! $(/usr/bin/md5sum "${CHSURFACE_KEY}" | /usr/bin/awk '{ print $1 }')"
    list_entry
    /usr/bin/gpg --list-keys --keyring "${CHSURFACE_KEY}"
    /usr/bin/gpg --fingerprint --keyring "${CHSURFACE_KEY}"
    list_catch
else
    list_item_fail 'Linux Surface GPG key NOT found!'
    exit 1
fi

# Update using the selected mirror
list_header "Updating packages"

## Only works if /tmp is accessible
/usr/bin/chmod 1777 /tmp

list_entry
/usr/bin/apt-get update -y
/usr/bin/apt-get upgrade -y

# Configure dpkg first for auto keyboard
list_header "Configuring DPKG (essentials)"
list_entry
/usr/bin/apt-get install -yq --no-install-recommends $(/usr/bin/cat ${CHROOT_PKGS}) | /usr/bin/tee -a "${LOG_FILE}"
debconf-set-selections < "${SELECTIONS}"

## Refresh repositories and check certificates
/usr/sbin/update-ca-certificates

# Start installing
list_header "APT installations"
list_entry
/usr/bin/apt-get install -yq --no-install-recommends $(/usr/bin/cat ${PKGS_ALL}) | /usr/bin/tee -a "${LOG_FILE}"

## Install extra packages
if [[ -n "${BCLD_PKG_EXTRA}" ]]; then
	list_header "Found extra packages: ${BCLD_PKG_EXTRA}"
	list_entry
	/usr/bin/apt-get install -yq --no-install-recommends "${BCLD_PKG_EXTRA}" | /usr/bin/tee -a "${LOG_FILE}"
fi


### Uninstall packages ###

## If there is a REMOVE file, use it.
if [[ -f ${REMOVE} ]]; then
    list_header "REMOVE file detected, excluding packages"
    list_entry
    /usr/bin/cat "${REMOVE}"
    list_catch
    list_entry
    /usr/bin/apt-get remove -yq --purge $(/usr/bin/cat ${REMOVE}) | /usr/bin/tee -a "${LOG_FILE}"
fi


# Configurations
list_header "Configurations"

## User/Run Level/Target, het is complex...
list_item "Default Target: ${DEFAULT_TARGET}"
list_entry
/usr/bin/systemctl enable "${DEFAULT_TARGET}.target"
/usr/bin/systemctl set-default "${DEFAULT_TARGET}.target"
list_catch

## User Management
list_item "User Management: \"${BCLD_USER}\""

if [[ -n ${BCLD_USER} ]]; then
    add_user "${BCLD_USER}"
else
    last_item "BCLD_USER is not set!"
    on_failure
fi

## USB-logger
list_item "Enable USB-logger by default"
list_entry
/usr/bin/mkdir -pv "${BCLD_MOUNT}"
list_catch
list_item "Enabling USB-logger service..."
list_entry
/usr/bin/systemctl enable BCLD-USB.service
list_catch

## Chrome Dump
list_item "Enable BCLD-crosdump.service to catch Chrome dumps"
list_item "Enabling Chromium dump logger service..."
list_entry
/usr/bin/systemctl enable BCLD-crosdump.service
list_catch

## Rsyslog
list_item "Creating: ${CHROOT_RM} for Rsyslog"
list_entry
/usr/bin/mkdir -v "${CHROOT_RM}"
list_catch

## Xauth
# Broken
#list_item "Configuring Xauth..."
#/usr/bin/xauth -v generate :0 . trusted 
#/usr/bin/xauth -v add ${HOST}:0 . $(xxd -l 16 -p /dev/urandom)

## Configure BCLD Big Mouse
BIG_MOUSE="$(mktemp --directory --suffix=_BCLD-BIG-MOUSE)"
list_item "Configuring BCLD Big Mouse™️ inside: ${BIG_MOUSE}"
list_entry
/usr/bin/chown -Rv _apt "${BIG_MOUSE}"
cd "${BIG_MOUSE}"
/usr/bin/apt-get download -y big-cursor
/usr/bin/ar -xv big-cursor*.deb
/usr/bin/zstd -d data.tar.zst
/usr/bin/tar -xf data.tar
/usr/bin/cp "${BIG_MOUSE}/usr/share/fonts/X11/misc/big-cursor.pcf.gz" "/home/${BCLD_USER}"
cd -
list_catch

## Unattended Security upgrades
list_item "Set DPKG to unattended..."
/usr/bin/echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# This is where the Chrome apps will be pulled from Nexus
if [[ ${DEB_COUNT} -gt 0 ]]; then
    # Look for any Chrome apps inside APP_DIR
    list_item "${DEB_COUNT} DEBs found in ${APP_DIR}! Installing..."
    list_entry
    /usr/bin/apt-get clean
	
	# Install any DEBs found in APP_DIR
    /usr/bin/find "${APP_DIR}" -type f -name '*.deb' -exec /usr/bin/apt-get install -fy {} \; -quit
	
	# Change ownership of /opt to the BCLD_USER
    /usr/bin/chown -Rv "${BCLD_USER}":"${BCLD_USER}" /opt
	
	# Cleanup the DEB dir
    /usr/bin/rm -rfv "${APP_DIR}"
    list_catch
elif [[ -z "${APP_PKGS}" ]]; then
    list_item_fail "${APP_PKGS} cannot be empty!"
    on_failure
else
    # If there are no DEBs, use APP packages instead
    list_item "No DEBs found in APP_DIR, using: ${APP_PKGS}"
    list_entry
    /usr/bin/apt-get install -yq --no-install-recommends $(/usr/bin/cat "${APP_PKGS}")
    list_catch
fi

## Configure Avahi
list_item "Disable resolvconf (for Avahi)"
# Since we are going with Avahi, disable resolveconf
#/usr/bin/systemctl disable --now systemd-resolved.service
clear_file '/lib/systemd/system/systemd-resolved.service' 'Removing resolv.conf service...'
clear_file '/etc/resolv.conf' 'Removing resolv.conf file...'

## Configure firewall
list_item "Configuring firewall settings"

### Flush defaults
list_item "Flushing defaults..."
/usr/sbin/iptables -F

### Save settings
list_item "Saving firewall configurations..."
list_entry
/usr/sbin/netfilter-persistent save
list_catch

## Reload libraries
/usr/sbin/ldconfig

## Configure Plymouth
list_item "Configuring Plymouth Spinner..."
list_entry
/usr/bin/update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/spinner/spinner.plymouth 200
list_catch

# MODEL packs
if [[ ${BCLD_MODEL} = 'test' ]]; then
    list_item "BCLD_MODEL set to: ${BCLD_MODEL}"
    last_item 'Configuring OpenSSH Server...'
    /usr/bin/echo 'PasswordAuthentication yes' >> "${SSHD}"
    /usr/bin/echo 'X11Forwarding yes' >> "${SSHD}"
    /usr/bin/systemctl enable ssh.service
fi

# Cleanup
list_header "Cleanup"

## Remove all the package lists...
clear_file "${CHROOT_PKGS}"
clear_file "${APP_PKGS}"
clear_file "${PKGS_ALL}"
clear_file "${REMOVE}"
clear_file "${SELECTIONS}"

## Clean APT and history
list_item "Cleaning APT..."
list_entry
/usr/bin/apt-get autoremove -yq | /usr/bin/tee -a "${LOG_FILE}"
/usr/bin/apt-get clean
history -c
list_catch

## Clear chroot logs
list_item "Cleaning chroot logs..."
list_entry
/usr/bin/rm -fv ${CHROOT_DIR}/root/*.log
list_exit
