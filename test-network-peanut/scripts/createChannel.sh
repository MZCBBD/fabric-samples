#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

CHANNEL_NAME="$1"
DELAY="$2"
MAX_RETRY="$3"
VERBOSE="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	setGlobals "did"
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		osnadmin channel join --channelID $CHANNEL_NAME --config-block ./channel-artifacts/${CHANNEL_NAME}.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
	FABRIC_CFG_PATH=$PWD/../config/
	ORG=$1
	local I=0
	while [[ $I < 2 ]]; do
		setGlobals $ORG $I

		local rc=1
		local COUNTER=1
		local CHANNEL_DELAY=$DELAY
		## Sometimes Join takes time, hence retry
		while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
			echo "Sleep $CHANNEL_DELAY seconds until a peer${I}.${ORG} join channel"
			sleep $CHANNEL_DELAY
			set -x
			peer channel join -b $BLOCKFILE >&log.txt
			res=$?
			{ set +x; } 2>/dev/null
			let rc=$res
			COUNTER=$(expr $COUNTER + 1)
			CHANNEL_DELAY=$(expr $CHANNEL_DELAY \* 2)
		done
		cat log.txt
		verifyResult $res "After $MAX_RETRY attempts, peer${I}.${ORG} has failed to join channel '$CHANNEL_NAME' "
		let I=$I+1
	done
}

setAnchorPeer() {
  ORG=$1
  ${CONTAINER_CLI} exec cli ./scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME 
}

FABRIC_CFG_PATH=${PWD}/configtx

## Create channel genesis block
infoln "Generating channel genesis block '${CHANNEL_NAME}.block'"
createChannelGenesisBlock

FABRIC_CFG_PATH=$PWD/../config/
BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"

## Create channel
infoln "Creating channel ${CHANNEL_NAME}"
createChannel
successln "Channel '$CHANNEL_NAME' created"

## Join all the peers to the channel
infoln "Joining org1 peer to the channel..."
joinChannel "did"
infoln "Joining org2 peer to the channel..."
joinChannel "badge"

## Set the anchor peers for each org in the channel
infoln "Setting anchor peer for org1..."
setAnchorPeer "did"
infoln "Setting anchor peer for org2..."
setAnchorPeer "badge"

successln "Channel '$CHANNEL_NAME' joined"
