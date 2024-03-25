#!/bin/bash
# Script for exporting the BCLD Wiki into an artifact

set -e

source ./script/file_operations.sh
source ./script/echo_tools.sh

TAG='WIKI-EXPORT'

list_header "Starting Wiki Exporter"

if [[ -x ./tools/WIKI-exporter.sh ]]; then
    ART_DIR="${PWD}/artifacts"
    prep_dir "${ART_DIR}"
else
    list_item_fail 'Please run this script from the project root directory!'
    on_failure
fi

if [[ -d ./modules ]]; then
    cd ./modules
        list_entry
        /usr/bin/zip -r "${ART_DIR}/bcld.wiki.zip" bcld.wiki \
        && list_catch \
        && on_completion \
        || list_catch \
        && list_item_fail 'Module directory is empty!' \
        && on_failure
    cd -
else
    list_item_fail 'Module directory does not exist!'
    on_failure
fi
