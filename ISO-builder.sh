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
# ISO Builder
# ISO-builder.sh uses settings in ./config/BUILD.conf and
# packages from ./config/packages/BUILD to prepare a build
# environment and create an ISO image.
#
#
# BUILD INIT
# Check if script is executed in project directory
# Also set critical variables.
if [[ -f "$(pwd)/ISO-builder.sh" ]]; then
        
    PROJECT_DIR="$(pwd)"
    
    CONFIG_DIR="${PROJECT_DIR}/config"
    SCRIPT_DIR="${PROJECT_DIR}/script"
    TOOLS_DIR="${PROJECT_DIR}/tools"
    
    BUILD_CONF="${CONFIG_DIR}/BUILD.conf"
    ECHO_TOOLS="${SCRIPT_DIR}/echo_tools.sh"
    EXPORTER_KIT="${TOOLS_DIR}/EXPORTER-TOOLKIT.sh"
    FILE_OPS="${SCRIPT_DIR}/file_operations.sh"
    
    # Source build tools
    source "${BUILD_CONF}"
    source "${ECHO_TOOLS}"
    source "${FILE_OPS}"
    source "${EXPORTER_KIT}"
    
    TAG='ISO-INIT'

    list_header "Initializing BCLD build"

    # If /dev/zero is missing, we cannot build
    if [[ ! -c /dev/zero ]]; then
        list_item_fail "/dev/zero missing..."
        last_item "Use 'mknod' to generate new device!"
        /usr/bin/mknod /dev/zero c 1 5 
        on_failure
    fi

else
    /usr/bin/echo -e "Please run script inside project directory!\n"
    on_failure
fi

on_completion

# ENVs
CLIENT_CERT_NAME='bcld.crt'
CLIENT_KEY_NAME='bcld.key'
CA_CERT_NAME='ca.crt'
ISO_LABEL="BCLD-ISO"
ISO_NAME='bcld.iso'
MD5_TAG='md5_file'
PKCS_PASS="$(uuidgen)"

## Paths
UBUNTU_BASE=$(basename "${UBUNTU_URL}")

## Config
PROFILE_DIR="${CONFIG_DIR}/bash/profile.d"
PKGS_DIR="${CONFIG_DIR}/packages"
SERVICE_DIR="${CONFIG_DIR}/systemd/system"

## Project Root
ART_DIR="${PROJECT_DIR}/artifacts"
BOOTSTRAP_DIR="${PROJECT_DIR}/bootstrap"
CERT_DIR="${PROJECT_DIR}/cert"
CHROOT_DIR="${PROJECT_DIR}/chroot"
IMG_DIR="${PROJECT_DIR}/image"
LOG_DIR="${PROJECT_DIR}/log"
OPT_DIR="${PROJECT_DIR}/opt"
REPOMAN_DIR="${PROJECT_DIR}/tools/bcld-repo-manager"

CLIENT_NSSDB="${CERT_DIR}/nssdb"

## Chroot
CHETC="${CHROOT_DIR}/etc"
CHAPP_DIR="${CHROOT_DIR}/app/${BCLD_MODEL^^}"
CHOME_DIR="${CHROOT_DIR}/home/${BCLD_USER}"
CHPLY_DIR="${CHROOT_DIR}/usr/share/plymouth"
CHROOT_BIN="${CHROOT_DIR}/usr/bin"
CHROOT_OPT="${CHROOT_DIR}/opt"
CHROOT_ROOT="${CHROOT_DIR}/root"
CHROOT_TMP="${CHROOT_DIR}/tmp"
CHROOT_PKI_DIR="${CHROOT_DIR}/usr/share/ca-certificates"

### Chroot ETC
CHROOT_CHROME_CERT_DIR="${CHETC}/chromium/policies/managed/"
CHENV="${CHETC}/environment"
CHINIT="${CHETC}/init.d"
CHLOGIND="${CHETC}/systemd/logind.conf"
CHNSSDB="${CHOME_DIR}/.pki/nssdb"
CHSERVICE_DIR="${CHETC}/systemd/system"

## IMG DIRs
GRUB_DIR="${IMG_DIR}/boot/grub"
ISO_DIR="${IMG_DIR}/ISO"

IMAGE_GRUB="${GRUB_DIR}/grub.cfg"

## ISO DIRs
DISK_DIR="${ISO_DIR}/.disk"
CASPER_DIR="${ISO_DIR}/casper"
EFI_DIR="${ISO_DIR}/EFI"
ISOLINUX_DIR="${ISO_DIR}/isolinux"

EFI_BOOT_DIR="${EFI_DIR}/BOOT"
EFI_ISO_GRUB="${EFI_BOOT_DIR}/grub.cfg"
ISO_MD5="${ISO_DIR}/${MD5_TAG}"
SQUASHFS="${CASPER_DIR}/filesystem.squashfs"
UBUNTU_DIR="${EFI_DIR}/ubuntu"

### ISOLINUX/Grub artifacts
#### Legacy
BIOS_IMG="${ISOLINUX_DIR}/bios.img"
CORE_IMG="${ISOLINUX_DIR}/core.img"
UBUNTU_GRUB="${UBUNTU_DIR}/grub.cfg"

#### UEFI
#BOOT_EFI="${EFI_BOOT_DIR}/bootx64.efi"
EFI_IMG="${EFI_BOOT_DIR}/efi.img"

### Dummy Repo dirs
REPO_DIR="${ISO_DIR}/dists/${CODE_NAME}"
DIST_DIR="${REPO_DIR}/${BCLD_REPO_BRANCH}/binary-amd64"
POOL_DIR="${ISO_DIR}/pool/${BCLD_REPO_BRANCH}"

## Log
BOOTSTRAP_LOG="${LOG_DIR}/bootstrap.log"
CHROOT_LOG="${LOG_DIR}/chroot.log"

