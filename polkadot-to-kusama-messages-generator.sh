#!/bin/bash
. ./prelude.sh

# THIS SCRIPT IS NOT INTENDED FOR USE IN PRODUCTION ENVIRONMENT
#
# This scripts periodically calls relay binary to generate Kusama -> Polkadot
# messages.

set -eu

# Path to relay binary
RELAY_BINARY_PATH=./bin/substrate-relay
# Polkadot node host
POLKADOT_HOST=127.0.0.1
# Polkadot node port
POLKADOT_PORT=9946
# Kusama signer
KUSAMA_SIGNER=//Bob
# Polkadot signer
POLKADOT_SIGNER=//Bob
# Max delay before submitting transactions (s)
MAX_SUBMIT_DELAY_S=60
# Lane to send message over
LANE=00000000

# submit Millau to Rialto message
submit_message() {
	MESSAGE_PARAMS="$*"
	$RELAY_BINARY_PATH 2>&1 send-message polkadot-to-kusama \
		--source-host=$POLKADOT_HOST\
		--source-port=$POLKADOT_PORT\
		--source-signer=$POLKADOT_SIGNER\
		--target-signer=$KUSAMA_SIGNER\
		--lane=$LANE\
		--origin Source \
		$MESSAGE_PARAMS
}

BATCH_TIME=0
while true
do
	SUBMIT_DELAY_S=`shuf -i 0-$MAX_SUBMIT_DELAY_S -n 1`
	# sleep some time
	echo "Sleeping $SUBMIT_DELAY_S seconds..."
	sleep $SUBMIT_DELAY_S

	# prepare message to send
	MESSAGE="remark"

	# submit message
	echo "Sending message from Polkadot to Kusama"
	submit_message $MESSAGE
done
