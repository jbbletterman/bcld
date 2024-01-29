#!/bin/bash
# BCLD Repo Manager
# This script requires, `gettext-base`, `aptitude`, `dpkg-dev`, `tee`, `tar` and `gzip`
#set -x
# Can also be ran with variables:
#   - POINTER_TYPE: u,g,o,d,z,s,x,w,q
#   - REPO_NAME: BCLD_CODE_NAME and BCLD_PATCH by default

if [[ -f "$(pwd)"/RepoMan.sh ]]; then
    # Paths
    PROJECT_DIR=$(pwd)
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

## Directories
ART_DIR="${PROJECT_DIR}/artifacts"
CERT_DIR="${PROJECT_DIR}/cert"
LOG_DIR="${PROJECT_DIR}/log"
REPOMAN_DIR="${PROJECT_DIR}/tools/bcld-repo-manager"

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
        if [[ ${1} = "${pkgs_dir}" ]]; then
            /usr/bin/chown _apt "${pkgs_dir}"
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
    PKG_TOTAL="$(wc -l < "${ALL_PKGS}")"

    # DEPs
    if [[ -f "${ALL_DEPS}" ]];then
        /usr/bin/rm "${ALL_DEPS}"
    fi
}

# Function to check repository and set the name if there is just 1
function check_repos () {
  repos=$(find "${REPO_HUB}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
  repo_num=$(/usr/bin/echo "${repos}" | wc -w)
  
  /usr/bin/echo "Checking ${REPO_HUB} for existing repositories..."
  /usr/bin/echo "Repositories detected: ${repos}"
  /usr/bin/echo "Total: ${repo_num}" 
}

# Automatically detect repo name if there is only 1
function auto_repo_name () {
    if [[ -z "${REPO_NAME}" ]] \
        || [[ "${repo_num}" -eq 0 ]]; then
        /usr/bin/echo
        /usr/bin/echo "No repositories found!"
    elif [[ -n "${REPO_NAME}" ]] \
        && [[ "${repo_num}" -eq 1 ]]; then
        /usr/bin/echo "A single repository was detected: (${repos})"
        REPO_NAME="${repos}"        
    fi

    set_repo_name
}

# Set repo name if not set.  
function set_repo_name () {
    if [[ -z ${REPO_NAME} ]]; then
		REPO_NAME="${BCLD_CODE_NAME^^}-${BCLD_PATCH}"
		/usr/bin/echo "Setting repo name: ${REPO_NAME}"
		/usr/bin/echo
    fi

    repo_dir="${REPO_HUB}/${REPO_NAME}"

    pkgs_dir="${repo_dir}/pool/main"
    stable_dir="${repo_dir}/dists/stable"
    data_dir="${stable_dir}/main/binary-amd64"

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

# Download dependencies using /usr/bin/apt-cache
function dep_init () {    
    
    # Download always requires packages lists
    populate_pkg_lists
    
    # Counter
    pkg_count=0
    
    /usr/bin/echo
    /usr/bin/echo "Querying dependencies..."

    cd "${pkgs_dir}" || exit
    while read -r PKG; do
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
    EVERYTHING_TOTAL="$(/usr/bin/echo ${EVERYTHING} | wc -w)"
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
    cd "${repo_dir}" || exit
    dpkg-scanpackages --arch amd64 pool/ > "${data_dir}/Packages"
    /usr/bin/echo "Compressing Packages.gz..."
    /usr/bin/cat "${data_dir}/Packages" | gzip -9 > "${data_dir}/Packages.gz"

    # Generate Release file
    /usr/bin/echo
    /usr/bin/echo "Generating Release file..."
    cd "${stable_dir}/" || exit
    "${REPOMAN_DIR}/generate_release.sh" > Release

    /usr/bin/echo -e "\nBCLD repository packages successfully scanned!\n"
}

# Function to init PKG_REPORT
function init_report () {
    if [[ -f ${PKG_REPORT} ]]; then
        /usr/bin/echo
        /usr/bin/echo "Found old artifact: ${PKG_REPORT}! Removing..."
        /usr/bin/rm -f ${PKG_REPORT}
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
function scan_pkgs () {
    EVERYTHING_COUNTER=0
    PKG_LIST="${TMPDIR}/${REPO_NAME}_PKGS_INFO"
    PKG_LIST_SORT="${TMPDIR}/${REPO_NAME}_PKGS_INFO_SORT"
    PKG_REPORT="${ART_DIR}/${REPO_NAME}_PKGS.md"
    
    if [[ -f ${PKG_LIST} ]];then
        /usr/bin/rm -f "${PKG_LIST}"
    fi

    if [[ -f ${PKG_REPORT} ]];then
        /usr/bin/rm -f "${PKG_REPORT}"
    fi

    init_report
    
    ## Generate entries
    for PKG in ${EVERYTHING};do

        /usr/bin/echo " └> (${EVERYTHING_COUNTER}/${EVERYTHING_TOTAL}) ${PKG}"
        if [[ -n "$(/usr/bin/apt-mark showauto "${PKG}")" ]]; then
            status="Dependency"
        else
            status="REQUIRED"
        fi
        
        PKG_INFO="$(/usr/bin/apt-cache show "${PKG}")"  
        
        description="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep 'Description-en' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
        hash="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep 'Description-md5' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
        homepage="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep 'Homepage' | /usr/bin/cut -d ' ' -f2 | /usr/bin/awk '{$1=$1};1')"
        file_name="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep 'Filename' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
        maintainer="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep -m1 'Maintainer' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
        version="$(/usr/bin/echo "${PKG_INFO}" | /usr/bin/grep 'Version' | /usr/bin/cut -d ':' -f2 | /usr/bin/awk '{$1=$1};1')"
        add_pkg_list "  * (${EVERYTHING_COUNTER}) ${file_name}"
        add_pkg_list "\t${description^}"
        add_pkg_list "\tHomepage:\t${homepage}"
        add_pkg_list "\t${status}:\t${description^}"
        add_pkg_list "\tVersion:\t${version}"
        add_pkg_list "\tStatus\t\t${status}"
        add_pkg_list "\tMaintainer:\t${maintainer}"
        add_pkg_list "\tmd5sum:\t\t${hash}"
        add_pkg_list
        #/usr/bin/echo -e " * (${EVERYTHING_COUNTER}) \`${PKG}\` [${status}]:\t${description^}" >> "${PKG_LIST}"
        ((EVERYTHING_COUNTER++))
    done
    
    /usr/bin/cat "${PKG_LIST}" | sort -u > "${PKG_LIST_SORT}"

    # Generate Markdown file
    while read -r LINE;do
         /usr/bin/echo "${LINE}" >> "${PKG_REPORT}"
         #/usr/bin/echo -e "\n" >> "${PKG_REPORT}"
    done < "${PKG_LIST_SORT}"
    
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
        /usr/bin/cat "${stable_dir}/Release" \
            | gpg --default-key "${GPG_KEY}" --armor --detach-sign --sign \
            > "${stable_dir}/Release.gpg" \
            && /usr/bin/echo "Signed: ${stable_dir}/Release.gpg" \
            || /usr/bin/echo "Release signing failed!"
        
        /usr/bin/echo
        /usr/bin/echo "Signing InRelease file..."
        /usr/bin/cat "${stable_dir}/Release" \
            | gpg --default-key "${GPG_KEY}" --armor --detach-sign --sign --clearsign \
            > "${stable_dir}/InRelease" \
            && /usr/bin/echo "Signed: ${stable_dir}/InRelease" \
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
    pkgs_num=$(find "${pkgs_dir}" -mindepth 1 -maxdepth 1 -type f -name '*.deb' | wc -l)
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

    case $POINTER_TYPE in

    c)
        # Allow second parameter when using Repoman Create.
        /usr/bin/echo
        /usr/bin/echo "Please enter a new BCLD repo name."
        /usr/bin/echo "This is usually the name of the version: 11.0.0"
        /usr/bin/echo

        # Prepare ENVs
        prep_dir "${ART_DIR}" 
        prep_dir "${LOG_DIR}"
        prep_dir "${REPO_HUB}"
        prep_dir "${TMP_PKGS_DIR}"

        # Repo functions
        set_repo_name
        prep_dir "${pkgs_dir}"
        prep_dir "${data_dir}"
        dep_init
        download_now
        /usr/bin/echo -e "\nBCLD repository successfully created!\n"
        count_packages
        ;;

    u)
        /usr/bin/echo
        /usr/bin/echo "Please enter the name of the BCLD repo you wish to update."
        /usr/bin/echo
        auto_repo_name
        update_repo
        sign_repo
        ;;
    
    g)
        auto_repo_name
        sign_repo
        ;;

    o) 
        auto_repo_name
        prep_dir "${TMP_PKGS_DIR}"
        prep_dir "${REPO_HUB}"
        prep_dir "${pkgs_dir}"
        dep_init
        scan_pkgs
        ;;

    d)
        auto_repo_name
        deploy_repo
        ;;

    z)
        auto_repo_name
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