## Artifacts
INF_ART="${ART_DIR}/info"
ISO_ART="${ART_DIR}/${ISO_NAME}"
PKG_ART="${ART_DIR}/PKGS_ALL"

### Vars ###
chinitrd="${CHROOT_DIR}/boot/initrd.img-${KERNEL_VERSION}"
chvmlinuz="$CHROOT_DIR/boot/vmlinuz-${KERNEL_VERSION}"
dummy_repo_string="Bootable Client Lockdown (BCLD) ${BCLD_VERSION_STRING} \"${CODE_NAME}\" ${BCLD_ARCH} ($(date))"


# FUNCTIONS

## Function to check required BUILD ENVs prior to building
function check_req_envs () {
    list_item 'Checking REQUIRED ENVs...'
    check_req_env 'BCLD_MODEL'
}

## Function to check optional BUILD ENVs prior to building
function check_opt_envs () {
    list_item 'Checking OPTIONAL ENVs...'
    check_opt_env 'BCLD_APP'
    check_opt_env 'BCLD_NVIDIA'
    check_opt_env 'BCLD_PKG_EXTRA'
    check_opt_env 'BCLD_SECRET'
    check_opt_env 'BCLD_TAG_EXTRA'
    check_opt_env 'KEEP_BOOTSTRAP'
    check_opt_env 'FACET_SECRET_1'
    check_opt_env 'FACET_SECRET_2'
    check_opt_env 'FACET_SECRET_3'
    check_opt_env 'FACET_SECRET_4'
    check_opt_env 'NULLFIX'
    check_opt_env 'WFT_SECRET_1'
    check_opt_env 'WFT_SECRET_2'
}

