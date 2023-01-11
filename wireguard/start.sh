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
	-h wireguard \
	-e PUID=1000 \
	-e PGID=1000 \
	-e TZ=Asia/Kolkata \
	-e SERVERURL=wg.tkch.co.in \
	-e SERVERPORT=51820 \
	-e PEERS="iphone14plus" \
	-e PEERDNS=94.140.14.14,94.140.15.15 \
	-e INTERNAL_SUBNET=172.32.1.0 \
	-e ALLOWEDIPS=0.0.0.0/0 \
	-e LOG_CONFS=true \
	-p 51820:51820/udp \
	-v "${CONFIG_PATH}"/config:/config:Z \
	--restart always \
	localhost/xs-wireguard:latest
