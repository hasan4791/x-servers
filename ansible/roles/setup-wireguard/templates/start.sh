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
CONTAINER_USER="1000"
CONTAINER_GROUP="1000"
if [ "${CONTAINER_MODE}" == "rootless" ]; then
	CONTAINER_BIN="podman"
	# In rootless mode, container root user
	# is mapped to host's non-root user
	CONTAINER_USER=0
	CONTAINER_GROUP=0
fi

# Run as Root container in podman
# with PUID & PGID of non-root user
# inside the container
${CONTAINER_BIN} run -d \
	--name="${CONTAINER_NAME}" \
	--cap-add=NET_ADMIN \
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
{% if wg_timezone is defined %}
	-e TZ={{ wg_timezone }} \
{% else %}
	-e TZ=Asia/Kolkata \
{% endif %}
{% if wg_server_url is defined %}
	-e SERVERURL={{ wg_server_url }} \
{% else %}
	-e SERVERURL=auto \
{% endif %}
{% if wg_server_port is defined %}
	-e SERVERPORT={{ wg_server_port }} \
{% else %}
	-e SERVERPORT=51820 \
{% endif %}
{% if wg_peers is defined %}
	-e PEERS={{ wg_peers }} \
{% else %}
	-e PEERS=1 \
{% endif %}
{% if wg_peer_dns is defined %}
	-e PEERDNS={{ wg_peer_dns }} \
{% else %}
	-e PEERDNS=auto \
{% endif %}
{% if wg_internal_subnet is defined %}
	-e INTERNAL_SUBNET={{ wg_internal_subnet|ipaddr('address') }} \
{% else %}
	-e INTERNAL_SUBNET=172.32.1.0 \
{% endif %}
{% if wg_allowed_ips is defined %}
	-e ALLOWEDIPS={{ wg_allowed_ips|ipaddr('address') }} \
{% else %}
	-e ALLOWEDIPS=0.0.0.0/0 \
{% endif %}
{% if wg_log_confs is defined %}
	-e LOG_CONFS={{ wg_log_confs|bool }} \
{% else %}
	-e LOG_CONFS=true \
{% endif %}
	-p 51820:51820/udp \
	-v "${CONFIG_PATH}"/config:/config:Z \
	--restart always \
	localhost/xs-wireguard:latest
