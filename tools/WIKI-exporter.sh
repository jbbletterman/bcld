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
# Script for exporting the BCLD Wiki into an artifact

set -e

source ./script/file_operations.sh
source ./script/echo_tools.sh

# VARs
TAG='WIKI-EXPORT'
WIKI_NAME='bcld.wiki'

MOD_PATH="./modules/${WIKI_NAME}"

list_header "Starting Wiki Exporter"

if [[ -x ./tools/WIKI-exporter.sh ]]; then
    ART_DIR="${PWD}/artifacts"
    prep_dir "${ART_DIR}"
else
    list_item_fail 'Please run this script from the project root directory!'
    on_failure
fi

# EXE

## Find the Wiki Homepage that should always exist
#  On failure, it's either empty or doesn't exist
if [[ -f "${MOD_PATH}/Home.md" ]]; then
    cd ./modules
        list_entry
        /usr/bin/zip -r "${ART_DIR}/bcld.wiki.zip" "${WIKI_NAME}"
        list_catch
    cd -
    on_completion
elif [ -d "${MOD_PATH}" ]; then
    list_item_fail 'Wiki directory seems empty!'
else
    list_item_fail 'Wiki directory does not exist!'
    on_failure
fi
