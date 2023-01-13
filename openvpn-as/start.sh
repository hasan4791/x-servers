#!/usr/bin/env bash

set -e

CONTAINER_NAME="$(basename "$(pwd)")"
CONTAINER_MODE="$1"

if [ -z "${XSERVER_DATA_PATH}" ]; then
	CONFIG_PATH="$(pwd)"
else
	CONFIG_PATH="${XSERVER_DATA_PATH}"/"${CONTAINER_NAME}"
fi

if [[ ! -d "${CONFIG_PATH}"/config ]]; then
	mkdir -p "${CONFIG_PATH}"/config
fi

#Defaults to rootful mode
CONTAINER_BIN="sudo podman"
CONTAINER_USER=1000
CONTAINER_GROUP=1000
if [ "${CONTAINER_MODE}" == "rootless" ]; then
	CONTAINER_BIN="podman"
	# In rootless mode, container root user
	# is mapped to host's non-root user
	CONTAINER_USER=5000
	CONTAINER_GROUP=0
fi

# Run as Root container in podman
# with PUID & PGID of non-root user
# inside the container
${CONTAINER_BIN} run -d \
	--name="${CONTAINER_NAME}" \
	--cap-add=NET_ADMIN \
	--device=/dev/net/tun \
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
	-e TZ=Asia/Kolkata \
	-p 9943:943/tcp \
	-p 1194:1194/tcp \
	-p 1194:1194/udp \
	-v "${CONFIG_PATH}"/config:/config:Z \
	--restart always \
	localhost/xs-openvpn-as:latest
