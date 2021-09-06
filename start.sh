#!/bin/bash

. ./prelude.sh

mkdir bin || true
mkdir data || true
mkdir logs || true
rm -rf data/kusama-alice.db
rm -rf data/kusama-bob.db
rm -rf data/polkadot-alice.db
rm -rf data/polkadot-bob.db
rm -rf logs/*

. ./build-polkadot-node.sh
. ./build-substrate-relay.sh

###############################################################################
### Kusama chain startup ######################################################
###############################################################################

RUST_LOG=runtime=trace,runtime::bridge=trace
export RUST_LOG

# start Kusama nodes
./run-with-log.sh kusama-alice "./bin/polkadot\
	--chain=kusama-local
	--alice\
	--base-path=data/kusama-alice.db\
	--bootnodes=/ip4/127.0.0.1/tcp/30334/p2p/12D3KooWSEpHJj29HEzgPFcRYVc5X3sEuP3KgiUoqJNCet51NiMX\
	--node-key=79cf382988364291a7968ae7825c01f68c50d679796a8983237d07fe0ccf363b\
	--port=30333\
	--prometheus-port=9615\
	--rpc-port=9933\
	--ws-port=9944\
	--execution=Native\
	--rpc-cors=all\
	--unsafe-rpc-external\
	--unsafe-ws-external"&
./run-with-log.sh kusama-bob "./bin/polkadot\
	--chain=kusama-local
	--bob\
	--base-path=data/kusama-bob.db\
	--bootnodes=/ip4/127.0.0.1/tcp/30333/p2p/12D3KooWMF6JvV319a7kJn5pqkKbhR3fcM2cvK5vCbYZHeQhYzFE\
	--node-key=4f9d0146dd9b7b3bf5a8089e3880023d1df92057f89e96e07bb4d8c2ead75bbd\
	--port=30334\
	--prometheus-port=9616\
	--rpc-port=9934\
	--ws-port=9945\
	--execution=Native\
	--rpc-cors=all\
	--unsafe-rpc-external\
	--unsafe-ws-external"&

###############################################################################
### Polkadot chain startup ####################################################
###############################################################################

RUST_LOG=runtime=trace,runtime::bridge=trace
export RUST_LOG

# start Polkadot nodes
./run-with-log.sh polkadot-alice "./bin/polkadot\
	--chain=polkadot-local
	--alice\
	--base-path=data/polkadot-alice.db\
	--bootnodes=/ip4/127.0.0.1/tcp/30336/p2p/12D3KooWHTYUAtF6ry4mrYTufzLfDSJ725mYc85rSKFzuFkXEvFT\
	--node-key=79cf382988364291a7968ae7825c01f68c50d679796a8983237d07fe0ccf363c\
	--port=30335\
	--prometheus-port=9617\
	--rpc-port=9935\
	--ws-port=9946\
	--execution=Native\
	--rpc-cors=all\
	--unsafe-rpc-external\
	--unsafe-ws-external"&
./run-with-log.sh polkadot-bob "./bin/polkadot\
	--chain=polkadot-dev
	--bob\
	--base-path=data/polkadot-bob.db\
	--bootnodes=/ip4/127.0.0.1/tcp/30335/p2p/12D3KooWKWnNktXrugMMYa4NFB18qxwF49rABJgHiLGJq7uVfs5E\
	--node-key=79cf382988364291a7968ae7825c01f68c50d679796a8983237d07fe0ccf363d\
	--port=30336\
	--prometheus-port=9618\
	--rpc-port=9936\
	--ws-port=9947\
	--execution=Native\
	--rpc-cors=all\
	--unsafe-rpc-external\
	--unsafe-ws-external"&

###############################################################################
### Headers+messages relay startup ############################################
###############################################################################

RUST_LOG=bridge=trace
export RUST_LOG

KUSAMA_HOST=127.0.0.1
KUSAMA_PORT=9944
POLKADOT_HOST=127.0.0.1
POLKADOT_PORT=9946
RELAY_BINARY_PATH=./bin/substrate-relay

# initialize Kusama -> Polkadot headers bridge
./run-with-log.sh initialize-kusama-to-polkadot "$RELAY_BINARY_PATH\
	init-bridge KusamaToPolkadot\
	--source-host=$KUSAMA_HOST\
	--source-port=$KUSAMA_PORT\
	--target-host=$POLKADOT_HOST\
	--target-port=$POLKADOT_PORT\
	--target-signer=//Alice"&

# initialize Polkadot -> Kusama headers bridge
./run-with-log.sh initialize-wococo-to-rococo "$RELAY_BINARY_PATH\
	init-bridge PolkadotToKusama\
	--source-host=$POLKADOT_HOST\
	--source-port=$POLKADOT_PORT\
	--target-host=$KUSAMA_HOST\
	--target-port=$KUSAMA_PORT\
	--target-signer=//Alice"&

# start kusama-polkadot headers+messages relay
./run-with-log.sh relay-kusama-polkadot "$RELAY_BINARY_PATH\
	relay-headers-and-messages kusama-polkadot\
	--rococo-host=$KUSAMA_HOST\
	--rococo-port=$KUSAMA_PORT\
	--rococo-signer=//Alice\
	--wococo-host=$POLKADOT_HOST\
	--wococo-port=$POLKADOT_PORT\
	--wococo-signer=//Alice\
	--lane=00000000\
	--prometheus-port=9700"&

###############################################################################
### Generate messages #########################################################
###############################################################################

# start generating Kusama -> Polkadot messages
./run-with-log.sh \
	kusama-to-polkadot-messages-generator\
	./kusama-to-polkadot-messages-generator.sh&
