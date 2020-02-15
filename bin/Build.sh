#!/bin/bash

DIR="$(dirname $0)"

if [ "$1" == "" ]
then
	VERSIONS="$(find * -maxdepth 1 -type d -name '*\.*' ! -name .git)"
else
	VERSIONS="$@"
fi

case $(uname -s) in
	'Linux')
		LOG_ARGS='-t 10'
		;;
	*)
		LOG_ARGS='-r -t 10'
		;;
esac


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

	LOGDIR="${GB_VERSION}/logs"
	LOGFILE="${LOGDIR}/$(date +'%Y%m%d-%H%M%S').log"

	echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Building container."

	script ${LOG_ARGS} ${LOGFILE} \
		docker build -t ${GB_IMAGENAME}:${GB_VERSION} -f ${GB_DOCKERFILE} .

	echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Log file saved to \"${LOGFILE}\""

	if [ "${GB_MAJORVERSION}" != "" ]
	then
		docker tag ${GB_IMAGENAME}:${GB_VERSION} ${GB_IMAGENAME}:${GB_MAJORVERSION}
	fi
done

