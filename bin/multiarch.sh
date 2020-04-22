#!/bin/bash

CONTAINER="$(basename $0)"
DIR="$(dirname $0)"
EXEC="${DIR}/$(uname -s)/$0"
if [ ! -x "${EXEC}" ]
then
	echo "Gearbox: Architecture not supported, ${EXEC}."
	exit
fi

exec "${EXEC}" "$@"

if [ "${CONTAINER}" == "launch" ]
then
	exec "${EXEC}" "$@"
else
	exec "${EXEC}" run ${CONTAINER} "$@"
fi
