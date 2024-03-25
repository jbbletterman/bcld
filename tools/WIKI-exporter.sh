#!/bin/bash
# Script for exporting the BCLD Wiki into an artifact

source ./script/file_operations.sh
source ./script/echo_tools.sh

TAG='WIKI-EXPORT'

if [[ -x ./tools/WIKI-exporter.sh ]]; then
    ART_DIR="${PWD}/artifacts"
    prep_dir "${ART_DIR}"
else
    list_item_fail 'Please run this script from the project root directory!'
    on_failure
fi

if [[ -d ./modules ]]; then
    cd ./modules || exit 1
        list_header "Starting Wiki Exporter"
        list_entry
        /usr/bin/zip -r -b "${ART_DIR}/bcld.wiki.zip" modules/bcld.wiki && list_catch && on_completion
    cd - || exit 1
else
    list_item_fail 'Module directory does not exist!'
    on_failure
fi
