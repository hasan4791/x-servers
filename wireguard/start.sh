#!/usr/bin/env bash

set -e

WORKING_DIR="$(pwd)"

if [[ ! -d "${WORKING_DIR}"/config ]]; then
	mkdir -p "${WORKING_DIR}"/config
fi

# Run as Root container in podman
# with PUID & PGID of non-root user
# inside the container
sudo podman run -d \
	--name=wireguard \
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
	-v "${WORKING_DIR}"/config:/config:Z \
	--restart always \
	localhost/xs-wireguard:latest
