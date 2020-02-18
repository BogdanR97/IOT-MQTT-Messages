#! /bin/bash

export REGISTRY_HOST=localhost:5000
export SPRC_DVP=$(pwd)

docker service create --name registry --publish published=5000,target=5000 registry:2
docker-compose -f stack.yml build
docker-compose -f stack.yml push
