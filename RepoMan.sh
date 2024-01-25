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
# Dockerized BCLD Repo Manager
#
# Runs [RepoMan](./tools/bcld-repo-manager/repository_manager.sh) inside Docker with mounts
# Can also be ran with arguments:
# 1: Pointer Type (u,g,o,d,z,s,x,w,q)
# 2: Repository Name (BCLD_CODE_NAME and BCLD_PATCH by default)

# VARs
CONTAINER='RepoMan'
REPOMAN='/project/tools/bcld-repo-manager/repository_manager.sh'

# Check if script is executed in project directory
# Also set critical variables.
if [[ -f "$(pwd)"/RepoMan.sh ]]; then
    project_dir=$(pwd)
    config_dir="${project_dir}/config"
    source "${config_dir}/BUILD.conf" || exit 1
else
    echo -e "Please run script inside project directory!\n"
    exit
fi

echo
echo "Starting Docker..."

# Detect arguments

## Selection
if [[ ${1} ]]; then
    echo "Arguments detected: "
    echo "Type: ${1}"
fi

## Repo Name
if [[ ${2} ]]; then
    echo "Name: ${2}"
fi

## Download immediately
if [[ ${3} ]]; then
    echo "Download immediately: ${3}"
fi

# Create Docker image or run existing one
if [[ $(/usr/bin/docker ps -a | /usr/bin/grep -c "${CONTAINER}") -gt 0 ]]; then
	# Start Docker
	echo "Starting local Docker image..."
	/usr/bin/docker container start "${CONTAINER}"
	/usr/bin/docker container exec -it "${CONTAINER}" "${REPOMAN}"
else
	# Create Docker image
	echo "No Docker image found! Creating..."
	/usr/bin/docker container run -ti \
		--name "${CONTAINER}" \
		-v "${project_dir}":/project:rw \
		-v "${WEB_DIR}":"${WEB_DIR}":rw \
		-v "${TMPDIR}":"${TMPDIR}":rw \
		-w /project \
		ubuntu:"${CODE_NAME}" bash -c "${REPOMAN}" "${1}" "${2}" "${3}"
fi
    


exit
