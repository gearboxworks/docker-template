#!/bin/bash

DIR="$(dirname $0)"

if [ "$1" == "" ]
then
	VERSIONS="$(find * -maxdepth 1 -type d -name '*\.*' ! -name .git)"
else
	VERSIONS="$@"
fi

for VERSION in "${VERSIONS}"
do
	JSONFILE="${VERSION}/gearbox.json"
	if [ ! -f "${JSONFILE}" ]
	then
		echo "Gearbox: Can't find JSON file: ${JSONFILE}"
		exit
	fi

	${DIR}/GetEnv.sh "${JSONFILE}"
	. "${VERSION}/.env"

	echo "# Gearbox[${GB_CONTAINERMAJORVERSION}]: Removing container."
	docker container rm -f ${GB_CONTAINERMAJORVERSION}

	echo "# Gearbox[${GB_CONTAINERVERSION}]: Removing container."
	docker container rm -f ${GB_CONTAINERVERSION}

	echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Removing image."
	docker image rm -f ${GB_IMAGEMAJORVERSION}

	echo "# Gearbox[${GB_IMAGEVERSION}]: Removing image."
	docker image rm -f ${GB_IMAGEVERSION}
done

