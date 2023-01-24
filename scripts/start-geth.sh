#!/bin/sh
#
# Starts a local fast-synced geth node.

DEFAULT_NETWORK=mainnet

if [ "$NETWORK" = "" ]; then
	NETWORK=$DEFAULT_NETWORK
fi

if [ "$PRUNE_GETH" != "" ]; then
    exec geth snapshot prune-state --datadir=/root/data/.ethereum --datadir.ancient=/root/data/ancient-data
elif [ "$START_GETH" != "" ]; then
	if [ "$NETWORK" != "$DEFAULT_NETWORK" ]; then
		exec geth --goerli --datadir=/root/data/.ethereum --datadir.ancient=/root/data/ancient-data --http --http.addr "0.0.0.0" --http.vhosts=* --http.api "eth,net" --ipcdisable --authrpc.addr "0.0.0.0" --authrpc.port "8551" --authrpc.vhosts "*" --authrpc.jwtsecret "/root/jwttoken/jwtsecret.hex"
	else
		exec geth --syncmode snap --http --http.addr "0.0.0.0" --http.vhosts=* --http.api "eth,net" --ipcdisable --datadir=/root/data/.ethereum --datadir.ancient=/root/data/ancient-data --authrpc.addr "0.0.0.0" --authrpc.port "8551" --authrpc.vhosts "*" --authrpc.jwtsecret "/root/jwttoken/jwtsecret.hex"
	fi
fi
