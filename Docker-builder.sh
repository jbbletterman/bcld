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
# Docker builder
# Script to run ./script/docker_run.sh inside a local Docker 
# container and generate a BCLD-IMG from within.

source './script/echo_tools.sh'
source './config/BUILD.conf'

TAG="DOCKER-LOCAL"

# Functions
function clean_docker () {
	if [[ $(/usr/bin/docker ps -a -q | /usr/bin/wc -l) -gt 0 ]]; then
		list_header 'Detected old Docker images!'
		list_item 'Stopping....'
		/usr/bin/docker stop $(/usr/bin/docker ps -a -q)
		list_item 'Cleaning....'
		list_entry
		/usr/bin/docker rm $(/usr/bin/docker ps -a -q)
		list_catch
	fi
}


list_header "Initializing local Docker ISO-build"

if [[ -f "$(pwd)/Docker-builder.sh" ]]; then
    BCLD_DIR="$(pwd)"
else
    last_item "Please run ${0} inside project directory!"
    exit 1
fi

list_item "Preparing to build: ${BCLD_VERSION_STRING}..."

if [[ -s /usr/bin/docker ]]; then
	# If Docker is installed, clean it up first
	clean_docker
	list_entry
	/usr/bin/docker run -ti --rm --privileged \
	-e BCLD_APP="${BCLD_APP}" \
	-e BCLD_CFG_EDIT="${BCLD_CFG_EDIT}" \
	-e BCLD_MODEL="${BCLD_MODEL}" \
	-e BCLD_NVIDIA="${BCLD_NVIDIA}" \
	-e BCLD_PKG_EXTRA="${BCLD_PKG_EXTRA}" \
	-e BCLD_TAG_EXTRA="${BCLD_TAG_EXTRA}" \
	-e FACET_SECRET_1="${FACET_SECRET_1}" \
	-e FACET_SECRET_2="${FACET_SECRET_2}" \
	-e FACET_SECRET_3="${FACET_SECRET_3}" \
	-e FACET_SECRET_4="${FACET_SECRET_4}" \
	-e WFT_SECRET_1="${WFT_SECRET_1}" \
	-e WFT_SECRET_2="${WFT_SECRET_2}" \
	-e BCLD_PKG_EXTRA="${BCLD_PKG_EXTRA}" \
	-e BCLD_TAG_EXTRA="${BCLD_TAG_EXTRA}" \
	-e BCLD_SECRET="${BCLD_SECRET}" \
	-v /dev:/dev \
	-v /run:/run:rw \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ${BCLD_DIR}:/project:rw \
	-w /project \
	ubuntu:${CODE_NAME} bash -c \
		'/project/script/docker_run.sh'
else
    list_item "Please run ${0} with Docker installed!"
    list_entry
	read -p 'Install now? y/N: ' install_docker
	list_catch
	if [[ ${install_docker} == 'y' ]]; then
		list_item 'Installing Docker, this may take a while...'
		list_entry
		# Can only work in sudo
		bash -c '/usr/bin/sudo ./tools/DOCKER-install.sh'
	else
		on_failure
	fi
fi
