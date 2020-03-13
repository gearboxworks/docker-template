#!/bin/bash

# WARNING: This file is SOURCED. Don't add in any "exit", otherwise your shell will exit.
export ARCH GB_BINFILE GB_BINDIR GB_BASEDIR GB_JSONFILE GB_VERSIONS GB_VERSION GITBIN GB_GITURL GB_GITREPO

ARCH="$(uname -s)"

GB_BINFILE="$(./bin/JsonToConfig -json-string '{}' -template-string '{{ .ExecName }}')"
GB_BINDIR="$(./bin/JsonToConfig -json-string '{}' -template-string '{{ .DirPath }}')"
GB_BASEDIR="$(dirname "$GB_BINDIR")"
GB_JSONFILE="${GB_BASEDIR}/gearbox.json"

GB_VERSIONS="$(${GB_BINFILE} -json ${GB_JSONFILE} -template-string '{{ range $version, $value := .Json.versions }}{{ $version }}{{ end }}')"
GB_VERSIONS="$(echo ${GB_VERSIONS})"	# Easily remove CR

GITBIN="$(which git)"
GB_GITURL="$(${GITBIN} config --get remote.origin.url)"
if [ "${GB_GITURL}" == "" ]
then
	GB_GITREPO=""
else
	GB_GITREPO="$(basename -s .git ${GB_GITURL})"
fi


################################################################################
_getVersions() {
	if [ ! -f "${GB_JSONFILE}" ]
	then
		echo "Gearbox: Can't find JSON file: ${GB_JSONFILE}"
		return 0
	fi

	if [ "${GB_VERSIONS}" == "" ]
	then
		echo "# Gearbox[${0}]: No versions found"
		return 0
	fi

	if [ "${GB_GITREPO}" == "docker-template" ]
	then
		echo "Cannot run this command from the docker-template repository."
		echo "IF THIS IS A COPY of that repo, then..."
		echo "	1. Remove the .git directory."
		echo "	2. Run the \"make init\" command."
		echo ""
		unset GB_VERSIONS GB_GITURL GB_GITREPO

	else
		case $1 in
			'all')
				;;
			'')
				echo "# Gearbox: ERROR - No versions specified."
				echo "# Gearbox: Versions available:"
				_listVersions
				unset GB_VERSIONS
				return 0
				;;
			*)
				GB_VERSIONS="$@"
				;;
		esac
	fi

	return 1
}


################################################################################
_listVersions() {
	echo "	all - All versions"
	${GB_BINFILE} -json ${GB_JSONFILE} -template-string '{{ range $version, $value := .Json.versions }}\t{{ $version }} - {{ $.Json.organization }}/{{ $.Json.name }}:{{ $version }}{{ end }}'
	echo ""
}


################################################################################
gb_getenv() {
	VERSION_DIR="$1"
	# DIR="$(./bin/JsonToConfig-${ARCH} -json "${GB_JSONFILE}" -template-string '{{ .Json.version }}')"
	${GB_BINFILE} -json "${GB_JSONFILE}" -template "${VERSION_DIR}/.env.tmpl" -out "${VERSION_DIR}/.env"
	. "${VERSION_DIR}/.env"
}


################################################################################
gb_init() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Initializing repo."

	gb_create-build ${GB_JSONFILE}
	gb_create-version ${GB_JSONFILE}
	${DIR}/JsonToConfig-$(uname -s) -json "${GB_JSONFILE}" -template TEMPLATE/README.md.tmpl -out README.md
}


################################################################################
gb_create-build() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Creating build directory."

	if [ -d build ]
	then
		echo "# Gearbox[${FUNCNAME[0]}]: Directory \"build\" already exists."
		return 0
	fi

	cp -i TEMPLATE/build.sh.tmpl .
	${GB_BINFILE} -json ${GB_JSONFILE} -create build.sh.tmpl -shell
	rm -f build.sh.tmpl build.sh

	${GB_BINFILE} -template ./TEMPLATE/README.md.tmpl -json ${GB_JSONFILE} -out README.md
}


