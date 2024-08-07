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
# BCLD VendorSelect
# Script for configuring BCLD system based on BCLD_VENDOR boot parameter.
#
# Enable Rsyslog service ONLY for Facet
#
# IMPORT
source /usr/bin/echo_tools.sh

TAG='BCLD-VENDOR'

# ENVs
BCLD_HOME="/home/${BCLD_USER}"
CA_CERT_NAME='ca.crt'
CLIENT_CRT_NAME='bcld.crt'
CLIENT_KEY_NAME='bcld.key'
PUB_PKI_DIR='/usr/share/ca-certificates'

export NSSDB="${BCLD_HOME}/.pki/nssdb"

# FUNCTIONS

## To set hashes
function hash_bcld_cert () {
	
	## Move into '/etc/ssl/certs' and link the added CA as CERT_NAME
	cd /etc/ssl/certs

	# ENVs
	CA_CRT="${PUB_PKI_DIR}/${BCLD_VENDOR}/${CA_CERT_NAME}"
	CLIENT_CRT="${PUB_PKI_DIR}/${BCLD_VENDOR}/${CLIENT_CRT_NAME}"
	CLIENT_KEY="${PUB_PKI_DIR}/${BCLD_VENDOR}/${CLIENT_KEY_NAME}"

	list_item 'Generating OpenSSL hashes...'
	CA_HASH="$(/usr/bin/openssl x509 -noout -hash -in "${CA_CRT}")"
	CLIENT_HASH="$(/usr/bin/openssl x509 -noout -hash -in "${CLIENT_CRT}")"

	list_item 'Generating SSL links...'
	/usr/bin/ln -sf "${CA_CRT}" "${CA_CERT_NAME}"
	/usr/bin/ln -sf "${CA_CERT_NAME}" "${CA_HASH}"
	/usr/bin/ln -sf "${CLIENT_CRT}" "${CLIENT_CRT_NAME}"
	/usr/bin/ln -sf "${CLIENT_CRT_NAME}" "${CLIENT_HASH}"
	/usr/bin/ln -sf "${CLIENT_KEY}" "${CLIENT_KEY_NAME}"

	cd - &> /dev/null
}

# Update certificate store
function update_cert () {
	list_item "Updating the certificate store..."
	/usr/sbin/update-ca-certificates &> /dev/null
}


## To set NSSDB
function set_bcld_nssdb () {
	
	list_item "Configuring certificate database for: ${BCLD_VENDOR^^}"
	
	if [[ "${BCLD_VERBOSE}" -eq 1 ]]; then
	    list_entry
	    /usr/bin/mkdir -pv "${NSSDB}"
	    /usr/bin/cp -v ${BCLD_HOME}/nssdb/${BCLD_VENDOR}/{cert9.db,key4.db,pkcs11.txt} "${NSSDB}"
	    /usr/bin/chown -Rv "${USER}:${USER}" "${NSSDB}"
	    list_catch
    else
	    /usr/bin/mkdir -p "${NSSDB}"
	    /usr/bin/cp ${BCLD_HOME}/nssdb/${BCLD_VENDOR}/{cert9.db,key4.db,pkcs11.txt} "${NSSDB}"
	    /usr/bin/chown -R "${USER}:${USER}" "${NSSDB}"
	    list_item_pass 'NSSDB installation complete!'
	fi
}

## To get certificates
function get_bcld_nssdb () {
	
	# Check for CRT
	if [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -L | /usr/bin/grep -c "${1}")" -gt 0 ]]; then
		list_item_pass "${BCLD_VENDOR} certificate detected!"
	fi

	# Check for KEY
	if [[ "$(/usr/bin/certutil -d "sql:${NSSDB}" -K | /usr/bin/grep -c "${1}")" -gt 0 ]]; then
		list_item_pass "${BCLD_VENDOR} key detected!"
	fi
}

## To fix permissions of selected certs
function fix_bcld_perms () {
    list_item "Fixing NSSDB permissions..."
	/usr/bin/chown -R "${BCLD_USER}:${BCLD_USER}" "${NSSDB}" || exit 1
}


# EXE

list_item 'Starting BCLD Vendor script...'

if [[ "${BCLD_VENDOR}" == 'facet' ]]; then
	hash_bcld_cert
	set_bcld_nssdb
	fix_bcld_perms
	get_bcld_nssdb 'facet.onl'
	update_cert
elif [[ "${BCLD_VENDOR}" == 'wft' ]]; then
	
	# Configure certificates for WFT, but disable remote logging
	hash_bcld_cert
	set_bcld_nssdb
	fix_bcld_perms
	get_bcld_nssdb 'duo.nl'
	update_cert
fi
