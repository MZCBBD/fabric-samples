#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/byondz.io/tlsca/tlsca.byondz.io-cert.pem
export PEER0_ORG1_CA=${PWD}/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem
export PEER0_ORG2_CA=${PWD}/organizations/peerOrganizations/badge.byondz.io/tlsca/tlsca.badge.byondz.io-cert.pem
export PEER0_ORG3_CA=${PWD}/organizations/peerOrganizations/org3.byondz.io/tlsca/tlsca.org3.byondz.io-cert.pem
export PEER0_did_CA=${PWD}/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem
export PEER1_did_CA=${PWD}/organizations/peerOrganizations/did.byondz.io/tlsca/tlsca.did.byondz.io-cert.pem
export PEER0_badge_CA=${PWD}/organizations/peerOrganizations/badge.byondz.io/tlsca/tlsca.badge.byondz.io-cert.pem
export PEER1_badge_CA=${PWD}/organizations/peerOrganizations/badge.byondz.io/tlsca/tlsca.badge.byondz.io-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/byondz.io/orderers/orderer.byondz.io/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/byondz.io/orderers/orderer.byondz.io/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  local PEER_NO=1
  if [ ! -z $2 ];then
    PEER_NO=$2
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG == "did" ]; then
    export CORE_PEER_LOCALMSPID="didMSP"
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/did.byondz.io/users/Admin@did.byondz.io/msp  
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    if [ $PEER_NO == 1 ];then       
      export CORE_PEER_ADDRESS=localhost:7051
    else
      export CORE_PEER_ADDRESS=localhost:7151
    fi
  elif [ $USING_ORG == "badge" ]; then
      export CORE_PEER_LOCALMSPID="badgeMSP"
      export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
      export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/badge.byondz.io/users/Admin@badge.byondz.io/msp
      if [ $PEER_NO == 1 ];then 
        export CORE_PEER_ADDRESS=localhost:9051
      else
        export CORE_PEER_ADDRESS=localhost:9061
      fi
  elif [ $USING_ORG == 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org3.byondz.io/users/Admin@org3.byondz.io/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ $USING_ORG == "did" ]; then
    export CORE_PEER_ADDRESS=peer0.did.byondz.io:7051
  elif [ $USING_ORG == "badge" ]; then
    export CORE_PEER_ADDRESS=peer0.badge.byondz.io:9051
  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_ADDRESS=peer0.org3.byondz.io:11051
  else
    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer$2.$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER$2_$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