################################################################################
gb_create-version() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Creating version directory for versions: ${GB_VERSIONS}"


	for GB_VERSION in ${GB_VERSIONS}
	do
		if [ -d ${GB_VERSION} ]
		then
			echo "# Gearbox[${GB_VERSION}]: Directory \"${GB_VERSIONS}\" already exists."
		else
			echo "# Gearbox[${GB_VERSION}]: Creating version directory \"${GB_VERSIONS}\"."
			cp -i TEMPLATE/version.sh.tmpl .
			${GB_BINFILE} -json ${GB_JSONFILE} -create version.sh.tmpl -shell
			rm -f version.sh.tmpl version.sh
		fi
	done

	${GB_BINFILE} -template ./TEMPLATE/README.md.tmpl -json ${GB_JSONFILE} -out README.md
}


################################################################################
gb_clean() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Cleaning up for versions: ${GB_VERSIONS}"


	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}


		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Removing container, (present and running)."
				docker container rm -f ${GB_CONTAINERVERSION}
				;;
			'STOPPED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Removing container, (present and shutdown)."
				docker container rm -f ${GB_CONTAINERVERSION}
				;;
			'MISSING')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Container already removed."
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac


		gb_checkImage ${GB_IMAGEMAJORVERSION}
		case ${STATE} in
			'PRESENT')
				echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Removing image."
				docker image rm -f ${GB_IMAGEMAJORVERSION}
				;;
			*)
				echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Image already removed."
				;;
		esac


		gb_checkImage ${GB_IMAGEVERSION}
		case ${STATE} in
			'PRESENT')
				echo "# Gearbox[${GB_IMAGEVERSION}]: Removing image."
				docker image rm -f ${GB_IMAGEVERSION}
				;;
			*)
				echo "# Gearbox[${GB_IMAGEVERSION}]: Image already removed."
				;;
		esac


		echo "# Gearbox[${GB_IMAGEVERSION}]: Removing logs."
		rm -f "${GB_VERSION}/logs/*.log"
	done
}


################################################################################
gb_build() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Building image for versions: ${GB_VERSIONS}"

	case ${ARCH} in
		'Linux')
			LOG_ARGS='-t 10'
			;;
		*)
			LOG_ARGS='-r -t 10'
			;;
	esac


	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		LOGDIR="${GB_VERSION}/logs"
		# LOGFILE="${LOGDIR}/$(date +'%Y%m%d-%H%M%S').log"
		LOGFILE="${LOGDIR}/${GB_NAME}.log"

		if [ "${GB_REF}" == "base" ]
		then
			echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: This is a base container."

		elif [ "${GB_REF}" != "" ]
		then
			echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Pull ref container."
			docker pull "${GB_REF}"
			echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Query ref container."
			GEARBOX_ENTRYPOINT="$(docker inspect --format '{{ join .ContainerConfig.Entrypoint " " }}' "${GB_REF}")"
			export GEARBOX_ENTRYPOINT
		fi

		echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Building container."
		if [ "${GITHUB_ACTIONS}" == "" ]
		then
			script ${LOG_ARGS} ${LOGFILE} \
				docker build -t ${GB_IMAGENAME}:${GB_VERSION} -f ${GB_DOCKERFILE} --build-arg GEARBOX_ENTRYPOINT .
			echo "# Gearbox[${GB_IMAGENAME}:${GB_VERSION}]: Log file saved to \"${LOGFILE}\""
		fi

		docker build -t ${GB_IMAGENAME}:${GB_VERSION} -f ${GB_DOCKERFILE} --build-arg GEARBOX_ENTRYPOINT .

		if [ "${GB_MAJORVERSION}" != "" ]
		then
			docker tag ${GB_IMAGENAME}:${GB_VERSION} ${GB_IMAGENAME}:${GB_MAJORVERSION}
		fi
	done

}


