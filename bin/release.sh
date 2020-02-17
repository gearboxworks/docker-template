#!/bin/bash

DIR="$(dirname $0)"

echo "################################################################################"
. ${DIR}/_GetVersions.sh
if [ "${VERSIONS}" == "" ]
then
	echo "# Gearbox: Running ${0} failed"
	exit 1
fi
echo "# Gearbox: Running ${0} for repository containing versions: ${VERSIONS}"


"${DIR}/push-github.sh" "$@"


echo "# Gearbox[${GB_GITREPO}]: Creating release on GitHub."
if [ "${GB_GITREPO}" == "" ]
then
	echo "# Gearbox[${GB_GITREPO}]: GB_GITREPO needs to be set to create a release."
	echo "# Gearbox[${GB_GITREPO}]: Have you run \"git init\"?"
	PUSHRELEASE="Y"
fi

if [ "${GITHUB_USER}" == "" ]
then
	echo "# Gearbox[${GB_GITREPO}]: GITHUB_USER needs to be set to create a release."
	PUSHRELEASE="Y"
fi

if [ "${GITHUB_TOKEN}" == "" ]
then
	echo "# Gearbox[${GB_GITREPO}]: GITHUB_TOKEN needs to be set to create a release."
	PUSHRELEASE="Y"
fi


if [ "${PUSHRELEASE}" == "" ]
then
	echo "# Gearbox[${GB_GITREPO}]: Abandoning GitHub release creation."
else
	echo "# Gearbox[${GB_GITREPO}]: Uploading release to GitHub."
	tar zcvf release.tgz Makefile README.md bin
	${DIR}/github-release upload --user "gearboxworks" --repo "${GB_GITREPO}" --tag 1.0.0 --name "release.tgz" --label "release.tgz" -R -f release.tgz
fi


"${DIR}/push-dockerhub.sh" "$@"

