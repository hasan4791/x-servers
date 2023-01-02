#!/usr/bin/env bash

set -e

WORKING_DIR="$(pwd)"

if [[ ! -d "${WORKING_DIR}"/config ]]; then
  mkdir -p "${WORKING_DIR}"/config
  mkdir -p "${WORKING_DIR}"/config/db
  mkdir -p "${WORKING_DIR}"/config/web-ssl
  touch "${WORKING_DIR}"/config/as.conf
fi

podman run -d \
  --name=openvpnas \
  --cap-add=NET_ADMIN \
  --device=/dev/net/tun \
  -h openvpnas \
  -e TZ=Asia/Kolkata \
  -p 943:943/tcp \
  -p 1194:11194/tcp \
  -p 1194:11194/udp \
  -v /root/ov-data/config/as.conf:/usr/local/openvpn_as/etc/as.conf:Z \
  -v /root/ov-data/config/db:/usr/local/openvpn_as/etc/db:Z \
  -v /root/ov-data/config/web-ssl:/usr/local/openvpn_as/etc/web-ssl:Z \
  --restart always \
 localhost/openvpnas:latest
