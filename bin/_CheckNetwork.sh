#!/bin/bash

NETWORK_NAME="$1"
if [ "${NETWORK_NAME}" == "" ]
then
	NETWORK_NAME="gearboxnet"
fi

EXISTS="$(docker network ls -qf "name=${NETWORK_NAME}")"
if [ "${EXISTS}" == "" ]
then
	# Create network
	echo "Creating network"
	docker network create --subnet 172.42.0.0/24 gearboxnet
fi

