#!/bin/bash

set -x

setGlobals() {
    USING_ORG=$1
    if [ $USING_ORG -eq 1 ]; then
        export CORE_PEER_LOCALMSPID="Org1MSP"
        export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
        export CORE_PEER_ADDRESS=localhost:7051
    elif [ $USING_ORG -eq 2 ]; then
        export CORE_PEER_LOCALMSPID="Org2MSP"
        export CORE_PEER_MSPCONFIGPATH=${PWD}/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
        export CORE_PEER_ADDRESS=localhost:9051
    else
        errorln "ORG Unknown"
    fi
}

export FABRIC_CFG_PATH=/home/bstudent/fabric-samples/config/

peer lifecycle chaincode package simpleasset.tar.gz --path ../contract/simpleasset/v1.1 --label simpleasset_1

setGlobals 1
peer lifecycle chaincode install simpleasset.tar.gz 
peer lifecycle chaincode queryinstalled 

setGlobals 2
peer lifecycle chaincode install simpleasset.tar.gz 
peer lifecycle chaincode queryinstalled 

PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | sed -n "/simpleasset_1/{s/^Package ID: //; s/, Label:.*$//; p;}")
setGlobals 1
peer lifecycle chaincode approveformyorg -o localhost:7050 --channelID mychannel --name simpleasset --version 1 --package-id ${PACKAGE_ID} --sequence  1

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name simpleasset --version 1 --sequence 1  --output json 

setGlobals 2
peer lifecycle chaincode approveformyorg -o localhost:7050 --channelID mychannel --name simpleasset --version 1 --package-id ${PACKAGE_ID} --sequence 1 

peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name simpleasset --version 1 --sequence 1 --output json 

setGlobals 1
peer lifecycle chaincode commit -o localhost:7050 --channelID mychannel --name simpleasset --peerAddresses localhost:7051 --peerAddresses localhost:9051 --version 1 --sequence  1
peer lifecycle chaincode querycommitted --channelID mychannel --name simpleasset 


fcn_call='{"function":"Set","Args":["a","100"]}'
peer chaincode invoke -o localhost:7050 -C mychannel -n simpleasset -c ${fcn_call} --peerAddresses localhost:7051 --peerAddresses localhost:9051
sleep 3

peer chaincode query -C mychannel -n simpleasset -c '{"Args":["Get","a"]}' 


