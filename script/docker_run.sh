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
# Docker tools
# Script to run with ./Docker-builder.sh. Checks the 
# environment and configures the container before running
# both ISO-builder.sh and then IMG-builder.sh.

/usr/bin/echo 'Installing packages on build machine, this may take a while...'

# Create a ./log directory if it does not exist
if [[ ! -d ./log ]]; then
    /usr/bin/echo 'Generating log directory...'
    /usr/bin/mkdir -v ./log
fi

# Prepare the container by updating the package lists
/usr/bin/apt-get update | /usr/bin/tee log/APT.log

# Install all dependencies
/usr/bin/apt-get install -y $(/usr/bin/cat /project/config/packages/BUILD) | /usr/bin/tee -a log/APT.log

# Generate the ISO-artifact
./ISO-builder.sh | /usr/bin/tee log/ISO-builder.log

# Generate the IMG-artifact
./IMG-builder.sh | /usr/bin/tee log/IMG-builder.log

# Finish
exit
