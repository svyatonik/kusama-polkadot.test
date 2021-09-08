#!/bin/bash

killall -9 polkadot
killall -9 substrate-relay
pkill -9 -f 'kusama-to-polkadot-messages-generator.sh'
pkill -9 -f 'polkadot-to-kusama-messages-generator.sh'
