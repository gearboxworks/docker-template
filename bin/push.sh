#!/bin/bash

DIR="$(dirname $0)"

"${DIR}/push-dockerhub.sh" "$@"
"${DIR}/push-github.sh" "$@"
