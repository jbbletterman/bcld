#!/bin/bash
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
# BCLD App
# This script launches the app inside a Openbox session.
#
#set -x

#ENVs
TAG="RUN-APP"

# Execute logging without sudo, or it's useless
/usr/bin/client_logger.sh

# Launch X configuration script. It's copied inside /usr/bin.
/usr/bin/Xconfigure.sh

# For automatic certificate selection
/usr/bin/autocert.sh

# Afname debug params:
PID="$!"
NW_LOG_FILE="/home/${BCLD_USER}/logfile.${PID}.log"
NW_NET_LOGFILE="/home/${BCLD_USER}/net-log.${PID}.json"

export NW_PRE_ARGS
NW_PRE_ARGS="--lang=nl --disable-gpu --enable-logging --log-file=${NW_LOG_FILE} --v=9 --log-net-log=${NW_NET_LOGFILE}"

# Launch app with BCLD_OPTS
/usr/bin/bash -c "${BCLD_APP} ${BCLD_OPTS}" &> "${OPENBOX_LOG}" &

