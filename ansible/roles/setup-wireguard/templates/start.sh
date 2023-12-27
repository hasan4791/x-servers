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
{% if xserver_container_non_root_id is defined %}
	CONTAINER_USER={{ xserver_container_non_root_id }}
	CONTAINER_GROUP={{ xserver_container_non_root_id }}
{% else %}
	CONTAINER_USER=0
	CONTAINER_GROUP=0
{% endif %}
fi

# Run container in podman with
# PUID & PGID of non-root user
# inside the container
podman run -d \
	--name="${CONTAINER_NAME}" \
	--cap-add=NET_ADMIN \
	--dns "1.1.1.1" \
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
	-e INTERNAL_SUBNET={{ wg_internal_subnet|ansible.utils.ipaddr('address') }} \
{% else %}
	-e INTERNAL_SUBNET=172.32.1.0 \
{% endif %}
{% if wg_allowed_ips is defined %}
	-e ALLOWEDIPS={{ wg_allowed_ips|ansible.utils.ipaddr('net') }} \
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
SVC="container-{{ xserver_name }}.service"
if [ "$EUID" -ne 0 ]; then
set +e
    systemctl --user stop "${SVC}"
    systemctl --user disable "${SVC}"
set -e
    mkdir -p ~/.config/systemd/user/
    rm -rf ~/.config/systemd/user/"${SVC}"
    podman generate systemd --name wireguard --restart-policy no > ~/.config/systemd/user/"${SVC}"
    sed -i -e "/ExecStop=/d" ~/.config/systemd/user/"${SVC}"
    sed -i -e "/ExecStopPost=/d" ~/.config/systemd/user/"${SVC}"
    sed -i -e "/PIDFile=/d" ~/.config/systemd/user/"${SVC}"
    systemctl --user enable "${SVC}"
    systemctl --user daemon-reload
else
set +e
    systemctl stop "${SVC}"
    systemctl disable "${SVC}"
set -e
    rm -rf /lib/systemd/system/"${SVC}"
    podman generate systemd --name wireguard --restart-policy no > /lib/systemd/system/"${SVC}"
    sed -i -e "/ExecStop=/d" /lib/systemd/system/"${SVC}"
    sed -i -e "/ExecStopPost=/d" /lib/systemd/system/"${SVC}"
    sed -i -e "/PIDFile=/d" /lib/systemd/system/"${SVC}"
    systemctl enable "${SVC}"
    systemctl daemon-reload
fi
{% endif %}
