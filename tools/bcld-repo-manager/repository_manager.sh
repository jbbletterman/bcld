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
# BCLD Repo Manager
# This script requires, `gettext-base`, `aptitude`, `dpkg-dev`, `tee`, `tar` and `gzip`
#set -x
# Can also be ran with variables:
#   - POINTER_TYPE: u,g,o,d,z,s,x,w,q
#   - REPO_NAME: BCLD_CODE_NAME and BCLD_PATCH by default

if [[ -f "$(pwd)"/RepoMan.sh ]]; then
    # Paths
    PROJECT_DIR="$(pwd)"
    CONFIG_DIR="${PROJECT_DIR}/config"

    # Read ENVs from BUILD.conf
    source "${CONFIG_DIR}/BUILD.conf" || exit 1
else
    /usr/bin/echo "Please run script inside BCLD root!"
    /usr/bin/echo
    exit
fi

### ENVs ###
# Do not ask for confirmations
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

### VARs ###
BUILD_TOOLS="aptitude dpkg-dev tar gzip rsync gettext-base"

# Paths
LOG_DIR="${PROJECT_DIR}/log"

CHREPOMAN_LOG="${LOG_DIR}/CHREPOMAN.log"
LIST_DIR="${CONFIG_DIR}/packages"
REPO_HUB="${TMPDIR}/bcld_repo"
REPOMAN_DIR="${PROJECT_DIR}/tools/bcld-repo-manager"
REPOMAN_LOG="${LOG_DIR}/REPOSITORY_MANAGER.log"
SOURCES="/etc/apt/sources.list"
TMP_PKGS_DIR="${TMPDIR}/packages"
REPO_DIR="${REPO_HUB}/${REPO_NAME}"

## Directories
ART_DIR="${PROJECT_DIR}/artifacts"
CERT_DIR="${PROJECT_DIR}/cert"
DATA_DIR="${STABLE_DIR}/main/binary-amd64"
LOG_DIR="${PROJECT_DIR}/log"
PKGS_DIR="${REPO_DIR}/pool/main"
REPOMAN_DIR="${PROJECT_DIR}/tools/bcld-repo-manager"
STABLE_DIR="${REPO_DIR}/dists/stable"

## Package lists
DEBUG="${LIST_DIR}/DEBUG"
CHKERNEL="/root/KERNEL"
KERNEL="${LIST_DIR}/KERNEL"
REQUIRED="${LIST_DIR}/REQUIRED"
VIRTUAL="${LIST_DIR}/VIRTUAL"

## Temporary files and folders
ALL_PKGS="${TMP_PKGS_DIR}/PKGS"
ALL_DEPS="${TMP_PKGS_DIR}/DEPS"
ALL_DEPS_SORT="${TMP_PKGS_DIR}/DEPS_SORT"
DEP_DOWNLOADS="${TMP_PKGS_DIR}/DOWNLOADS"

# Artifacts
PKG_LIST="${TMPDIR}/${REPO_NAME}_PKGS_INFO"
PKG_REPORT="${ART_DIR}/${REPO_NAME}_PKGS.md"

## Logging
APT_REPOMAN_LOG="${LOG_DIR}/APT_REPOMAN.log"
PKGS_LOG="${LOG_DIR}/PKGS.log"
REPOMAN_LOG="${LOG_DIR}/REPOSITORY_MANAGER.log"

### Functions ###

# Read pointer
function read_pointer () {
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo "Press c to CREATE a new repo."
    /usr/bin/echo "Press u to UPDATE an existing repo."
    /usr/bin/echo "Press d to DEPLOY a repo."
    /usr/bin/echo "Press z to ZIP a repo."
    /usr/bin/echo "Press g to sign a repo with GPG."
    /usr/bin/echo "Press s to SEARCH for VIRTUAL packages."
    /usr/bin/echo "Press o to OUTPUT package lists."
    /usr/bin/echo "Press x to clear the Repo Manager."
    /usr/bin/echo "Press w to clear the web directory."
    /usr/bin/echo "Press q to QUIT."
    /usr/bin/echo
    /usr/bin/echo "Then, press Enter."
    /usr/bin/echo
    read -r POINTER_TYPE
    /usr/bin/echo
    /usr/bin/echo
    clear
}

# Prepare environment
function prep_dir () {
    if [[ ! -d ${1} ]]; then
        /usr/bin/echo "Preparing directory: ${1}"
        /usr/bin/mkdir -pv "${1}" &>> "${REPOMAN_LOG}" || exit
        if [[ ${1} = "${PKGS_DIR}" ]]; then
            /usr/bin/chown _apt "${PKGS_DIR}"
        fi
    fi    
}

