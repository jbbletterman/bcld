#!/bin/bash

/usr/bin/echo -e "\nStarting BCLD PXE-deployment script..."

# Send all necessary files to the PXE server
PXE_SERVER="${1}"

if [[ -n "${PXE_SERVER}" ]]; then

    /usr/bin/echo "Using URL: ${PXE_SERVER}"

    ## ISO
    /usr/bin/curl \
        --upload-file "./artifacts/bcld.iso" \
        --url "${PXE_SERVER}/bcld.iso"

    ## RAMFS
    /usr/bin/curl \
        --upload-file "./artifacts/initrd" \
        --url "${PXE_SERVER}/initrd"

    ## KERNEL
    /usr/bin/curl \
        --upload-file "./artifacts/vmlinuz" \
        --url "${PXE_SERVER}/vmlinuz"

    /usr/bin/echo -e 'PXE deployment complete!\n'
else
    /usr/bin/echo -e 'Please supply a URL...\n'
fi