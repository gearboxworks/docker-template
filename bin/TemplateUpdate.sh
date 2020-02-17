#!/bin/bash

DIR="$(dirname $0)"
CMD="$1"
VERSION="$2"

help() {
cat<<EOF

$(basename $0)
	Updates docker-template files from GitHub with either a specified version or latest.

$(basename $0) [version] - Updates TEMPLATE files.

EOF
}


################################################################################
GB_GITURL="$(git config --get remote.origin.url)"; export GB_GITURL
GB_GITREPO="$(basename -s .git ${GB_GITURL})"; export GB_GITREPO

if [ "${GB_GITREPO}" == "docker-template" ]
then
	echo "################################### WARNING ###################################"
	echo "# This command can not ever be run from the docker-template GitHub repository."
	echo "################################### WARNING ###################################"
	exit 1
fi

if [ "${VERSION}" == "" ]
then
	VERSION="-l"
else
	VERSION="-t ${VERSION}"
fi


echo "################################################################################"
echo "# Gearbox[docker-template]: Updating docker-template files from GitHub."

${DIR}/github-release download \
	--user "gearboxworks" \
	--repo "docker-template" \
	${VERSION} \
	--name docker-template.tgz

rm -f docker-template.tgz

