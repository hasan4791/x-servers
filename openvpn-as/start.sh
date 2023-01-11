#!/usr/bin/env bash

set -e

CONTAINER_NAME=$(basename $(pwd))

if [ -z "${XSERVERS_DATA_PATH}" ]; then
    CONFIG_PATH="$(pwd)"
else
    CONFIG_PATH="${XSERVERS_DATA_PATH}"/"${CONTAINER_NAME}"
fi

if [[ ! -d "${CONFIG_PATH}"/config ]]; then
    mkdir -p "${CONFIG_PATH}"/config
fi

# Run as Root container in podman
# with PUID & PGID of non-root user
# inside the container
sudo podman run -d \
	--name="${CONTAINER_NAME}" \
	--cap-add=NET_ADMIN \
	--device=/dev/net/tun \
	-e PUID=1000 \
	-e PGID=1000 \
	-h openvpnas \
	-e TZ=Asia/Kolkata \
	-p 9943:943/tcp \
	-p 1194:443/tcp \
	-p 1194:1194/udp \
	-v "${CONFIG_PATH}"/config:/config:Z \
	--restart always \
	localhost/xs-openvpn-as:latest
