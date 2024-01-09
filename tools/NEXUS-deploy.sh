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
#
# Nexus deployment script
# Deploy the artifacts to Nexus

# Source BUILD_CONFIG, for name conventions
source './config/BUILD.conf'
source './script/echo_tools.sh'
source './script/file_operations.sh'

# VARs
TAG='BUILD-NEXUS'
BCLD_ARTIFACT="./artifacts/${BCLD_VERSION_FILE}.img" # Path to artifact

# Functions
function deploy_nexus () {
    
    # Always check IMG SIZE and never deploy faulty images
    check_img_size "${BCLD_ARTIFACT}"
    
    list_header "Deploying IMG to Nexus"
    list_item "The file is: ${1}"
    list_item "Size: $(/usr/bin/du -h ${1})"
    list_item "Target: ${2}"
    list_entry
    /usr/bin/curl -u "${BAMBOONEXUSUPLOADUSER}":"${BAMBOONEXUSUPLOADPASSWORD}" \
    --upload-file ${1} \
    --url "${2}" \
    && list_item "Successfully deployed!"
    
    on_completion
}

# This step requires Bamboo credentials
deploy_nexus "${BCLD_ARTIFACT}" "${BCLD_NEXUS_STRING}"
