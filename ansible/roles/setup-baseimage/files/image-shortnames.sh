#!/usr/bin/env bash

set -e

FILE="/etc/containers/registries.conf.d/shortnames.conf"

if [ -f "${FILE}" ]; then
	if ! grep -qi "docker.io/library/busybox" <"${FILE}"; then
		echo "  #Busybox" >>"${FILE}"
		echo "  \"busybox\" = \"docker.io/library/busybox\"" >>"${FILE}"
	fi
fi
