#!/bin/bash

DIR="$(dirname $0)"

echo "################################################################################"
. ${DIR}/_GetVersions.sh
if [ "${VERSIONS}" == "" ]
then
	echo "# Gearbox: Running ${0} failed"
	exit 1
fi
echo "# Gearbox: Running ${0} for versions: ${VERSIONS}"

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

	${DIR}/_GetEnv.sh "${JSONFILE}"
	. "${VERSION}/.env"

	LOGDIR="${GB_VERSION}/logs"
	# LOGFILE="${LOGDIR}/$(date +'%Y%m%d-%H%M%S').log"
	LOGFILE="${LOGDIR}/${GB_NAME}.log"

	echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Building container."

	script ${LOG_ARGS} ${LOGFILE} \
		docker build -t ${GB_IMAGENAME}:${GB_VERSION} -f ${GB_DOCKERFILE} .

	echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Log file saved to \"${LOGFILE}\""

	if [ "${GB_MAJORVERSION}" != "" ]
	then
		docker tag ${GB_IMAGENAME}:${GB_VERSION} ${GB_IMAGENAME}:${GB_MAJORVERSION}
	fi
done

