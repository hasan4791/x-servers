#!/usr/bin/env bash

set -e

WORKING_DIR="$(pwd)"

if [[ ! -d "${WORKING_DIR}"/config ]]; then
	mkdir -p "${WORKING_DIR}"/config
fi

podman run -d \
	--name=wireguard \
	--cap-add=NET_ADMIN \
	-e PUID=1000 \
	-e PGID=1000 \
    {% if var_timezone is defined %}
	-e TZ= {{ var_timezone }} \
    {% else %}
    -e TZ=Asia/Kolkata \
    {% endif %}
    {% if var_wg_server_url is defined %} \
	-e SERVERURL={{ var_wg_server_url }} \
    {% else %}
    -e SERVERURL=auto \
    {% endif %}
    {% if var_wg_server_port is defined %}
	-e SERVERPORT= {{ var_wg_server_port }} \
    {% else %}
	-e SERVERPORT=51820 \
    {% endif %}
    {% if var_wg_peers is defined %}
    -e PEERS= {{ var_wg_peers }} \
    {% else %}
	-e PEERS=1 \
    {% endif %}
    {% if var_wg_peer_dns is defined %}
    -e PEERDNS= {{ var_wg_peer_dns }} \
    {% else %}
	-e PEERDNS=auto \
    {% endif %}
    {% if var_wg_internal_subnet is defined %}
	-e INTERNAL_SUBNET={{ var_wg_internal_subnet|ipaddr('address') }} \
    {% else %}
	-e INTERNAL_SUBNET=172.32.1.0 \
    {% endif %}
    {% if var_wg_allowed_ips is defined %}
	-e ALLOWEDIPS={{ var_wg_allowed_ips|ipaddr('address') }} \
    {% else %}
    -e ALLOWEDIPS=0.0.0.0/0 \
    {% endif %}
    {% if var_wg_log_confs is defined %}
	-e LOG_CONFS={{ var_wg_log_confs|bool }} \
    {% else %}
    -e LOG_CONFS=true
    {% endif %}
	-p 51820:51820/udp \
	-v "${WORKING_DIR}"/config:/config:Z \
	--restart always \
	lscr.io/linuxserver/wireguard:latest