# Function to clear temporary package lists
function populate_pkg_lists () {
    # PKGs
    if [[ -f "${ALL_PKGS}" ]];then
        /usr/bin/rm "${ALL_PKGS}"
    fi
    
    ### Update kernel package list
    /usr/bin/envsubst < "${KERNEL}" > "${CHKERNEL}"
    
    /usr/bin/cat "${DEBUG}" > "${ALL_PKGS}" && /usr/bin/echo "" >> "${ALL_PKGS}"
    /usr/bin/cat "${CHKERNEL}" >> "${ALL_PKGS}" && /usr/bin/echo "" >> "${ALL_PKGS}"
    /usr/bin/cat "${REQUIRED}" >> "${ALL_PKGS}" && /usr/bin/echo "" >> "${ALL_PKGS}"
    PKG_TOTAL="$(/usr/bin/wc -w < "${ALL_PKGS}")"

    # DEPs
    if [[ -f "${ALL_DEPS}" ]];then
        /usr/bin/rm "${ALL_DEPS}"
    fi
}

# Function to check repository and set the name if there is just 1
function check_repos () {
  repos=$(/usr/bin/find "${REPO_HUB}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  repo_num=$(/usr/bin/echo "${repos}" | /usr/bin/wc -w)
  
  /usr/bin/echo "Checking ${REPO_HUB} for existing repositories..."
  /usr/bin/echo "Repositories detected: ${repos}"
  /usr/bin/echo "Total: ${repo_num}" 
}

# Zip everything inside REPO_HUB/REPO_NAME
function zip_repo () {
  zip_file="${REPO_NAME}.tar.gz"
    /usr/bin/echo 
    /usr/bin/echo 
    /usr/bin/echo "Zipping repository...: ${REPO_NAME}"
    /usr/bin/echo 
    cd "${REPO_HUB}" || exit
    tar -zcvf "${zip_file}" "${REPO_NAME}"
    mv "${zip_file}" "${ART_DIR}"
    /usr/bin/echo
    /usr/bin/echo "Repository saved to: $(readlink -e "${ART_DIR}/${zip_file}")"
}

# Function to prepare directories
function prep_dirs () {
    # Prepare ENVs
    prep_dir "${ART_DIR}" 
    prep_dir "${LOG_DIR}"
    prep_dir "${REPO_HUB}"
    prep_dir "${TMP_PKGS_DIR}"

    # Repo functions
    prep_dir "${PKGS_DIR}"
    prep_dir "${DATA_DIR}"
}

# Download dependencies using /usr/bin/apt-cache
function dep_init () {    
    
    # Download always requires packages lists
    populate_pkg_lists
    
    # Counter
    pkg_count=1
    
    /usr/bin/echo
    /usr/bin/echo "Querying dependencies..."

    cd "${PKGS_DIR}" || exit
    while read -r PKG; do
        # PKG cannot be empty
        if [[ -n ${PKG} ]]; then
            /usr/bin/echo
            /usr/bin/echo " ┌┤[PKG]: ${PKG} [${pkg_count}/${PKG_TOTAL}]" \
                | /usr/bin/tee "${PKGS_LOG}"  \
                && ((pkg_count++))
            
            # Return string of DEPS for PKG
            DEPS=$(/usr/bin/apt-cache depends ${PKG} \
            | grep -E 'Depends' \
            | cut -d ':' -f 2,3 \
            | sed -e s/'<'/''/ -e s/'>'/''/)
            
            for DEP in ${DEPS};do
                if [[ ! ${ALL_DEPS} == *"${DEP}"* ]];then
                    /usr/bin/echo " └──•(DEP): ${DEP}"  \
                        | /usr/bin/tee "${PKGS_LOG}"
                    /usr/bin/echo "${DEP}" >> "${ALL_DEPS}"
                fi
            done
        fi
    done < "${ALL_PKGS}"
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo "TOTAL PKGS: ${PKG_TOTAL}"
    /usr/bin/echo
    /usr/bin/echo "PKGS:"
    /usr/bin/cat "${ALL_PKGS}"
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/cat "${ALL_DEPS}" | sort -u > "${ALL_DEPS_SORT}"
    comm -13 "${VIRTUAL}" "${ALL_DEPS_SORT}" --nocheck-order > "${DEP_DOWNLOADS}"
    dep_total="$(wc -l < "${DEP_DOWNLOADS}")"
    /usr/bin/echo "TOTAL DEPS: ${dep_total}"
    /usr/bin/echo
    /usr/bin/echo "DEPS:"
    /usr/bin/cat "${DEP_DOWNLOADS}"
    EVERYTHING="$(/usr/bin/cat "${ALL_PKGS}" <(/usr/bin/echo) ${DEP_DOWNLOADS})"
    EVERYTHING_UNIQUE="$(/usr/bin/echo "${EVERYTHING}" | /usr/bin/sort -u)"
    EVERYTHING_TOTAL="$(/usr/bin/echo ${EVERYTHING_UNIQUE} | /usr/bin/wc -w)"
}

function download_now () {
    # Set download flag if not set
    if [[ -z ${DOWNLOAD_NOW} ]];then
        /usr/bin/echo
        /usr/bin/echo
        /usr/bin/echo "Type 'YES' to download listed PKGS and DEPS:"
        /usr/bin/echo
        read -r DOWNLOAD_NOW
    fi
    
    # Download interactively or immediately
    if [[ ${DOWNLOAD_NOW} = 'YES' ]];then
        /usr/bin/echo
        /usr/bin/echo
        # /usr/bin/echo "Downloading PKGS. This may take a while..."
        # /usr/bin/echo
        # /usr/bin/apt-get download $(/usr/bin/cat ${ALL_PKGS}) &>>"${APT_REPOMAN_LOG}" || exit
        # /usr/bin/echo
        # /usr/bin/echo
        # /usr/bin/echo "Downloading DEPS. This may take a while..."
        # /usr/bin/echo
        /usr/bin/echo "Downloading all packages, please wait..." \
            && /usr/bin/apt-get download ${EVERYTHING} &>>"${APT_REPOMAN_LOG}" \
            || /usr/bin/echo "Download failed..."
        /usr/bin/echo "Download finished!"
        /usr/bin/echo
    else
        /usr/bin/echo
        /usr/bin/echo "Download cancelled."
        /usr/bin/echo
    fi
}

# Function to update existing repository
function update_repo () {
    # Scan all downloaded packages and generate Package files
    /usr/bin/echo
    /usr/bin/echo "Scanning packages..."
    cd "${REPO_DIR}" || exit
    dpkg-scanpackages --arch amd64 pool/ > "${DATA_DIR}/Packages"
    /usr/bin/echo "Compressing Packages.gz..."
    /usr/bin/cat "${DATA_DIR}/Packages" | gzip -9 > "${DATA_DIR}/Packages.gz"

    # Generate Release file
    /usr/bin/echo
    /usr/bin/echo "Generating Release file..."
    cd "${STABLE_DIR}/" || exit
    "${REPOMAN_DIR}/generate_release.sh" > Release

    /usr/bin/echo -e "\nBCLD repository packages successfully scanned!\n"
}

# Function to init PKG_REPORT
function init_report () {
    if [[ -f ${PKG_REPORT} ]]; then
        /usr/bin/echo
        /usr/bin/echo "Found old artifact: ${PKG_REPORT}! Removing..."
        /usr/bin/rm -vf ${PKG_REPORT}
    fi
    
    /usr/bin/echo
    /usr/bin/echo 'Scanning packages:'
    /usr/bin/echo '# Package List' >> "${PKG_REPORT}"
    /usr/bin/echo "## ${BCLD_VERSION_STRING}" >> "${PKG_REPORT}"
    /usr/bin/echo "## TOTAL: ${EVERYTHING_TOTAL}" >> "${PKG_REPORT}"
}

# Function to add to package list
function add_pkg_list (){
    /usr/bin/echo -e "${1}" >> "${PKG_LIST}"
}

# Function to scan for information about all packages in ./config.
function apt_show () {
    /usr/bin/apt-cache show "${PKG}" | /usr/bin/grep -m1 "${1}" | /usr/bin/cut -d "${2}" -f2 | /usr/bin/awk '{$1=$1};1'
}

# Function to scan for simple description
function apt_show_description () {
    description_en="$(/usr/bin/apt-cache search --names-only "^${PKG}$" | /usr/bin/head -1)"
    
    if [[ -z "${description_en}" ]]; then
        # If not found, use 'show' intead
        count=16
        description_en="$(/usr/bin/apt-cache show "${PKG}" | /usr/bin/grep -m1 'Description-en')"
    else
        # If found, cut label and delimiter
        count=$(( "${#PKG}" + 3 ))
    fi
    
    # If STILL empty, probably a virtual pacakge
    if [[ -z "${description_en}" ]]; then
        description_en='VIRTUAL PACKAGE'
    fi
    
    add_pkg_list "   Description:\t\"${description_en:$count}\""
}

# Function to scan for information about all packages in ./config.
function scan_pkgs () {
    EVERYTHING_COUNTER=1
    
    if [[ -f ${PKG_LIST} ]];then
        /usr/bin/echo "PKG_LIST found!"
        /usr/bin/rm -vf "${PKG_LIST}"
    fi

    init_report
    
    ## Generate entries
    for PKG in ${EVERYTHING_UNIQUE};do

        /usr/bin/echo " └> (${EVERYTHING_COUNTER}/${EVERYTHING_TOTAL}) ${PKG}"
        if [[ -n "$(/usr/bin/apt-mark showauto "${PKG}")" ]]; then
            status="Dependency"
        else
            status="REQUIRED"
        fi

        hash="$(apt_show 'Description-md5' ':')"
        homepage="$(apt_show 'Homepage' ' ')"
        file_name="$(apt_show 'Filename' ':')"
        maintainer="$(apt_show 'Maintainer' ':')"
        version="$(apt_show 'Version' ' ')"

        add_pkg_list " * (${EVERYTHING_COUNTER})"
        add_pkg_list "   Name:\t${PKG}"
        apt_show_description
        add_pkg_list "   Filename:\t${file_name}"
        add_pkg_list "   Version:\t${version}"
        add_pkg_list "   Status:\t${status}"
        add_pkg_list "   Maintainer:\t${maintainer}"
        add_pkg_list "   md5sum:\t${hash}"
        add_pkg_list "   Homepage:\t${homepage}"
        add_pkg_list
        #/usr/bin/echo -e " * (${EVERYTHING_COUNTER}) \`${PKG}\` [${status}]:\t${description^}" >> "${PKG_LIST}"
        ((EVERYTHING_COUNTER++))
    done
    
    /usr/bin/cat "${PKG_LIST}" >> "${PKG_REPORT}"
    
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo 'Package lists scanned!'
    /usr/bin/echo "Package information saved to ${PKG_REPORT}."
    /usr/bin/echo
}

# Function to sign existing repository
function sign_repo () {
    if [[ -f ${CERT_DIR}/pgp-key.private  ]];then
        /usr/bin/echo 
        /usr/bin/echo "Importing GPG private key..."
        /usr/bin/cat "${CERT_DIR}/pgp-key.private" | gpg --import
        
        /usr/bin/echo
        /usr/bin/echo "Signing Release file..."
        /usr/bin/cat "${STABLE_DIR}/Release" \
            | gpg --default-key "${GPG_KEY}" --armor --detach-sign --sign \
            > "${STABLE_DIR}/Release.gpg" \
            && /usr/bin/echo "Signed: ${STABLE_DIR}/Release.gpg" \
            || /usr/bin/echo "Release signing failed!"
        
        /usr/bin/echo
        /usr/bin/echo "Signing InRelease file..."
        /usr/bin/cat "${STABLE_DIR}/Release" \
            | gpg --default-key "${GPG_KEY}" --armor --detach-sign --sign --clearsign \
            > "${STABLE_DIR}/InRelease" \
            && /usr/bin/echo "Signed: ${STABLE_DIR}/InRelease" \
            || /usr/bin/echo "InRelease signing failed!"
    else
        /usr/bin/echo
        /usr/bin/echo "No GPG keys found in ${CERT_DIR}..."
    fi
}

# Function to search virtual packages
function search_aptitude () {
    /usr/bin/echo
    /usr/bin/echo "Please enter the name of a virtual package:"
    read -r aptitude_package
    /usr/bin/echo "Searching packages which provide ${aptitude_package}"
    aptitude search "~P${aptitude_package}"
}

# Convenience script to unpack repo
function deploy_repo () {
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo "Deploying repo to ${WEB_DIR}..."
    /usr/bin/echo
    /usr/bin/echo
    rsync -uahHAX --info=progress2 "${REPO_HUB}/${REPO_NAME}" "${WEB_DIR}"
}

# Clear all created repositories
function clear_repos () {
  # Clear repos and artifacts
  /usr/bin/echo 
  /usr/bin/echo "Performing repo cleanup."
  /usr/bin/echo "Cleaning ${REPO_HUB}..."
  /usr/bin/echo "${repos}"
  /usr/bin/echo "${repo_num}"
  if [[ ${repo_num} -gt 0 ]]; then
    /usr/bin/rm -rf "${REPO_HUB}"/* \
        && /usr/bin/echo -e "\n\nAll repos deleted!\n" || exit
  else
    /usr/bin/echo "No repos found!"
  fi
}

# Count WEB_DIRs
function count_web_dir () {
    web_dir_repos=$(find "${WEB_DIR}" -mindepth 1 -maxdepth 1 -type d)
    web_dir_repo_num=$(/usr/bin/echo "${web_dir_repos}" | wc -w)
    /usr/bin/echo
    /usr/bin/echo "Repos found in WEB_DIR: ${web_dir_repo_num}"
    /usr/bin/echo "${web_dir_repos}"
}

# Clear WEB_DIR
function clear_web_dir () {
    if [[ $web_dir_repo_num -gt 0 ]]; then
        /usr/bin/echo
        /usr/bin/echo "Clearing contents of ${WEB_DIR}..."
        /usr/bin/rm -rf "${WEB_DIR}"/*
    else
        /usr/bin/echo
        /usr/bin/echo "${WEB_DIR} is already empty."
    fi
}

# Function to count packages inside the repo
function count_packages () {
    pkgs_num=$(find "${PKGS_DIR}" -mindepth 1 -maxdepth 1 -type f -name '*.deb' | wc -l)
    /usr/bin/echo
    /usr/bin/echo "Current repository contains: ${pkgs_num} packages!"
    /usr/bin/echo
}


### Repo Manager ###
while [[ ! $done ]]; do
   
    # Always make LOG_DIR
    /usr/bin/mkdir -pv "${LOG_DIR}"
    
    # Substitute sources template with BUILD ENVs
    /usr/bin/echo
    /usr/bin/echo "Substituting ${SOURCES}..."
    /usr/bin/apt-get update &>> "${CHREPOMAN_LOG}"
    /usr/bin/apt-get install -yq gettext-base &>>"${CHREPOMAN_LOG}"
     /usr/bin/envsubst < "${CONFIG_DIR}/apt/sources.list" > "${SOURCES}"
    
    # Sync the new repository 
    /usr/bin/echo "Syncing local meta..."
    /usr/bin/apt-get clean
    /usr/bin/apt-get update -y &>>"${CHREPOMAN_LOG}"
    
    # Check for installed build tools
    /usr/bin/echo "Installing build tools for BCLD Repo Manager. Please wait..."
    /usr/bin/echo ">>> ${BUILD_TOOLS}"
    /usr/bin/echo
    /usr/bin/apt-get install -yq ${BUILD_TOOLS} &>> "${CHREPOMAN_LOG}"
    
    # Welcome message
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo
    /usr/bin/echo '///\\\ --- >>> BCLD RepoMan! <<< --- ///\\\'
    /usr/bin/echo
    /usr/bin/echo
    
    # Check repos early
    check_repos
    
    # Count WEB_DIR early
    count_web_dir

    # Read pointer
    if [[ -n ${POINTER_TYPE} ]]; then
        done=true
    else
        read_pointer
    fi

    case ${POINTER_TYPE} in

    c)
        # Allow second parameter when using Repoman Create.
        /usr/bin/echo
        /usr/bin/echo "Please enter a new BCLD repo name."
        /usr/bin/echo "This is usually the name of the version: 11.0.0"
        /usr/bin/echo
        prep_dirs
        dep_init
        download_now
        /usr/bin/echo -e "\nBCLD repository successfully created!\n"
        count_packages
        ;;

    u)
        /usr/bin/echo
        /usr/bin/echo "Please enter the name of the BCLD repo you wish to update."
        /usr/bin/echo
        update_repo
        sign_repo
        ;;
    
    g)
        sign_repo
        ;;

    o) 
        prep_dirs
        dep_init
        scan_pkgs
        ;;

    d)
        deploy_repo
        ;;

    z)
        zip_repo
        ;;
    
    s)
        search_aptitude
        ;;

    x)
        clear_repos
        ;;
    
    w)
        clear_web_dir
        ;;
    
    q)
        done=true
        ;;

    *)
        /usr/bin/echo 'Possible options are:'
        /usr/bin/echo 'c(reate),'
        /usr/bin/echo 'd(eploy),' 
        /usr/bin/echo 'q(uit).'
        /usr/bin/echo 's(earch),' 
        /usr/bin/echo 'u(pdate),' 
        ;;
    esac
    
    unset pointer
    unset repo_name

done
exit
