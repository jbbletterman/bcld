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
# Script for diffing BCLD-SBOM
if [[ -f "$(pwd)"/tools/bcld-repo-manager/SBOM_validate.sh ]]; then
    # Paths
    PROJECT_DIR="$(pwd)"
    CONFIG_DIR="${PROJECT_DIR}/config"

    # Read ENVs from BUILD.conf
    source "${CONFIG_DIR}/BUILD.conf" || exit 1
    source "${PROJECT_DIR}/script/echo_tools.sh" || exit 1
else
    /usr/bin/echo "Please run script inside BCLD root!"
    /usr/bin/echo
    exit
fi

# VARs
ART_DIR="${PROJECT_DIR}/artifacts"
PKG_REPORT="${ART_DIR}/${REPO_NAME}_PKGS.md"
TAG='SBOM-VAL'

# EXE

list_header 'Starting BCLD SBOM Validation...'
list_item "Grabbing package list from ${1}"

## Generate a list of packages from SBOM 1

if [[ -f "${1}" ]]; then
    PKG_LIST="$(/usr/bin/grep 'Name:' ${1})"
else
    list_item_fail "SBOM 1 cannot be empty!"
fi

if [[ ! -f "${2}" ]]; then
    list_item_fail "SBOM 2 cannot be empty!"
fi

for pkg in ${PKG_LIST}; do

    if [[ "${pkg}" == 'Name:' ]]; then
        # Skip garbage entries
        continue
    fi
    
    # Then, compare this list to SBOM 2
    if [[ $(/usr/bin/grep -c $'\t'${pkg} "${2}") -eq 1 ]]; then
        # Split pkg_info for SBOM 1 and SBOM 2
        pkg_info_1="$(/usr/bin/grep -m1 -B1 -A8 $'\t'"${pkg}" "${1}")"
        pkg_info_2="$(/usr/bin/grep -m1 -B1 -A8 $'\t'"${pkg}" "${2}")"
        
        # Split version numbers
        pkg_ver_1="$(/usr/bin/echo "${pkg_info_1}" | /usr/bin/grep 'Version:' | /usr/bin/awk '{ print $2 }')"
        pkg_ver_2="$(/usr/bin/echo "${pkg_info_2}" | /usr/bin/grep 'Version:' | /usr/bin/awk '{ print $2 }')"

        # Always output different version
        if [[ "${pkg_ver_1}" != "${pkg_ver_2}" ]]; then
            list_item_pass "${pkg}"
            list_item_pass ">>> ${pkg_ver_1} >>> ${pkg_ver_2}"
        fi
    else
        # Always fail if SBOM 1 is missing from SBOM 2
        list_item_fail "\"${pkg_basename}\" missing, please check if this is correct!"
    fi
done
