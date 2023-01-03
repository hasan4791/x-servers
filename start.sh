#!/usr/bin/env bash

set -e

WORKING_DIR="$(pwd)"

if [[ ! -d "${WORKING_DIR}"/config ]]; then
	mkdir -p "${WORKING_DIR}"/config
	mkdir -p "${WORKING_DIR}"/config/db
	mkdir -p "${WORKING_DIR}"/config/web-ssl
	touch "${WORKING_DIR}"/config/as.conf
fi

#Run as Roolful mode
sudo podman run -d \
	--name=openvpnas \
	--cap-add=NET_ADMIN \
	--device=/dev/net/tun \
	-e PUID=1000 \
	-e PGID=1000 \
	-h openvpnas \
	-e TZ=Asia/Kolkata \
	-p 943:9943/tcp \
	-p 1194:11194/tcp \
	-p 1194:11194/udp \
	-v "${WORKING_DIR}"/config/as.conf:/usr/local/openvpn_as/etc/as.conf:Z \
	-v "${WORKING_DIR}"/config/db:/usr/local/openvpn_as/etc/db:Z \
	-v "${WORKING_DIR}"/config/web-ssl:/usr/local/openvpn_as/etc/web-ssl:Z \
	--restart always \
	localhost/openvpnas:latest