################################################################################
gb_create() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Creating container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				echo "# Gearbox[${GB_IMAGEVERSION}]: Container already exists and is started."
				;;
			'STOPPED')
				echo "# Gearbox[${GB_IMAGEVERSION}]: Container already exists and is stopped."
				;;
			'MISSING')
				echo "# Gearbox[${GB_IMAGEVERSION}]: Creating container."
				docker create --name ${GB_CONTAINERVERSION} ${GB_NETWORK} -P ${GB_VOLUMES} ${GB_IMAGEVERSION}
				;;
			*)
				echo "# Gearbox[${GB_IMAGEVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_info() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Image and container info for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: List image."
		docker image ls ${GB_IMAGEMAJORVERSION}
		echo "# Gearbox[${GB_IMAGEVERSION}]: List image."
		docker image ls ${GB_IMAGEVERSION}

		echo "# Gearbox[${GB_CONTAINERMAJORVERSION}]: List container."
		docker container ls -f name="^${GB_CONTAINERMAJORVERSION}"
		echo "# Gearbox[${GB_CONTAINERVERSION}]: List container."
		docker container ls -f name="^${GB_CONTAINERVERSION}"
	done

}


################################################################################
gb_inspect() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Inspecting image and container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Inspect image."
		docker image inspect ${GB_IMAGEMAJORVERSION} 2>&1
		echo "# Gearbox[${GB_IMAGEVERSION}]: Inspect image."
		docker image inspect ${GB_IMAGEVERSION} 2>&1

		echo "# Gearbox[${GB_CONTAINERMAJORVERSION}]: Inspect container."
		docker container inspect name="^${GB_CONTAINERMAJORVERSION}" 2>&1
		echo "# Gearbox[${GB_CONTAINERVERSION}]: Inspect container."
		docker container inspect name="^${GB_CONTAINERVERSION}" 2>&1
	done

}


################################################################################
gb_list() {
	echo "################################################################################"
	if _getVersions $@
	then
		echo "FUCK"
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Listing image and container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: List image."
		docker image ls ${GB_IMAGEMAJORVERSION}
		echo "# Gearbox[${GB_IMAGEVERSION}]: List image."
		docker image ls ${GB_IMAGEVERSION}

		echo "# Gearbox[${GB_CONTAINERMAJORVERSION}]: List container."
		docker container ls -a -f name="^${GB_CONTAINERMAJORVERSION}"
		echo "# Gearbox[${GB_CONTAINERVERSION}]: List container."
		docker container ls -a -f name="^${GB_CONTAINERVERSION}"
	done
}


################################################################################
gb_logs() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Showing build logs for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${VERSION}

		if [ -f "${VERSION}/logs/${GB_NAME}.log" ]
		then
			echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Showing logs."
			script -dp "${VERSION}/logs/${GB_NAME}.log" | less -SinR
		else
			echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: No logs."
		fi
	done

}


################################################################################
gb_ports() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Showing ports for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Showing exposed container ports."
				docker port ${GB_CONTAINERVERSION}
				;;
			'STOPPED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Container needs to be started."
				;;
			'MISSING')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Need to create container first."
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_dockerhub() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Pushing to DockerHub for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_IMAGEVERSION}]: Pushing image to DockerHub."
		docker push ${GB_IMAGEVERSION}
		echo "# Gearbox[${GB_IMAGEMAJORVERSION}]: Pushing image to DockerHub."
		docker push ${GB_IMAGEMAJORVERSION}
	done

}


################################################################################
gb_github() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Pushing to GitHub for repo."

	if [ "${GITHUB_ACTIONS}" != "" ]
	then
		echo "# Gearbox[${GB_GITREPO}]: Running from GitHub action - ignoring."
		return $?
	fi

	echo "# Gearbox[${GB_GITREPO}]: Pushing repo to GitHub."
	git commit -a -m "Latest push" && git push

}


################################################################################
gb_push() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Cleaning for versions: ${GB_VERSIONS}"

	gb_dockerhub ${GB_VERSIONS}
	gb_github ${GB_VERSIONS}
}


################################################################################
gb_release() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Releasing for versions: ${GB_VERSIONS}"

	gb_clean ${GB_VERSIONS} && \
		gb_build ${GB_VERSIONS} && \
		gb_test ${GB_VERSIONS} && \
		gb_push ${GB_VERSIONS}

}


