#!/bin/bash

# Exit immediately if something's wrong
set -e

/usr/bin/echo -e "\nStarting BCLD PXE-deployment script..."

# Send all necessary files to the PXE server
PXE_SERVER="${1}"
ART_DIR='./artifacts'
ISO="${ART_DIR}/bcld.iso"
RAMFS="${ART_DIR}/initrd"
KERNEL="${ART_DIR}/vmlinuz"

# Message before uploading
function upload_msg () {
    /usr/bin/echo "Uploading file: ${1}"
}

if [[ -n "${PXE_SERVER}" ]] \
    && [[ -f "${ISO}" ]] \
    && [[ -f "${RAMFS}" ]] \
    && [[ -f "${KERNEL}" ]]; then

    /usr/bin/echo "Using URL: ${PXE_SERVER}"

    ## ISO
    upload_msg "${ISO}"
    /usr/bin/curl \
        --upload-file "${ISO}" \
        --url "${PXE_SERVER}/bcld.iso"

    ## RAMFS
    upload_msg "${RAMFS}"
    /usr/bin/curl \
        --upload-file "${RAMFS}" \
        --url "${PXE_SERVER}/initrd"

    ## KERNEL
    upload_msg "${KERNEL}"
    /usr/bin/curl \
        --upload-file "${KERNEL}" \
        --url "${PXE_SERVER}/vmlinuz"

    /usr/bin/echo -e 'PXE deployment complete!\n'
elif [[ -z "${PXE_SERVER}" ]]; then
    /usr/bin/echo -e 'Please supply a URL...\n'
else
    /usr/bin/echo -e 'Please make sure all artifacts are available: bcld.iso, initrd, and vmlinuz...\n'
fi