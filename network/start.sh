#!/bin/bash
function infoln() {
    echo $1
}

# 컨테이너, 도커네트워크 수행
set -x

export PATH=$PATH:/home/bstudent/fabric-samples/bin;
export FABRIC_CFG_PATH=${PWD}

#1 컨테이너 생성 및 도커네트워크 생성
docker-compose -f docker-compose.yml up -d ca_org1 orderer.example.com peer0.org1.example.com peer0.org2.example.com

sleep 10

docker ps -a 

# org1 환경설정
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

export FABRIC_CFG_PATH=/home/bstudent/fabric-samples/config

. organizations/fabric-ca/registerEnroll.sh

# infoln "Creating Org1 Identities"

createOrg1

# 채널 생성  config/mychannel.tx -> peer channel create -> config/mychannel.block
peer channel create -o localhost:7050 -c mychannel -f ./config/mychannel.tx --outputBlock ./config/mychannel.block 
sleep 3

# 채널 조인 config/mychannel.block -> peer channel join -> peer channel list 
peer channel join -b ./config/mychannel.block 
sleep 3

# org2 환경설정
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051

# 채널 조인 config/mychannel.block -> peer channel join -> peer channel list 
peer channel join -b ./config/mychannel.block 
sleep 3