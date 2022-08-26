#!/bin/bash

docker rm -f $(docker ps -aq)

docker rmi -f $(docker images dev-* -q)

docker network rm fabric_basic