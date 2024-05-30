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
# BCLD Rsyslogger
# Script for offloading BCLD logging to FAO servers with Rsyslogging enabled.
# Commands here cannot run in sudo immediately after booting, 
# because sudo needs a hostname reset.
# The sudo commands in this script will only be triggered when a FAO 
# detection has reset the hostname.

source '/bin/log_tools.sh'

# ENVs
export BCLD_SYSLOG_PORT='6514'

FILE_NAME='60-BCLD-rsyslog.conf'
INPUT_FILE='/opt/remotelogging/input.json'
RSYS_CONF="/etc/rsyslog.d/${FILE_NAME}"
RSYS_TEMPLATE="${HOME}/${FILE_NAME}"
RSYS_TEMP_FILE="${RSYS_TEMPLATE}.tmp"

BCLD_LOGFILE="/opt/bcld_log.json"
BCLD_LOG_RSYSLOG_CONF="70-bcld-log.conf"
BCLD_LOG_RSYSLOG_DEST="/etc/rsyslog.d/${BCLD_LOG_RSYSLOG_CONF}"
BCLD_LOG_RSYSLOG_SRC="${HOME}/${BCLD_LOG_RSYSLOG_CONF}"

/usr/bin/inotifywait --quiet "$(/usr/bin/dirname ${INPUT_FILE} )" -e create --include 'input.json' |
    while read dir action file; do
        
        log_line 'FAO INPUT_FILE DETECTED!!!'
        log_line "${file} appeared in ${dir} by ${action}"
		if [ -z "${BCLD_FAO}" ]; then
			export BCLD_FAO=$(/usr/bin/cat "${INPUT_FILE}" | /usr/bin/jq '.hostAndPort' | cut -d \" -f2)
		fi

		# Restart Rsyslog with BCLD_FAO
		log_line "Checking port ${BCLD_SYSLOG_PORT} on ${BCLD_FAO} for encrypted Rsyslog"
		/usr/bin/envsubst < "${RSYS_TEMPLATE}" > "${RSYS_TEMP_FILE}"
		/usr/bin/sudo /usr/bin/cp "${RSYS_TEMP_FILE}" "${RSYS_CONF}"

		if [ -e "$BCLD_LOGFILE" ]; then
			/usr/bin/sudo /usr/bin/cp "${BCLD_LOG_RSYSLOG_SRC}" "${BCLD_LOG_RSYSLOG_DEST}"
		fi

		# Restart the service
		/usr/bin/sudo /usr/bin/systemctl restart rsyslog.service
		# Wait for service to restart before pushing entries
		/usr/bin/sleep 5s
		/usr/bin/sudo /usr/bin/client_logger.sh 
    done
