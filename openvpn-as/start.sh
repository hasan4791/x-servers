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
	--name=openvpn-as \
	--cap-add=NET_ADMIN \
	--device=/dev/net/tun \
	-e PUID=1000 \
	-e PGID=1000 \
	-h openvpnas \
	-e TZ=Asia/Kolkata \
	-p 9943:943/tcp \
	-p 1194:443/tcp \
	-p 1194:1194/udp \
	-v "${WORKING_DIR}"/config:/config:Z \
	--restart always \
	localhost/xs-openvpn-as:latest
