#!/bin/bash
# {{ $.CreationInfo }}

# See gearboxworks/gearbox-base for details.
. /build/include-me.sh

c_ok "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Release test started."

if id -u gearbox
then
	c_ok "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Gearbox user found."
else
	c_err "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Gearbox user NOT found."
fi

if id -g gearbox
then
	c_ok "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Gearbox group found."
else
	c_err "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Gearbox group NOT found."
fi

c_ok "Gearbox[{{ .Json.name }}-{{ .Json.version }}]: Release test finished."

