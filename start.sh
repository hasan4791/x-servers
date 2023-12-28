#!/usr/bin/env bash

set -e

CONTAINER_NAME="ansible"

if [ "$EUID" -ne 0 ]; then
	CONTAINER_MODE="rootless"
fi

if [ -z "${XSERVER_DATA_PATH}" ]; then
	CONFIG_PATH="$(pwd)"
else
	CONFIG_PATH="${XSERVER_DATA_PATH}"/"${CONTAINER_NAME}"
fi

CONTAINER_USER="1000"
CONTAINER_GROUP="1000"
if [ "${CONTAINER_MODE}" == "rootless" ]; then
	# In rootless mode, container root user
	# is mapped to host's non-root user
	CONTAINER_USER=0
	CONTAINER_GROUP=0
fi

# Run container in podman with
# PUID & PGID of non-root user
# inside the container
podman run -d \
	--name="${CONTAINER_NAME}" \
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
	-e TZ=Asia/Kolkata \
	-v "${CONFIG_PATH}":/x-servers \
	--restart always \
	localhost/xs-ansible-core:latest
