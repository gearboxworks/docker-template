#!/bin/bash

JSONFILE="$1"
if [ ! -f "${JSONFILE}" ]
then
	echo "Gearbox: Missing JSON file."
	exit
fi


if [ ! -f "TEMPLATE/version.sh.tmpl" ]
then
	echo "Gearbox: Missing version.sh.tmpl file."
	exit
fi

cp -i TEMPLATE/version.sh.tmpl .

./bin/JsonToConfig -json "${JSONFILE}" -create version.sh.tmpl -shell

./bin/JsonToConfig -template ./TEMPLATE/README.md.tmpl -json "${JSONFILE}" -out README.md