## Function to list detected build/run stages
function check_tags () {
    
    TAG='ISO-TAGS'
    
    list_header 'Running BCLD tag detection...'
    
    TAGS=$(/usr/bin/grep -r "^[ /t]*TAG=" ./Docker-builder.sh ./ISO-builder.sh ./IMG-builder.sh ./script/* ./config/*/* ./tools/* ./test/bcld_test.sh | /usr/bin/cut -d '=' -f2 | /usr/bin/tr -d '"' | /usr/bin/tr -d "'" )
    count=1
    total="$(/usr/bin/echo ${TAGS} | /usr/bin/wc -w)"
    
    for tag in ${TAGS}; do
        list_item "(${count}/${total}): ${tag}"
        ((count++))
    done
    
    list_exit
}

## Function to cleanup prior to building using mostly file_operations.sh
clean_prebuild () {
    # Clean all mounts and loop devices
    unmount_chroot
    clear_loop_devs


    # chroot
    clean_chroot

    # BIOS
    reset_file "${CORE_IMG}"
    reset_file "${BIOS_IMG}"
    reset_file "${EFI_ISO_GRUB}"
    reset_file "${IMAGE_GRUB}"
    reset_file "${UBUNTU_GRUB}"
    reset_file "${EFI_IMG}"
}

## Function to validate if there are any apps going to be installed before building
function init_pkgs () {

    TAG='ISO-APP'
    
    list_header "Checking available packages in \"${APP_DIR}\" and \"${CONFIG_DIR}/packages/APP\"."

    # If BCLD_MODEL isn't sourced, it should be declared within the build agent.
    if [[ $(/usr/bin/find ${APP_DIR} -type f -name '*.deb' | wc -l) -gt 0 ]]; then
        # Copy DEB files to CHDEB
        list_item_pass "DEB package found!"
        list_exit
        (( BCLD_DEB++ ))
    elif [[ $(/usr/bin/find ${APP_DIR} -type f -name '*.AppImage' | wc -l) -gt 0 ]]; then
        # Otherwise copy AppImages
        list_item_pass "AppImage found!"
        list_exit
        (( BCLD_APPIMAGE++ ))
    elif [[ $(/usr/bin/cat "${CONFIG_DIR}/packages/APP" | /usr/bin/wc -l) -gt 0 ]]; then 
        # Check for APP entries if there are no DEBs or AppImages
        list_item_pass "APP entries found!"
        list_exit
    else
        # Fail immediately if there is no DEB-file, no AppImage and no APP entries
        list_item_fail "No DEBs or AppImages found in ${APP_DIR} and no APP entries found in ${CONFIG_DIR}/packages/APP!"
        on_failure
    fi
}

## Function to count and copy DEB files inside CHAPP_DIR
function copy_chdeb () {

    TAG='ISO-CHDEB'
    
    # Find DEB file with BCLD_MODEL, using APP_DIR
    list_header "Copying DEB-file"
    /usr/bin/find "${APP_DIR}" \
        -type f \
        -name '*.deb' \
        -exec bash -c 'for app; do /usr/bin/cp ${app} '${CHAPP_DIR}'; done' bash {} + -quit
    
    # Check if DEB was installed properly
    list_item "$(/usr/bin/dpkg -I "${CHAPP_DIR}"/*.deb | grep 'Version:')"
    list_item_pass "DEB-file copied!..."
    on_completion
}

## Function to count and copy AppImage files inside CHAPP_DIR
function copy_chapp () {

    TAG='ISO-CHAPP'
    
    # AppImages don't require installation,
    # so we can shove em' straight into /opt
    list_header "Copying AppImage"
    
    /usr/bin/find "${APP_DIR}" \
        -type f \
        -name '*.AppImage' \
        -exec bash -c 'for app; do /usr/bin/cp ${app} '${CHROOT_OPT}'; done' bash {} + -quit
     
     /usr/bin/chmod +x "${CHROOT_DIR}/${BCLD_APP}"
    
    
    if [[ $(/usr/bin/find "${CHROOT_OPT}" -type f -name "${BCLD_RUN}*" | /usr/bin/wc -l) -gt 0 ]]; then
        list_item_pass "AppImage copied!"
        on_completion
    else
        list_item_pass "AppImage not found!"
        on_failure
    fi
}

## Function to copy existing bootstrap files
function copy_bootstrap () {

    copy_recursively "${BOOTSTRAP_DIR}" "${CHROOT_DIR}"
    
    # Cleanup ./bootstrap if configured
	if [[ "${KEEP_BOOTSTRAP}" == 'true' ]]; then
	    list_item 'Using KEEP_BOOTSTRAP=true'
	else
		delete_dir "${BOOTSTRAP_DIR}" "Cleaning old bootstrap..."
	fi

}

## Function for preparing directories
function prep_dirs () {
    list_header "Preparing directories"

    prep_dir "${APP_DIR}"
    prep_dir "${ART_DIR}"
    prep_dir "${GRUB_DIR}"
    prep_dir "${CASPER_DIR}"
    prep_dir "${CHAPP_DIR}"
    prep_dir "${DISK_DIR}"
    prep_dir "${DIST_DIR}"
    prep_dir "${UBUNTU_DIR}"
    prep_dir "${LOG_DIR}"
    prep_dir "${OPT_DIR}"
    prep_dir "${POOL_DIR}"
    prep_dir "${CHROOT_PKI_DIR}"
    prep_dir "${CHROOT_CHROME_CERT_DIR}"
    prep_dir "${EFI_BOOT_DIR}"

    on_completion
}

## Function to check if app was installed correctly
function check_apps () {
    if [[ ${BCLD_DEB} -gt 0 ]]; then
        # If DEBs found in ./APP, build default
        # Look for a binary resemling BCLD_RUN in CHROOT_OPT, single match
        DEB_CHECK="$(/usr/bin/find "${CHROOT_OPT}" -type f -name "${BCLD_RUN}*" -print -quit)"
        
        list_item "Running Debian package check on ${BCLD_RUN}: ${DEB_CHECK}"
        
        if [[ -x ${DEB_CHECK} ]]; then
            list_item_pass "Debian package found!"
            on_completion
        elif [[ -z ${BCLD_APP} ]]; then
            list_item_fail "BCLD_APP cannot be empty!"
            list_item_fail "EXITING IMMEDIATELY!: ${1}"
            on_failure
        else
            list_item_fail "Debian package could not be found..."
            list_item_fail "EXITING IMMEDIATELY!: ${1}"
            on_failure
        fi

    elif [[ ${BCLD_APPIMAGE} -gt 0 ]]; then
        # If AppImage found, use AppImage
        # Check /opt for AppImages or exit immediately if there is nothing there

        APP_IMG_CHECK="$(/usr/bin/find "${CHROOT_OPT}" -type f -name "${BCLD_RUN}*")"
        
        list_item "Running AppImage check on ${BCLD_RUN}: ${APP_IMG_CHECK}"
        
        if [[ -x ${APP_IMG_CHECK} ]]; then
            list_item_pass "AppImage found!"
            on_completion
        else
            list_item_fail "AppImage could not be found..."
            list_item_fail "EXITING IMMEDIATELY!: ${1}"
            on_failure
        fi
        
    else 
        # Use ./config/packages/APP in any other case

        APP_PKG_CHECK="$(/usr/sbin/chroot "${CHROOT_DIR}" /usr/bin/dpkg -l | /usr/bin/awk '{ print $2 }' | grep "^${BCLD_RUN}$" | /usr/bin/wc -l)"
        
        list_item "Running App package check on ${BCLD_RUN}..."
        
        if [[ ${APP_PKG_CHECK} -eq 1 ]]; then
            list_item_pass "Package found!"
            on_completion
        else
            list_item_fail "Package could not be found..."
            list_item_fail "EXITING IMMEDIATELY!: ${1}"
            on_failure
        fi
    fi
}

## Function to copy initrd
function copy_initrd () {
    copy_file "${chinitrd}" "${1}/initrd" && list_item_pass "initrd copied!"
}

## Function to copy vmlinuz
function copy_vmlinuz () {
    copy_file "${chvmlinuz}" "${1}/vmlinuz" && list_item_pass "vmlinuz copied!"
}

## Function to set ENVs inside ./chroot
function set_chroot_env () {
    list_item_pass "Setting BCLD_ENV: ${1}=${2}..."
    /usr/bin/echo "${1}=${2}" >> "${CHENV}"
}

## Function to get ENVs inside ./chroot
function get_chroot_env () {
    list_header "Getting BCLD_ENVs:"
    list_entry
    /usr/bin/cat "${CHENV}"
    list_catch
}

## Function for newline in PKGS_ALL
function pkgs_line () {
    /usr/bin/echo >> "${PKG_ART}"
}

## Function to display BCLD_MODEL
function get_bcld_model () {
    list_header "BCLD_MODEL set to: ${BCLD_MODEL}"
}

## Function to mount systems
function init_mount () {
    list_entry
    /usr/bin/mount --verbose --bind /dev "${CHROOT_DIR}/dev"
    /usr/bin/mount --verbose -t devpts /dev/pts "${CHROOT_DIR}/dev/pts"
    /usr/bin/mount --verbose -t proc /proc "${CHROOT_DIR}/proc"
    /usr/bin/mount --verbose --rbind /sys "${CHROOT_DIR}/sys"
    list_catch
}

## Function to unmount systems
function unmount_chroot () {

	# Always sync and wait 2s first
	/usr/bin/sync && sleep 2s
    clear_mount "${CHROOT_DIR}/sys"
    clear_mount "${CHROOT_DIR}/proc"
    clear_mount "${CHROOT_DIR}/dev/pts"
    clear_mount "${CHROOT_DIR}/dev"
}

## Function to copy configuration files
function copy_config_scripts () {
	list_header "Copying configuration scripts."
	
	copy_file "${SCRIPT_DIR}/autocert.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/bcld_app.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/bcld_vendor.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/chroot.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/client_logger.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/crosdump_logger.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/echo_tools.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/log_tools.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/startup.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/usb_logger.sh" "${CHROOT_BIN}"
	copy_file "${SCRIPT_DIR}/Xconfigure.sh" "${CHROOT_BIN}"
	on_completion
}

## Function to copy Nvidia files
function copy_nvidia_configs () {
    if [[ ${BCLD_NVIDIA} == 'true' ]]; then
	    list_header "BCLD_NVIDIA set to 'true'"

        NVIDIA_XRUN="${PROJECT_DIR}/modules/nvidia-xrun"

        if [[ -d ${NVIDIA_XRUN} ]]; then
            list_item 'Copying Nvidia configuration files...'
            
            # nvidia-xrun
            #copy_file "${NVIDIA_XRUN}/nvidia-xorg.conf" "${CHETC}/X11/"
            copy_file "${NVIDIA_XRUN}/nvidia-xinitrc" "${CHETC}/X11/xinit/"
            copy_file "${NVIDIA_XRUN}/nvidia-xrun" "${CHROOT_BIN}"
            
            # X11 config
            copy_file "${CONFIG_DIR}/X11/xorg.conf.nvidia/30-nvidia.conf" "${CHROOT_DIR}/etc/X11/xorg.conf.d/30-nvidia.conf"
            
            /usr/bin/chmod +x "${CHROOT_BIN}/nvidia-xrun"
            
            /usr/bin/echo 'openbox' > "${CHOME_DIR}/.xinitrc"
        else
            list_item_fail 'Nvidia Git modules not found...'
            on_failure
        fi
    fi

}

## Function to copy post-configuration directories
function copy_post_config_dirs () {
    list_item "Copying configuration directories"
    #copy_directory "${CONFIG_DIR}/systemd/shm" "${CHROOT_DIR}/sys/block"

    copy_directory "${CONFIG_DIR}/systemd/system/systemd-udevd.service.d" "${CHSERVICE_DIR}"
    #copy_directory "${CONFIG_DIR}/systemd/system.conf.d/" "${CHROOT_DIR}/etc/systemd"
    copy_directory "${CONFIG_DIR}/trap_shutdown" "${CHOME_DIR}"
    copy_directory "${CONFIG_DIR}/X11/xorg.conf.d" "${CHROOT_DIR}/etc/X11/"
    copy_directory "${PROFILE_DIR}" "${CHROOT_DIR}/etc/"
}

## Function to copy post-configuration files
function copy_post_configs () {
	list_item "Copying postconfiguration files..."

	copy_file "${CONFIG_DIR}/modprobe/alsa-base.conf" "${CHROOT_DIR}/etc/modprobe.d/alsa-base.conf"
	copy_file "${CONFIG_DIR}/modprobe/blacklist.conf" "${CHROOT_DIR}/etc/modprobe.d/blacklist.conf"
	copy_file "${CONFIG_DIR}/network-manager/conf.d/default-wifi-powersave-on.conf" "${CHROOT_DIR}/etc/NetworkManager/conf.d/default-wifi-powersave-on.conf"
	copy_file "${CONFIG_DIR}/network-manager/interfaces" "${CHROOT_DIR}/etc/network/"
	copy_file "${CONFIG_DIR}/network-manager/NetworkManager.conf" "${CHROOT_DIR}/etc/NetworkManager/"
	copy_file "${CONFIG_DIR}/openbox/autostart" "${CHROOT_DIR}/etc/xdg/openbox/"
	copy_file "${CONFIG_DIR}/pam/login" "${CHROOT_DIR}/etc/pam.d/login"
	copy_file "${CONFIG_DIR}/plymouth/spinner.plymouth" "${CHPLY_DIR}/themes/spinner/spinner.plymouth"
	copy_file "${CONFIG_DIR}/plymouth/bcld-plymouth.png" "${CHPLY_DIR}/themes/spinner/watermark.png"
	copy_file "${CONFIG_DIR}/plymouth/bcld-plymouth.png" "${CHPLY_DIR}/ubuntu-logo.png"
	copy_file "${CONFIG_DIR}/rsyslog/60-BCLD-rsyslog.conf" "${CHOME_DIR}/60-BCLD-rsyslog.conf"
    copy_file "${CONFIG_DIR}/rsyslog/70-bcld-log.conf" "${CHOME_DIR}/70-bcld-log.conf"
	copy_file "${SCRIPT_DIR}/rsyslogger.sh" "${CHROOT_BIN}"
    copy_file "${CONFIG_DIR}/X11/xmodmap/.xmodmap" "${CHOME_DIR}"
	copy_file "${CONFIG_DIR}/X11/xbindkeys/.xbindkeysrc" "${CHOME_DIR}"
	
	## Copy ISOLINUX
    copy_file /usr/lib/ISOLINUX/isolinux.bin "${ISOLINUX_DIR}/isolinux.bin"
}

check_tags

# Before building, check if any DEBs, AppImages or APPs are present
init_pkgs

# Start Building
TAG='ISO-PRECLEAN'
list_header "Starting BCLD ISO Builder!"
list_item "Date: $(date -Ru)"
last_item "Version: ${BCLD_VERSION_STRING}"

# Check ENV before build
list_header "Checking build ENVs!"
check_req_envs
check_opt_envs

# Cleanup before build
clean_prebuild

## Components
reset_file "${ISO_MD5}"
reset_file "${SQUASHFS}"
delete_dir "${DISK_DIR}" "Cleanup disk info..."   
clean_art

on_completion

# Generate necessary build directories

TAG='ISO-PREP'

prep_dirs

# Debootstrap

TAG='ISO-BOOTSTRAP'

# This may only work if Debootstrap is installed
if [[ -f /usr/sbin/debootstrap ]] && [[ ! -d "${BOOTSTRAP_DIR}" ]]; then

    list_header "Bootstrapping Ubuntu ${CODE_NAME^}..."
	# Create directory and copy files, /tmp needs special permissions
    prep_dir "${BOOTSTRAP_DIR}"
    
    list_entry
    /usr/sbin/debootstrap --variant=minbase --arch=amd64 "${CODE_NAME}" "${BOOTSTRAP_DIR}" "${UBUNTU_REPO}" | /usr/bin/tee "${BOOTSTRAP_LOG}"
    list_catch
    
    copy_bootstrap

elif [[ -d "${BOOTSTRAP_DIR}" ]] && [[ "$(/usr/bin/find "${BOOTSTRAP_DIR}" -mindepth 1 -type d | /usr/bin/wc -l )" -gt 0 ]]; then

	list_header "Existing bootstrap detected, skipping!"

	# Use existing image, do not bootstrap
    copy_bootstrap

else
    list_item_fail "Unable to prepare the environment!"
    last_item "Please make sure 'debootstrap' is installed."
    on_failure
fi

on_completion

# After the bootstrap, copy any DEBs or AppImages, but never both
if [[ ${BCLD_DEB} -gt 0 ]]; then
    copy_chdeb
elif [[ ${BCLD_APPIMAGE} -gt 0 ]]; then
    copy_chapp
fi

# Preconfigurations

TAG='ISO-PRECONF'

list_header "Preconfigurations"

copy_file "${BUILD_CONF}" "${CHROOT_ROOT}"
subst_file "${CONFIG_DIR}/apt/sources.list" "${CHROOT_DIR}/etc/apt/sources.list"

## Build VERSION
list_item "Generating ${CHROOT_DIR}/VERSION..."
/usr/bin/echo "${BCLD_VERSION_STRING}" > "${CHROOT_DIR}/VERSION"

## Package management

### Substitute KERNEL lines
subst_file "${PKGS_DIR}/KERNEL" "${PKG_ART}"
pkgs_line

### Add main packages
# Kernel packages and dependencies from REQUIRED are always installed
cat "${PKGS_DIR}/REQUIRED" >> "${PKG_ART}"
pkgs_line

### Debian Non-interactive
copy_file "${PKGS_DIR}/selections.conf" "${CHROOT_DIR}/${BCLD_HOME}"

### Add Nvidia drivers if enabled
if [[ ${BCLD_NVIDIA} == 'true' ]]; then
    subst_file_add "${PKGS_DIR}/NVIDIA" "${PKG_ART}"
    pkgs_line
fi

### Add DEBUG packages for everything except RELEASE
if [[ ${BCLD_MODEL} != 'release' ]]; then
    cat "${PKGS_DIR}/DEBUG" >> "${PKG_ART}"
    pkgs_line
fi

### Add TEST packages specifically for TEST
if [[ ${BCLD_MODEL} = 'test' ]]; then
    cat "${PKGS_DIR}/TEST" >> "${PKG_ART}"
    pkgs_line
fi

# Display all packages, if there are no packages we cannot continue!
if [[ -f ${PKG_ART} ]]; then
    list_item "Full list of packages:"
    list_entry
    cat "${PKG_ART}"
else
    last_item "PKG_ART not set! Exiting..."
    on_failure
fi

# Copy PKGS_ALL AFTER all the modifications to the list are finished
list_header "Copying Package list artifact"
copy_file "${PKG_ART}" "${CHROOT_DIR}/${BCLD_HOME}"
list_exit

## Configuration scripts
copy_config_scripts

# BCLD Services

TAG='ISO-SERVICES'

list_header "Copying BCLD Services"

## USB-logger
copy_file "${CONFIG_DIR}/systemd/system/BCLD-USB.service" "${CHSERVICE_DIR}/BCLD-USB.service"

## Chromium dump
copy_file "${CONFIG_DIR}/systemd/system/BCLD-crosdump.service" "${CHSERVICE_DIR}/BCLD-crosdump.service"

# REMOVE can exclude packages from a build
if [[ -n $(cat "${PKGS_DIR}/REMOVE") ]]; then
    list_item_pass "Packages marked for removal:"
    list_entry
    /usr/bin/cat "${PKGS_DIR}/REMOVE"
    list_catch

    copy_file "${PKGS_DIR}/REMOVE" "${CHROOT_ROOT}"
fi

# APP can include packages for Vendorless BCLD
if [[ -n $(cat "${PKGS_DIR}/APP") ]]; then
    list_item_pass "Adding APP packages:"
    list_entry
    /usr/bin/cat "${PKGS_DIR}/APP"
    list_catch

    copy_file "${PKGS_DIR}/APP" "${CHROOT_ROOT}"
fi

on_completion

# Set mounts
# This is essential, so exit on failure
#/usr/bin/mount --verbose --rbind devpts "${CHROOT_DIR}/dev/pts"
TAG='ISO-MOUNT'
list_header "Applying mounts"
init_mount
on_completion

# Chroot installations
TAG='ISO-CHROOT'
list_header "Chrooting"

## Chroot
/usr/sbin/chroot "${CHROOT_DIR}" "/usr/bin/chroot.sh" | /usr/bin/tee "${CHROOT_LOG}"

## Check if app was installed after chrooting
if [[ ! -f "${CHROOT_DIR}/var/cache/apt/pkgcache.bin" ]]; then
    # Chroot finished succesfully, check for app
    list_item_pass 'Chroot finished successfully, checking for app...'
    check_apps "Build failed!"
else
    # Chroot ended unexpectedly
    list_item_fail 'Chroot was ended unexpectedly!'
    on_failure
fi


# Postconfigurations

TAG='ISO-POSTCONF'

list_header "Postconfigurations"

## dhclient timeout
/usr/bin/sed -i 's/timeout 300/timeout 20/' "${CHROOT_DIR}/etc/dhcp/dhclient.conf"

## dhclient retry (reset to default)
#/usr/bin/sed -i 's/#retry 60/retry 3600/' "${CHROOT_DIR}/etc/dhcp/dhclient.conf"

## Generate configuration directories
# Agetty
prep_dir "${CHSERVICE_DIR}/getty@tty1.service.d"

# Sudo
prep_dir "${CHROOT_DIR}/etc/sudoers.d"
list_exit

## Copy post-configuration directories
copy_post_config_dirs

## Copy post-configuration files
copy_post_configs

## Copy Nvidia configuration files for BCLD_NVIDIA builds
copy_nvidia_configs

## Substitutions
subst_file "${CONFIG_DIR}/bash/environment" "${CHENV}"
subst_file "${CONFIG_DIR}/casper/casper.conf" "${CHROOT_DIR}/etc/casper.conf"
subst_file "${CONFIG_DIR}/systemd/system/getty@tty1.service.d/override.conf" "${CHSERVICE_DIR}/getty@tty1.service.d/override.conf"

## Current ENVs inside ./chroot
get_chroot_env

## BCLD INIT script
copy_file "${CONFIG_DIR}/bash/bcld-init" "${CHINIT}/bcld-init"

list_item 'Generating BCLD-INIT links...'

cd "${CHETC}" || exit

### K-levels
link_file "init.d/bcld-init" rc0.d/K01bcld-init
link_file "init.d/bcld-init" rc1.d/K01bcld-init
link_file "init.d/bcld-init" rc6.d/K01bcld-init

### S-levels
link_file "init.d/bcld-init" rc2.d/S01bcld-init
link_file "init.d/bcld-init" rc3.d/S01bcld-init
link_file "init.d/bcld-init" rc4.d/S01bcld-init
link_file "init.d/bcld-init" rc5.d/S01bcld-init

safe_return

## Change permissions for BCLD Big Mouse
# BCLD Big Mouse has to overwrite this file when enabled
list_item "Changing mouse permissions for BCLD Big Mouse..."
/usr/bin/chmod 666 "${CHROOT_DIR}/usr/share/fonts/X11/misc/cursor.pcf.gz"

## Suspend / Lock
# Disable lock on lid close
if [[ -f ${CHLOGIND} ]]; then
	list_item "Disable lock on lid close..."
	# Search lock on lid close, replace with ignore
	/usr/bin/echo 'HandleLidSwitch=ignore' >> "${CHLOGIND}"
fi

## Shutdown
list_item "Decrease shutdown timer..."
/usr/bin/echo 'DefaultTimeoutStopSec=5s' >> "${CHROOT_DIR}/etc/systemd/system.conf"

## Grub framebuffer for splash
list_item "Enabling Grub framebuffer..."
/usr/bin/echo 'FRAMEBUFFER=y' >> "${CHROOT_DIR}/etc/initramfs-tools/conf.d/splash"
### this is broken
# list_item "Update GRUB 64-bit signed binaries..."
# copy_file /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed "${EFI_BOOT_DIR}"/grubx64.efi

# Make any extra errors less splashy
list_item "XTerm configuration..."
copy_directory "${CONFIG_DIR}/X11/xterm" "${CHOME_DIR}/xterm"

# iptables
list_item "Setting firewall rules for next boot: ${BCLD_MODEL}"

if [[ ${BCLD_MODEL} = 'release' ]]; then
    # Set regular firewall rules for next boot
    copy_file "${CONFIG_DIR}/iptables/iptables.firewall.rules" "${CHROOT_DIR}/etc/iptables/rules.v4"

elif [[ ${BCLD_MODEL} = 'debug' ]]; then
    # Set debug firewall rules for next boot
    copy_file "${CONFIG_DIR}/iptables/iptables.firewall.rules.debug" "${CHROOT_DIR}/etc/iptables/rules.v4"

else
    # Set test firewall rules for next boot
    copy_file "${CONFIG_DIR}/iptables/iptables.firewall.rules.test" "${CHROOT_DIR}/etc/iptables/rules.v4"
fi

# Create noauto file for xbindkeys, load manually (only RELEASE)
/usr/bin/touch "${CHOME_DIR}/.xbindkeys.noauto"

# Delete necessary files
delete_file "${CHROOT_DIR}/etc/machine-id" 'Generalizing distro...'
delete_file "${CHROOT_DIR}/etc/resolv.conf" 'Clearing resolv.conf...'

## Unnecessary services
delete_file "${CHSERVICE_DIR}/dbus-org.freedesktop.resolve1.service" 'Disable resolvconf'
delete_file "${CHSERVICE_DIR}/multi-user.target.wants/systemd-resolved.service" 'Disable resolvconf'
delete_file "${CHROOT_DIR}/lib/systemd/system/systemd-resolved.service" 'Disable resolvconf'
delete_file "${CHROOT_DIR}/lib/systemd/system/casper-md5check.service" 'Disable Casper service (trigger manually)'

## Disable MOTD's if they exist
if [[ -f ${CHROOT_DIR}/etc/legal ]];then
    list_item "Disabling MOTDs..."
    /usr/bin/chmod -x "${CHROOT_DIR}"/etc/update-motd.d/*
    /usr/bin/rm "${CHROOT_DIR}/etc/legal"
fi

on_completion

## Certificate Management, perform only if CERT is present in /cert
# Skip entirely if CERT_DIR does not exist
if [[ -d "${CERT_DIR}" ]]; then

    TAG='ISO-CERT'

    list_header "Certificate Management"

    # Skip if no CRTs found
    if [[ $(/usr/bin/find "${CERT_DIR}" -type f -name '*crt' | /usr/bin/wc -l) -gt 0 ]]; then

	    list_item_pass "Certificates found in ${CERT_DIR}!"


	    list_item "Checking directories..."
	    delete_dir "${CHNSSDB}" 'Clearing...'
	    prep_dir "${CHNSSDB}"

	    ## Copy all certificates to the client
	    list_item "Copying certificates..."
	    copy_directory ${CERT_DIR}/facet "${CHROOT_PKI_DIR}"
	    copy_directory ${CERT_DIR}/wft "${CHROOT_PKI_DIR}"

	    ## KEY
	    list_item "Storing Facet key..."
	    /usr/bin/echo -e "${FACET_SECRET_1}\n${FACET_SECRET_2}\n${FACET_SECRET_3}\n${FACET_SECRET_4}" > "${CHROOT_PKI_DIR}/facet/${CLIENT_KEY_NAME}"
	    
	    list_item "Storing WFT key..."
	    /usr/bin/echo -e "${WFT_SECRET_1}\n${WFT_SECRET_2}" > "${CHROOT_PKI_DIR}/wft/${CLIENT_KEY_NAME}"

	    list_item "Copying NSSDBs..."
	    copy_directory "${CLIENT_NSSDB}" "${CHOME_DIR}"
    else
	    list_item_fail "No certificates found in ${CERT_DIR}! Skipping..."
	fi
	
else
	list_item_fail "${CERT_DIR} not found! Skipping..."
fi

on_completion

## BCLD TWEAKS
# Tweaks are slight differences between the BCLD_MODELs

TAG='ISO-TWEAKS'

list_header 'BCLD tweaks'

### BCLD_MODEL TWEAKS
list_item 'BCLD_MODEL tweaks'

if [[ ${BCLD_MODEL} = 'release' ]]; then

	# Configure Openbox for RELEASE
	copy_file "${CONFIG_DIR}/openbox/rc.xml" "${CHROOT_DIR}/etc/xdg/openbox/rc.xml"

elif [[ ${BCLD_MODEL} = 'debug' ]]; then

	# Configure Openbox for DEBUG
	copy_file "${CONFIG_DIR}/openbox/rc.xml.debug" "${CHROOT_DIR}/etc/xdg/openbox/rc.xml"

else

	# Configure Openbox for TEST
	copy_file "${CONFIG_DIR}/openbox/rc.xml.debug" "${CHROOT_DIR}/etc/xdg/openbox/rc.xml"

    # Add user password for TEST
    set_chroot_env "BCLD_SECRET" "${BCLD_SECRET}"
    
    # Disable kioskmode if test
    list_item "Disabling kioskmode..."
    copy_file "${CONFIG_DIR}/X11/xorg.conf.test/99-bcld-disable-kiosk.conf" "${CHROOT_DIR}/etc/X11/xorg.conf.d/"
    
    # Add extra TEST tools
    list_item 'Adding test tools...'
    copy_file "./test/bcld_test.sh" "${CHROOT_BIN}"

fi

### VENDORLESS TWEAKS
if [[ ${BCLD_RUN} == 'qutebrowser' ]]; then
    prep_dir "${CHOME_DIR}/.config/qutebrowser"
    copy_file "${CONFIG_DIR}/qutebrowser/config.py" "${CHOME_DIR}/.config/qutebrowser/config.py"
fi

### BCLD_NVIDIA TWEAKS
#if [[ ${BCLD_NVIDIA} == 'true' ]]; then
#    list_item 'Forcing Nvidia kernel module...'
#    /usr/bin/echo "blacklist i915" >> "${CHROOT_DIR}/etc/modprobe.d/blacklist.conf"
#fi

on_completion

## Trigger update-initramfs before exporting artifacts
TAG='ISO-INITRAMFS'
list_header "Triggering update-initramfs"
list_entry
/usr/sbin/chroot "${CHROOT_DIR}" /usr/sbin/update-initramfs -u | /usr/bin/tee -a "${CHROOT_LOG}"

### Lazy force unmounts after last chroot command
list_header "Forcing unmounts"
unmount_chroot
list_exit


### Copy initrd (RAMFS) and vmlinuz (kernel)
list_header "Copying initrd and vmlinuz"

# Casper
copy_initrd "${CASPER_DIR}"
copy_vmlinuz "${CASPER_DIR}"

# Artifacts
copy_initrd "${ART_DIR}"
copy_vmlinuz "${ART_DIR}"

on_completion

### Generate package lists

TAG='ISO-REPO'

list_header "Scanning packages with DPKG"

list_entry
cd "${ISO_DIR}"
dpkg-scanpackages --arch amd64 pool/ > "${DIST_DIR}/Packages"
list_catch

list_item "Compressing Packages.gz..."

cat "${DIST_DIR}/Packages" | gzip -9 > "${DIST_DIR}/Packages.gz"
safe_return

# Generate Release file
list_header "Generating Release file"

cd "${REPO_DIR}"
"${REPOMAN_DIR}/generate_release.sh" > Release
safe_return

list_item_pass "BCLD repository packages successfully scanned!"
on_completion

# Generate SquashFS only if there are contents inside /opt.

TAG='ISO-SQUASHFS'

# This is where the app SHOULD be installed.
# Generating SquashFS takes very long and is pointless without the app
check_apps "Cannot build SquashFS..."

list_header "Generating SquashFS"
list_entry
/usr/bin/mksquashfs chroot "${CASPER_DIR}/filesystem.squashfs" \
	-e boot \
	-e var/cache \
	-e var/lib/apt/lists \
	-e usr/share/backgrounds
list_catch
on_completion

# After generating the SQUASHFS, it is safe to cleanup ./chroot
TAG='ISO-CLEANUP'

list_header "Cleaning: ${CHROOT_DIR}"

# Never, ever clean chroot unless the devices are unmounted!
unmount_chroot

du_export "${CHROOT_DIR}"

FAILED_COUNT=0

# Check for installed pkgs
for pkg in $(cat ./artifacts/PKGS_ALL); do
	PKG_COUNT="$(/usr/sbin/chroot ./chroot bash -c "/usr/bin/dpkg --get-selections ${pkg}" | /usr/bin/grep -cw 'install')"
	
	# Increase amount of FAILED_PKGS if a PKG install cannot be COUNT
	if [[ "${PKG_COUNT}" -eq 0 ]]; then
		FAILED_COUNT="$(( FAILED_COUNT + 1 ))"
		FAILED_PKGS+=" ${pkg}"
	fi
	
done

if [[ "${FAILED_COUNT}" -gt 0 ]]; then
	list_item_fail "Missing packages detected:${FAILED_PKGS}"
	list_item_fail "TOTAL: ${FAILED_COUNT}"
	on_failure
else
	list_item_pass 'All packages successfully installed!'
	clean_chroot
	on_completion
fi

# Update Grub
TAG='ISO-GRUB'

list_header "Generating GRUB images"

list_item "Generating GRUB BIOS..."

cd "${ISO_DIR}"

## Generate Grub CORE binary
/usr/bin/grub-mkstandalone \
    --format=i386-pc \
    --output=isolinux/core.img \
    --install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux16 linux normal configfile iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=isolinux/grub.cfg" # Interne ISO grub.cfg mapping (BIOS)

## Combine with `cdboot.img` to generate BIOS binary
/usr/bin/cat /usr/lib/grub/i386-pc/cdboot.img isolinux/core.img > isolinux/bios.img

#list_item "Generating GRUB UEFI..."
## Generate Grub EFI binary, broken
#/usr/bin/grub-mkstandalone \
#	--format=x86_64-efi-signed/ \
#	--output=EFI/BOOT/grubx64.efi \
#	--install-modules="linux16 linux normal iso9660 biosdisk memdisk search tar ls" \
#	--modules="linux16 linux normal configfile iso9660 biosdisk search" \
#	--locales="" \
#	--fonts="" \
#	"boot/grub/grub.cfg=EFI/BOOT/grub.cfg" # Interne ISO grub.cfg mapping (UEFI)

safe_return

## Copy signed binaries from host, since installation does not work
list_item "Copy GRUB binaries..."
/usr/bin/cp /usr/lib/grub/x86_64-efi-signed/grubx64.efi.signed "${EFI_BOOT_DIR}/grubx64.efi"
/usr/bin/cp /usr/lib/shim/shimx64.efi.dualsigned "${EFI_BOOT_DIR}/bootx64.efi"
/usr/bin/cp /usr/lib/shim/mmx64.efi "${EFI_BOOT_DIR}/mmx64.efi"

## Dummy Repo
list_item "Create dummy repo string..."
### EFI
/usr/bin/echo "${dummy_repo_string}" > "${INF_ART}"

### ISO
#copy_file "${INF_ART}" "${DISK_DIR}"

## Copy UBUNTU_GRUB config to ISO
list_item "Copy GRUB configs..."
# UBUNTU
copy_file "${CONFIG_DIR}/grub/grub.cfg.iso" "${UBUNTU_GRUB}"
/usr/bin/echo -e "\nTHIS IS A DUPLICATE, DO NOT EDIT THIS FILE!" >> "${UBUNTU_GRUB}"

# EFI BOOT
copy_file "${CONFIG_DIR}/grub/grub.cfg.iso" "${EFI_ISO_GRUB}"
/usr/bin/echo -e "\nTHIS IS A DUPLICATE, DO NOT EDIT THIS FILE!" >> "${EFI_ISO_GRUB}"


## Generate GRUB EFI IMG-file
list_item "Generate GRUB EFI-IMG..."
list_entry

cd "${EFI_BOOT_DIR}"

IMG_PART=$(/usr/bin/du -s --exclude='efi.img' | /usr/bin/awk '{ print $1 }')

/usr/bin/dd if=/dev/zero of=efi.img bs=1024 count=$(( IMG_PART + 1024 ))
/usr/sbin/mkfs.vfat efi.img
/usr/bin/mmd -i efi.img efi efi/boot
/usr/bin/mcopy -vi "efi.img" {bootx64.efi,grubx64.efi,mmx64.efi,grub.cfg} ::efi/boot/
safe_return

list_catch
on_completion

# Prepare ISO image
TAG='ISO-GEN'

## Copy files
list_header "Preparing stage: ${TAG}"
copy_directory "${CONFIG_DIR}/grub/.disk" "${ISO_DIR}"

# Generate md5sum.txt for the ISO image
# If any directories or the hash file itself are included, it will throw an error during boot.

list_item "Generating ${ISO_MD5}"

cd "${ISO_DIR}"

while IFS= read -r FILE; do
    if [[ ${FILE} = "./${MD5_TAG}" ]] \
        || [[ ${FILE} = './isolinux/bios.img' ]]; then
        # Certain filles always trigger mismatches...
        continue
    else
        /usr/bin/md5sum "${FILE}" >> "${ISO_MD5}"
    fi
done <<< "$(/usr/bin/find . -type f)"

copy_file "${ISO_MD5}" "${CHROOT_DIR}"
list_exit

# Generate ISO image
list_header "Generating ISO image ${ART_DIR}/${ISO_NAME}"
list_entry

/usr/bin/xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${ISO_LABEL}" \
    -eltorito-boot boot/grub/bios.img \
      -no-emul-boot \
      -boot-load-size 4 \
      -boot-info-table \
      --eltorito-catalog boot/grub/boot.cat \
      --grub2-boot-info \
      --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
        -e EFI/BOOT/efi.img \
        -no-emul-boot \
    -append_partition 2 0xef EFI/BOOT/efi.img \
    -output "${ISO_ART}" \
    -graft-points \
        /EFI/efiboot.img=EFI/BOOT/efi.img \
        /boot/grub/bios.img=isolinux/bios.img \
        . \
    && list_catch && list_item "ISO image created!"

safe_return

on_completion

# CLEANUP

TAG='ISO-CLEAR'

# After generating the ISO, it is safe to cleanup SQUASHFS
list_header 'Cleanup SQUASHFS'
reset_file "${SQUASHFS}"

## Chroot mounts
unmount_chroot

list_item_pass "ISO-artifact created! Check ${ART_DIR}."
on_completion
