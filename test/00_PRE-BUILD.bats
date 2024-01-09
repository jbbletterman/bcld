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
# Copyright © 2023 Quintor B.V.
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
# Pre-build Bash tests
# Use BATS to test ENVs and prepare to build a TEST image
#
## Setup
setup() {
	load 'common-setup'
    _common_setup
    
    TEST_FILE='BATS-RUN.test'

	/usr/bin/touch "./test/${TEST_FILE}"
    
}

## Teardown
teardown() {
    rm -f './test/BATS-RUN.test'
}

# Functions

## Function to check installed packages
check_installed_pkgs() {
	/usr/bin/dpkg --get-selections "${1}"
}

## Function to check all hashes
check_bcld_md5() {
    /usr/bin/md5sum --check "${BCLD_MD5}"
}

## Function to check top hash
check_md5_sum() {
    /usr/bin/md5sum --check test/md5sum \
    	|| /usr/bin/echo 'FAILED!'
}

## Function to query DNS
dns_check() {
	/usr/bin/dig 'archive.ubuntu.com'
	#/usr/bin/dig 'http://blondelle.quintor.local'
	/usr/bin/dig 'github.com'
	/usr/bin/dig 'hub.docker.com'
	/usr/bin/dig 'nexus.quintor.nl'
}

## Function to ping important services
bcld_pings() {
	/usr/bin/ping -c 1 -W 5 'archive.ubuntu.com'
	/usr/bin/ping -c 1 -W 5 'github.com'
	/usr/bin/ping -c 1 -W 5 'hub.docker.com'
	/usr/bin/ping -c 1 -W 5 'nexus.quintor.nl'
}

## Function to send empty files to Nexus
bcld_dry_nexus() {

	if [[ -z "${BCLD_REPO}" ]] \
		&& [[ -z "${BAMBOONEXUSUPLOADUSER}" ]] \
		&& [[ -z "${BAMBOONEXUSUPLOADPASSWORD}" ]];then
			skip 'Not running in Bamboo ENV...'
	fi

	# This step requires Bamboo Nexus credentials
	curl -u "${BAMBOONEXUSUPLOADUSER}":"${BAMBOONEXUSUPLOADPASSWORD}" \
    	--upload-file "./test/${TEST_FILE}" \
    	--url "${BCLD_REPO}/${TEST_FILE}" \
    	|| /usr/bin/echo 'FAILED!'
}

## Function to send empty files to PXE
bcld_dry_pxe() {

	if [[ -z "${PXE_URL}" ]] && [[ -z "${APACHE_SECRET}" ]];then
			skip 'Not running in Bamboo ENV...'
	fi

	# This step requires Bamboo PXE credentials
	curl -u "apache:${APACHE_SECRET}" \
        --upload-file "./test/${TEST_FILE}" \
        --url "${PXE_URL}" \
    	|| /usr/bin/echo 'FAILED!'
}

## Function to check if ENVs are set
env_check() {
    if [[ -z ${BCLD_MODEL} ]] && [[ -z ${BCLD_SECRET} ]];then
    	/usr/bin/echo 'BCLD ENVs missing!'
    fi
}

## Function to check if NSSDBs are accessible for Facet
scan_nssdb_facet() {
	/usr/bin/certutil -d "sql:config/nssdb/facet" -L
	/usr/bin/certutil -d "sql:config/nssdb/facet" -K
}

## Function to check if NSSDBs are accessible for WFT
scan_nssdb_wft() {
	/usr/bin/certutil -d "sql:config/nssdb/wft" -L
	/usr/bin/certutil -d "sql:config/nssdb/wft" -K
}

# Tests

## Test for ENVs
@test 'ENV Checker' {
	run env_check
    refute_output --partial 'BCLD ENVs missing!'
}

## Test for DNS records
@test 'Testing DNS' {
	run dns_check
    refute_output --partial 'ANSWER: 0'
    assert_output --partial 'ANSWER SECTION:'
}

## Test for checking available services
@test 'Uplink' {
	run bcld_pings
    refute_output --partial 'failure in name resolution'
    assert_output --partial '0% packet loss'
}

## Test top MD5-hash
@test 'Repo Integrity' {
    run check_md5_sum
    refute_output --partial 'FAILED'
}

## Test repo MD5-hashes
@test 'File Integrity' {
    run check_bcld_md5
    refute_output --partial 'FAILED'
}

## Test to check if Nexus can be reached
@test 'Dry-Run (Nexus)' {
    run bcld_dry_nexus
    refute_output --partial 'FAILED!'
}

## Test to check if PXE can be reached
@test 'Dry-Run (PXE)' {
    run bcld_dry_pxe
    refute_output --partial 'FAILED!'
}

## Test for checking BUILD packages
@test "Bamboo DEBs" {
    for pkg in $(cat ./config/packages/BUILD); do
		run check_installed_pkgs "${pkg}"
        refute_output --partial 'no packages found'
        assert_output --partial 'install'
    done
}

## Test if NSSDBs are accessible for Facet
@test "FacetDB" {
	run scan_nssdb_facet
    assert_output --partial 'bcld.facet.onl'
    assert_output --partial 'Dienst Uitvoering Onderwijs'
    assert_output --partial '84180586b3bffaa130e698f7ad64a895c19c4a20'

}

## Test if NSSDBs are accessible for WFT
@test "WftDB" {
	run scan_nssdb_wft
    assert_output --partial 'bsb.duo.nl'
    assert_output --partial 'Staat der Nederlanden'
    assert_output --partial '49966f66ab090bd24616ca028007b506cbb8b902'

}
