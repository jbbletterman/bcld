#!/bin/bash

# Send all necessary files to the PXE server
PXE_SERVER="${1}"

if [[ -z "${PXE_SERVER}" ]]; then

    /usr/bin/echo -e "\nUsing URL: ${PXE_SERVER}\n"

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

else
    /usr/bin/echo -e '\nPlease supply a URL...\n'
fi