#!/bin/bash

# 환경설정 , path설정 ~/fabric-samples/bin, FABRIC_CONFIG_PATH
set -x 
export FABRIC_CFG_PATH=${PWD}

if [ ! -d config ]; then
    mkdir config
fi

rm -rf ./config/*
rm -rf ./organizations/ordererOrganizations
rm -rf ./organizations/peerOrganizations

# cryptogen
cryptogen generate --config=./organizations/cryptogen/crypto-config.yaml --output="organizations"

# configtxgen - genesis.block
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./config/genesis.block

# configtxgen - channel.tx
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./config/mychannel.tx -channelID mychannel