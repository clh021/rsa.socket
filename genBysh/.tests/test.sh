#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SHELL_PATH="$( cd "$(dirname "$0")" && pwd -P )"
ROOT_PATH="$( cd "${SHELL_PATH}/.." && pwd -P )"
TEST_PATH="$( cd "${SHELL_PATH}/../../bin/" && pwd -P )"
# shellcheck disable=SC1090
. "${SHELL_PATH}/.lib.sh"


# -------------------------------------------------------------------------------------------------
# Pre-check
# -------------------------------------------------------------------------------------------------

###
### Clean-up for new round
###
rm -rf "${TEST_PATH}/tmp"
mkdir "${TEST_PATH}/tmp"


###
### Do we test in Docker container?
###
USE_DOCKER=0
if [ "${#}" = "1" ]; then
	USE_DOCKER=1
fi


# -------------------------------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------------------------------


###
### General
###
DOCKER_NAME="devilbox_openssl_server"
DOCKER_IMAGE="debian:buster-slim"
OPENSSL_PORT=4433


###
### Certificate Authority
###
CA_NAME="lianghong.top"
CA_KEYSIZE=2048
CA_VALIDITY=3650

CA_KEY_NAME="ca.key"
CA_KEY_PATH="${TEST_PATH}/tmp/${CA_KEY_NAME}"
CA_CRT_NAME="ca.crt"
CA_CRT_PATH="${TEST_PATH}/tmp/${CA_CRT_NAME}"


###
### Certificate
###
CERT_NAME="lianghong"
CERT_KEYSIZE=2048
CERT_VALIDITY=400

CERT_NAME="cert"
CERT_KEY_NAME="${CERT_NAME}.key"
CERT_KEY_PATH="${TEST_PATH}/tmp/${CERT_NAME}.key"
CERT_CSR_PATH="${TEST_PATH}/tmp/${CERT_NAME}.csr"
CERT_CRT_NAME="${CERT_NAME}.crt"
CERT_CRT_PATH="${TEST_PATH}/tmp/${CERT_NAME}.crt"

CLIENT_NAME="client"
CLIENT_PFX_PASS="test"
CLIENT_KEY_PATH="${TEST_PATH}/tmp/${CLIENT_NAME}.key"
CLIENT_CSR_PATH="${TEST_PATH}/tmp/${CLIENT_NAME}.csr"
CLIENT_CRT_PATH="${TEST_PATH}/tmp/${CLIENT_NAME}.crt"
CLIENT_PFX_PATH="${TEST_PATH}/tmp/${CLIENT_NAME}.pfx"


# -------------------------------------------------------------------------------------------------
# ENTRYPOINT
# -------------------------------------------------------------------------------------------------

echo
echo "# -------------------------------------------------------------------------------------------------"
echo "# Creating Certificate Authority"
echo "# -------------------------------------------------------------------------------------------------"
echo
run "${ROOT_PATH}/bin/ca-gen \
-v \
-k ${CA_KEYSIZE} \
-d ${CA_VALIDITY} \
-n ${CA_NAME} \
-c DE \
-s Berlin \
-l Berlin \
-o DevilboxOrg \
-u DevilboxUnit \
-e ca@${CA_NAME} \
${CA_KEY_PATH} \
${CA_CRT_PATH}"

# Verify CRT
echo
echo "[INFO] Verify CRT"
run "openssl x509 -noout -in ${CA_CRT_PATH}"
echo

# Verify KEY
echo
echo "[INFO] Verify KEY"
run "openssl rsa -check -noout -in ${CA_KEY_PATH}"

# Check that KEY matches CRT
echo
echo "[INFO] Verify KEY matches CRT"
run "diff -y \
<(openssl x509 -noout -modulus -in ${CA_CRT_PATH} | openssl md5) \
<(openssl rsa -noout -modulus -in ${CA_KEY_PATH} | openssl md5)"


echo
echo "# -------------------------------------------------------------------------------------------------"
echo "# Creating Certificate"
echo "# -------------------------------------------------------------------------------------------------"
echo

