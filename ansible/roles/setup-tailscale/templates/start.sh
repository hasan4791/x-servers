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
	--device /dev/net/tun \
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
{% if ts_enable_ipv6 is defined and ts_enable_ipv6|bool %}
	--network=podman-dual-stack \
	--sysctl=net.ipv6.conf.all.forwarding=1 \
{% endif %}
{% if ts_timezone is defined %}
	-e TZ={{ ts_timezone }} \
{% else %}
	-e TZ=Asia/Kolkata \
{% endif %}
	-e TS_AUTHKEY={{ ts_auth_key }} \
	-e TS_EXTRA_ARGS="{{ ts_extra_args }}" \
	-e TS_USERSPACE=false \
	-e TS_STATE_DIR=/config \
	-e TS_ENABLE_HEALTH_CHECK=true \
{% if ts_set_mtu is defined %}
	-e TS_DEBUG_MTU={{ ts_set_mtu }} \
{% endif %}
{% if ts_peer_relay_endpoints is defined %}
	-e XS_PEER_RELAY_ENDPOINTS="{{ ts_peer_relay_endpoints }}" \
{% endif %}
{% if ts_peer_relay_port is defined and ts_peer_relay_port_publish is defined %}
	-e XS_PEER_RELAY_PORT={{ ts_peer_relay_port }} \
	-p {{ ts_peer_relay_port_publish }}:{{ ts_peer_relay_port }}/udp \
{% if ts_enable_ipv6 is defined and ts_enable_ipv6|bool %}
	-p [::]:{{ ts_peer_relay_port_publish }}:{{ ts_peer_relay_port }}/udp \
{% endif %}
{% elif ts_peer_relay_port is defined %}
	-p {{ ts_peer_relay_port }}:{{ ts_peer_relay_port }}/udp \
{% if ts_enable_ipv6 is defined and ts_enable_ipv6|bool %}
	-p [::]:{{ ts_peer_relay_port }}:{{ ts_peer_relay_port }}/udp \
{% endif %}
{% else %}
	-p 40000:40000/udp \
	-p [::]:40000:40000/udp \
{% endif %}
	-v "${CONFIG_PATH}"/config:/config:Z \
	--restart always \
	localhost/xs-tailscale:latest
