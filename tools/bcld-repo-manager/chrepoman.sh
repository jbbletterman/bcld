#!/bin/bash
# Script to run inside Dockerized BCLD Repo Manager


### ENVs ###
# Do not ask for confirmations
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

# Paths
BUILD_TOOLS="aptitude dpkg-dev tar gzip rsync"
PROJECT_DIR="/project"
SOURCES="/etc/apt/sources.list"
CONFIG_DIR="${PROJECT_DIR}/config"
REPOMAN_DIR="${PROJECT_DIR}/tools/bcld-repo-manager"
LOG_DIR="${PROJECT_DIR}/log"
CHREPOMAN_LOG="${LOG_DIR}/CHREPOMAN.log"
REPOMAN_LOG="${LOG_DIR}/REPOSITORY_MANAGER.log"
#REPO_TMP="${REPOMAN_DIR}/tmp"

# Once paths are set, source BUILD.conf
source "${CONFIG_DIR}/BUILD.conf" || exit 1

# Create missing directories
if [[ ! -d ${LOG_DIR} ]]; then
    echo
    echo "${LOG_DIR} does not exist. Creating..."
    mkdir -v "${LOG_DIR}" || exit
fi  

# Substitute sources template with BUILD ENVs and make available to Docker
echo
echo "Substituting ${SOURCES}..."
apt-get update &>> "${CHREPOMAN_LOG}"
apt-get install -yq gettext-base &>>"${CHREPOMAN_LOG}"
envsubst < "${CONFIG_DIR}/apt/sources.list" > "${SOURCES}"

# Sync local meta
echo
echo "Syncing local meta..."
apt-get clean
apt-get update -y &>>"${CHREPOMAN_LOG}"

# Install tools for BCLD Repo Manager
echo
echo "Installing build tools for BCLD Repo Manager. Please wait..."
echo ">>> ${BUILD_TOOLS}"
echo
apt-get install -yq ${BUILD_TOOLS} &>> "${CHREPOMAN_LOG}"

# Start BCLD Repo Manager
echo
echo "Starting BCLD Repo Manager..."
cd "${PROJECT_DIR}" || exit

"${REPOMAN_DIR}/repository_manager.sh" "${1}" "${2}" "${3}" | tee ${REPOMAN_LOG}

exit
