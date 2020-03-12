#!/bin/bash

JSONFILE="$1"
if [ ! -f "${JSONFILE}" ]
then
	echo "Gearbox: Missing JSON file."
	exit
fi


if [ ! -f "TEMPLATE/build.sh.tmpl" ]
then
	echo "Gearbox: Missing build.sh.tmpl file."
	exit
fi

cp -i TEMPLATE/build.sh.tmpl .

./bin/JsonToConfig-$(uname -s) -json "${JSONFILE}" -create build.sh.tmpl -shell

if [ ! -f README.md ]
then
	./bin/JsonToConfig -template ./TEMPLATE/README.md.tmpl -json "${JSONFILE}" -out README.md
fi

