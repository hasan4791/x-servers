#!/usr/bin/env bash

set -e

CONTAINER_NAME="$(basename "$(pwd)")"

if [ "$EUID" -ne 0 ]; then
    CONTAINER_MODE="rootless"
fi

if [ -z "${XSERVER_DATA_PATH}" ]; then
	CONFIG_PATH="$(pwd)"
else
	CONFIG_PATH="${XSERVER_DATA_PATH}"/"${CONTAINER_NAME}"
fi

if [[ ! -d "${CONFIG_PATH}"/config ]]; then
	mkdir -p "${CONFIG_PATH}"/config
fi

{% if user_id.stdout is defined %}
CONTAINER_USER={{ user_id.stdout }}
{% else %}
CONTAINER_USER="1000"
{% endif %}
{% if group_id.stdout is defined %}
CONTAINER_GROUP={{ group_id.stdout }}
{% else %}
CONTAINER_GROUP="1000"
{% endif %}
if [ "${CONTAINER_MODE}" == "rootless" ]; then
	# In rootless mode, container root user
	# is mapped to host's non-root user
{% if xserver_container_non_root_uid is defined %}
	CONTAINER_USER={{ xserver_container_non_root_uid }}
{% else %}
	CONTAINER_USER=0
{% endif %}
	CONTAINER_GROUP=0
fi

# Run container in podman with
# PUID & PGID of non-root user
# inside the container
podman run -d \
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
{% if wg_mode is not defined or wg_mode == "server" %}
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
	-e ALLOWEDIPS={{ wg_allowed_ips|ipaddr('net') }} \
{% else %}
	-e ALLOWEDIPS=0.0.0.0/0 \
{% endif %}
{% if wg_keepalive_peers is defined %}
	-e PERSISTENTKEEPALIVE_PEERS={{ wg_keepalive_peers }} \
{% else %}
    -e PERSISTENTKEEPALIVE_PEERS="all" \
{% endif %}
	-p 51820:51820/udp \
{% endif %}
{% if wg_log_confs is defined %}
	-e LOG_CONFS={{ wg_log_confs|bool }} \
{% else %}
	-e LOG_CONFS=true \
{% endif %}
	-v "${CONFIG_PATH}"/config:/config:Z \
{% if wg_mode == "client" %}
	--sysctl="net.ipv4.conf.all.src_valid_mark=1" \
{% endif %}
	--restart always \
	localhost/xs-wireguard:latest

{% if xserver_os is defined and xserver_os == "pios11" %}
SVC="container-wireguard.service"
systemctl disable "${SVC}"
rm -rf /lib/systemd/system/"${SVC}"
podman generate systemd --name wireguard --restart-policy no > /lib/systemd/system/"${SVC}"
systemctl enable "${SVC}"
{% endif %}
