#!/bin/bash
# Script for diffing BCLD-SBOM

PKG_LIST="${ART_DIR}/PKGS_ALL"

for package in ${PKG_LIST}; do
    pkg="$(/usr/bin/basename "${package}")"
    /usr/bin/echo "${pkg}"
done
