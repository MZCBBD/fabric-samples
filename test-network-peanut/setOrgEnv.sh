#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0




# default to using Did
ORG=${1:-did}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ORDERER_CA=${DIR}/test-network/organizations/ordererOrganizations/byondz.io/tlsca/tlsca.byondz.io-cert.pem
PEER0_DID_CA=${DIR}/test-network/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem
PEER1_DID_CA=${DIR}/test-network/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem
PEER0_BADGE_CA=${DIR}/test-network/organizations/peerOrganizations/badge.byondz.io/tlsca/tlsca.badge.byondz.io-cert.pem
PEER0_ORG3_CA=${DIR}/test-network/organizations/peerOrganizations/org3.byondz.io/tlsca/tlsca.org3.byondz.io-cert.pem


if [[ ${ORG,,} == "did" || ${ORG,,} == "digibank" ]]; then

   CORE_PEER_LOCALMSPID=didMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/did.byondz.io/users/Admin@did.byondz.io/msp
   CORE_PEER_ADDRESS=localhost:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/test-network/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem

elif [[ ${ORG,,} == "badge" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=badgeMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/test-network/organizations/peerOrganizations/badge.byondz.io/users/Admin@badge.byondz.io/msp
   CORE_PEER_ADDRESS=localhost:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/test-network/organizations/peerOrganizations/badge.byondz.io/tlsca/tlsca.badge.byondz.io-cert.pem

else
   echo "Unknown \"$ORG\", please choose did/Digibank or badge/Magnetocorp"
   echo "For example to get the environment variables to set upa Badge shell environment run:  ./setOrgEnv.sh badge"
   echo
   echo "This can be automated to set them as well with:"
   echo
   echo 'export $(./setOrgEnv.sh badge | xargs)'
   exit 1
fi

# output the variables that need to be set
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_DID_CA=${PEER0_DID_CA}"
echo "PEER1_DID_CA=${PEER1_DID_CA}"
echo "PEER0_BADGE_CA=${PEER0_BADGE_CA}"
echo "PEER0_ORG3_CA=${PEER0_ORG3_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