################################################################################
gb_rm() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Removing container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Removing container, (present and running)."
				docker container rm -f ${GB_CONTAINERVERSION}
				;;
			'STOPPED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Removing container, (present and shutdown)."
				docker container rm -f ${GB_CONTAINERVERSION}
				;;
			'MISSING')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Container already removed."
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_shell() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Running shell for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				;;
			'STOPPED')
				gb_start ${GB_VERSION}
				;;
			'MISSING')
				gb_create ${GB_VERSION}
				gb_start ${GB_VERSION}
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Entering container."
				docker exec -i -t ${GB_CONTAINERVERSION} /bin/bash -l
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_ssh() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Running SSH for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				;;
			'STOPPED')
				gb_start ${GB_VERSION}
				;;
			'MISSING')
				gb_create ${GB_VERSION}
				gb_start ${GB_VERSION}
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				SSHPASS="$(which sshpass)"
				if [ "${SSHPASS}" != "" ]
				then
					SSHPASS="${SSHPASS} -pbox"
				fi

				echo "# Gearbox[${GB_CONTAINERVERSION}]: SSH into container."
				PORT="$(docker port ${GB_CONTAINERVERSION} 22/tcp | sed 's/0.0.0.0://')"

				${SSHPASS} ssh -p ${PORT} -o StrictHostKeyChecking=no gearbox@localhost
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_start() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Starting container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_CONTAINERVERSION}]: Checking network."
		gb_checknetwork

		echo "# Gearbox[${GB_CONTAINERVERSION}]: Starting container."
		docker start ${GB_CONTAINERVERSION}
	done

}


################################################################################
gb_stop() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Stopping container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		echo "# Gearbox[${GB_CONTAINERVERSION}]: Stopping container."
		docker stop ${GB_CONTAINERVERSION}
	done

}


################################################################################
gb_test() {
	echo "################################################################################"
	if _getVersions $@
	then
		return $?
	fi
	echo "# Gearbox[${FUNCNAME[0]}]: Testing container for versions: ${GB_VERSIONS}"

	for GB_VERSION in ${GB_VERSIONS}
	do
		gb_getenv ${GB_VERSION}

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				;;
			'STOPPED')
				gb_start ${GB_VERSION}
				;;
			'MISSING')
				gb_create ${GB_VERSION}
				gb_start ${GB_VERSION}
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac

		gb_checkContainer ${GB_CONTAINERVERSION}
		case ${STATE} in
			'STARTED')
				SSHPASS="$(which sshpass)"
				if [ "${SSHPASS}" != "" ]
				then
					SSHPASS="${SSHPASS} -pbox"
				fi

				echo "# Gearbox[${GB_CONTAINERVERSION}]: Running unit-tests."
				PORT="$(docker port ${GB_CONTAINERVERSION} 22/tcp | sed 's/0.0.0.0://')"

				ssh -p ${PORT} -o StrictHostKeyChecking=no gearbox@localhost /etc/gearbox/unit-tests/run.sh
				;;
			*)
				echo "# Gearbox[${GB_CONTAINERVERSION}]: Unknown state."
				;;
		esac
	done

}


################################################################################
gb_checkImage() {
	STATE="$(docker image ls -q "$1")"
	if [ "${STATE}" == "" ]
	then
		# Not created.
		STATE="MISSING"
	else
		STATE="PRESENT"
	fi
}


################################################################################
gb_checkContainer() {
	STATE="$(docker container ls -q -a -f name="^$1")"
	if [ "${STATE}" == "" ]
	then
		# Not created.
		STATE="MISSING"
		return
	fi

	STATE="$(docker container ls -q -f name="^$1")"
	if [ "${STATE}" == "" ]
	then
		# Not created.
		STATE="STOPPED"
		return
	fi

	STATE="STARTED"
}


################################################################################
gb_checknetwork() {
	STATE="$(docker network ls -qf "name=gearboxnet")"
	if [ "${STATE}" == "" ]
	then
		# Create network
		echo "Creating network"
		docker network create --subnet 172.42.0.0/24 gearboxnet
	fi
}