run "${ROOT_PATH}/bin/cert-gen \
-v \
-k ${CERT_KEYSIZE} \
-d ${CERT_VALIDITY} \
-n ${CERT_NAME} \
-c DE \
-s Berlin \
-l Berlin \
-o SomeOrg \
-u SomeUnit \
-e cert@${CERT_NAME} \
-a '*.${CERT_NAME},*.dev.${CERT_NAME},www.${CERT_NAME}' \
${CA_KEY_PATH} \
${CA_CRT_PATH} \
${CERT_KEY_PATH} \
${CERT_CSR_PATH} \
${CERT_CRT_PATH}"

# Verify CRT
echo
echo "[INFO] Verify CRT"
run "openssl x509 -noout -in ${CERT_CRT_PATH}"

# Verify KEY
echo
echo "[INFO] Verify KEY"
run "openssl rsa -check -noout -in ${CERT_KEY_PATH}"

# Verify CSR
echo
echo "[INFO] Verify CSR"
run "openssl req -noout -verify -in ${CERT_CSR_PATH}"

# Check that KEY matches CRT
echo
echo "[INFO] Verify KEY matches CRT"
run "diff -y \
<(openssl x509 -noout -modulus -in ${CERT_CRT_PATH} | openssl md5) \
<(openssl rsa -noout -modulus -in ${CERT_KEY_PATH} | openssl md5)"

# Check that KEY matches CSR
echo
echo "[INFO] Verify KEY matches CSR"
run "diff -y \
<(openssl x509 -noout -modulus -in ${CERT_CRT_PATH} | openssl md5) \
<(openssl req -noout -modulus -in ${CERT_CSR_PATH} | openssl md5)"

# Check certificate is issued by CA
echo
echo "[INFO] Verify certificate is issued by CA"
run "openssl verify -verbose -CAfile ${CA_CRT_PATH} ${CERT_CRT_PATH}"



echo
echo "# -------------------------------------------------------------------------------------------------"
echo "# Creating Client Certificate"
echo "# -------------------------------------------------------------------------------------------------"
echo

run "${ROOT_PATH}/bin/cert-gen \
-v \
-k ${CERT_KEYSIZE} \
-d ${CERT_VALIDITY} \
-n ${CERT_NAME} \
-c DE \
-s Berlin \
-l Berlin \
-o SomeOrg \
-u SomeUnit \
-e cert@${CERT_NAME} \
-a '*.${CERT_NAME},*.dev.${CERT_NAME},www.${CERT_NAME}' \
${CA_KEY_PATH} \
${CA_CRT_PATH} \
${CLIENT_KEY_PATH} \
${CLIENT_CSR_PATH} \
${CLIENT_CRT_PATH}"

# Verify CRT
echo
echo "[INFO] Verify Client CRT"
run "openssl x509 -noout -in ${CLIENT_CRT_PATH}"

# Verify KEY
echo
echo "[INFO] Verify Client KEY"
run "openssl rsa -check -noout -in ${CLIENT_KEY_PATH}"

# Verify CSR
echo
echo "[INFO] Verify Client CSR"
run "openssl req -noout -verify -in ${CLIENT_CSR_PATH}"

# Check that KEY matches CRT
echo
echo "[INFO] Verify Client KEY matches CRT"
run "diff -y \
<(openssl x509 -noout -modulus -in ${CLIENT_CRT_PATH} | openssl md5) \
<(openssl rsa -noout -modulus -in ${CLIENT_KEY_PATH} | openssl md5)"

# Check that KEY matches CSR
echo
echo "[INFO] Verify Client KEY matches CSR"
run "diff -y \
<(openssl x509 -noout -modulus -in ${CLIENT_CRT_PATH} | openssl md5) \
<(openssl req -noout -modulus -in ${CLIENT_CSR_PATH} | openssl md5)"

# Check Client certificate is issued by CA
echo
echo "[INFO] Verify certificate is issued by CA"
run "openssl verify -verbose -CAfile ${CA_CRT_PATH} ${CLIENT_CRT_PATH}"

