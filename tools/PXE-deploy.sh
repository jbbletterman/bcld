#!/bin/bash
#
# Copyright © 2025 Quintor B.V.
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
# Copyright © 2025 Quintor B.V.
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
# Exit immediately if something's wrong
set -e

/usr/bin/echo -e "\nStarting BCLD PXE-deployment script..."

# Send all necessary files to the PXE server
PXE_SERVER="${1}"
ART_DIR='./artifacts'
ISO="${ART_DIR}/bcld.iso"
RAMFS="${ART_DIR}/initrd"
KERNEL="${ART_DIR}/vmlinuz"
VERSION="${ART_DIR}/VERSION"

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

    ## VERSION
    upload_msg "${KERNEL}"
    /usr/bin/curl \
        --upload-file "${VERSION}" \
        --url "${PXE_SERVER}/VERSION"

    /usr/bin/echo -e 'PXE deployment complete!\n'
elif [[ -z "${PXE_SERVER}" ]]; then
    /usr/bin/echo -e 'Please supply a URL...\n'
else
    /usr/bin/echo -e 'Please make sure all artifacts are available: bcld.iso, initrd, and vmlinuz...\n'
fi