#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# import utils
. scripts/envVar.sh
. scripts/configUpdate.sh


# NOTE: this must be run in a CLI container since it requires jq and configtxlator 
createAnchorPeerUpdate() {
  infoln "Fetching channel config for channel $CHANNEL_NAME"
  fetchChannelConfig $ORG $CHANNEL_NAME ${CORE_PEER_LOCALMSPID}config.json

  infoln "Generating anchor peer update transaction for ${ORG} on channel $CHANNEL_NAME"

  if [ $ORG == "did" ]; then
    HOST="peer0.did.byondz.io"
    PORT=7051
    HOST2="peer1.did.byondz.io"
    PORT2=7051
  elif [ $ORG == "badge" ]; then
    HOST="peer0.badge.byondz.io"
    PORT=9051
    HOST2="peer1.badge.byondz.io"
    PORT2=9061
  elif [ $ORG -eq 3 ]; then
    HOST="peer0.org3.byondz.io"
    PORT=11051
  else
    errorln "${ORG} unknown"
  fi

  set -x
  # Modify the configuration to append the anchor peer 
  if [ $ORG == "did" ]; then
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'},{"host": "'$HOST2'","port": '$PORT2'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  else
    jq '.channel_group.groups.Application.groups.'${CORE_PEER_LOCALMSPID}'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": '$PORT'},{"host": "'$HOST2'","port": '$PORT2'}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json > ${CORE_PEER_LOCALMSPID}modified_config.json
  fi
  { set +x; } 2>/dev/null

  # Compute a config update, based on the differences between 
  # {orgmsp}config.json and {orgmsp}modified_config.json, write
  # it as a transaction to {orgmsp}anchors.tx
  createConfigUpdate ${CHANNEL_NAME} ${CORE_PEER_LOCALMSPID}config.json ${CORE_PEER_LOCALMSPID}modified_config.json ${CORE_PEER_LOCALMSPID}anchors.tx
}

updateAnchorPeer() {
  peer channel update -o orderer.byondz.io:7050 --ordererTLSHostnameOverride orderer.byondz.io -c $CHANNEL_NAME -f ${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile "$ORDERER_CA" >&log.txt
  res=$?
  cat log.txt
  verifyResult $res "Anchor peer update failed"
  successln "Anchor peer set for org '$CORE_PEER_LOCALMSPID' on channel '$CHANNEL_NAME'"
}

ORG=$1
CHANNEL_NAME=$2

setGlobalsCLI $ORG

createAnchorPeerUpdate 

updateAnchorPeer 
