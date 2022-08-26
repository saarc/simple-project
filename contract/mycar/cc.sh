#!/bin/bash

# 1. 네트워크 확인  
 docker ps -a
 docker images dev-*
 docker network ls
# 1.1 컨테이너 삭제
docker rm -f $(docker ps -aq)
# 1.2 체인코드 이미지 삭제
docker rmi -f $(docker images dev-* -q)
# 1.3 도커 네트워크 삭제
docker network rm fabric_test

# 2. 네트워크 시작  
 cd ~/fabric-samples/test-network/
 ./network.sh up createChannel 
# 3. 체인코드 배포
 ./network.sh deploycc -ccn mycar -ccp ../../dev/first-project/contract/mycar