# Package Client certificate and key as client.pfx
echo
echo "[INFO] Package Client certificate and key as client.pfx (pwd:${CLIENT_PFX_PASS})"
run "openssl pkcs12 -export -in ${CLIENT_CRT_PATH} -inkey ${CLIENT_KEY_PATH} -out ${CLIENT_PFX_PATH} -password pass:${CLIENT_PFX_PASS}"


ERROR=0
if [ "${USE_DOCKER}" = "1" ]; then
	echo
	echo "# -------------------------------------------------------------------------------------------------"
	echo "# Testing browser certificate (inside Docker container)"
	echo "# -------------------------------------------------------------------------------------------------"
	echo

	echo "[INFO] Pulling Docker Image"
	run "docker pull ${DOCKER_IMAGE}"

	echo
	echo "[INFO] Ensuring Docker Image is not running"
	run "docker rm -f ${DOCKER_NAME} >/dev/null 2>&1 || true"

	echo
	echo "[INFO] Starting Docker Image with OpenSSL server"
	run "docker run -d --rm --name ${DOCKER_NAME} -w /data -p '${OPENSSL_PORT}:${OPENSSL_PORT}' -v ${TEST_PATH}/tmp:/data ${DOCKER_IMAGE} sh -c '
		apt-get update -qq &&
		apt-get install -qq -y curl openssl > /dev/null &&
		set -x &&
		openssl s_server -key ${CERT_KEY_NAME} -cert ${CERT_CRT_NAME} -CAfile ${CA_CRT_NAME} -accept ${OPENSSL_PORT} -www' >/dev/null"

	echo
	echo "[INFO] Waiting for Docker container to start"
	run "sleep 5"

	echo
	echo "[INFO] Testing valid https connection with curl"
	if ! run "docker exec -w /data ${DOCKER_NAME} curl -sS -o /dev/null -w '%{http_code}' --cacert ${CA_CRT_NAME} 'https://localhost:${OPENSSL_PORT}' | grep 200" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Testing valid https connection with openssl client"
	if ! run "echo | openssl s_client -verify 8 -CAfile ${CA_CRT_PATH} >/dev/null" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Validating openssl certificate with openssl client"
	if ! run "echo | openssl s_client -verify 8 -CAfile ${CA_CRT_PATH} | grep 'Verify return code: 0 (ok)'" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Show info and clean up"
	run "docker logs ${DOCKER_NAME} || true"
	run "docker rm -f ${DOCKER_NAME} >/dev/null 2>&1 || true"

else
	echo
	echo "# -------------------------------------------------------------------------------------------------"
	echo "# Testing browser certificate (on host system)"
	echo "# -------------------------------------------------------------------------------------------------"
	echo

	echo
	echo "[INFO] Ensuring OpenSSL server is not running"
	run "ps aux | grep openssl | grep s_server | awk '{print \$2}' | xargs kill 2>/dev/null || true"

	echo
	echo "[INFO] Starting OpenSSL server"
	run "openssl s_server -key ${CERT_KEY_PATH} -cert ${CERT_CRT_PATH} -CAfile ${CA_CRT_PATH} -accept ${OPENSSL_PORT} -www >/dev/null &"

	echo
	echo "[INFO] Waiting for OpensSL server to start"
	run "sleep 5"

	echo
	echo "[INFO] Testing valid https connection with curl"
	if ! run "curl -sS -o /dev/null -w '%{http_code}' --cacert ${CA_CRT_PATH} 'https://localhost:${OPENSSL_PORT}' | grep 200" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Testing valid https connection with openssl client"
	if ! run "echo | openssl s_client -verify 8 -CAfile ${CA_CRT_PATH} >/dev/null" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Validating openssl certificate with openssl client"
	if ! run "echo | openssl s_client -verify 8 -CAfile ${CA_CRT_PATH} | grep 'Verify return code: 0 (ok)'" "60"; then
		ERROR=1
	fi

	echo
	echo "[INFO] Clean up"
	run "ps aux | grep openssl | grep s_server | awk '{print \$2}' | xargs kill 2>/dev/null || true"

fi

echo
echo "[INFO] Return success or failure"
exit "${ERROR}"
