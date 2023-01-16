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

mkdir -p "${CONFIG_PATH}"{/config,/config/log,/config/etc/db,/config/etc/web-ssl}
if [[ ! -f  "${CONFIG_PATH}"/config/etc/as.conf ]]; then
    touch "${CONFIG_PATH}"/config/etc/as.conf
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
	--device=/dev/net/tun \
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
{% if ov_timezone is defined %}
	-e TZ={{ ov_timezone }} \
{% else %}
	-e TZ=Asia/Kolkata \
{% endif %}
{% if ov_admin_port is defined and ov_admin_port_publish is defined %}
	-p {{ ov_admin_port_publish }}:{{ ov_admin_port }}/tcp \
{% elif ov_admin_port is defined %}}
	-p 943:{{ ov_admin_port }}/tcp \
{% elif ov_admin_port_publish is defined %}}
	-p {{ ov_admin_port }}:943/tcp \
{% else %}
	-p 943:943/tcp \
{% endif %}
{% if ov_client_port_tcp is defined and ov_client_port_tcp_publish is defined %}
	-p {{ ov_client_port_tcp_publish }}:{{ ov_client_port_tcp }}/tcp \
{% elif ov_client_port_tcp is defined %}}
	-p 443:{{ ov_client_port_tcp }}/tcp \
{% elif ov_client_port_tcp_publish is defined %}}
	-p {{ ov_client_port_tcp_publish }}:443/tcp \
{% else %}
	-p 443:443/tcp \
{% endif %}
{% if ov_client_port_udp is defined and ov_client_port_udp_publish is defined %}
	-p {{ ov_client_port_udp_publish }}:{{ ov_client_port_udp }}/udp \
{% elif ov_client_port_udp is defined %}}
	-p 1194:{{ ov_client_port_udp }}/udp \
{% elif ov_client_port_udp_publish is defined %}}
	-p {{ ov_client_port_udp_publish }}:1194/udp \
{% else %}
	-p 1194:1194/udp \
{% endif %}
	-v "${CONFIG_PATH}"/config/log:/config/log:Z \
	-v "${CONFIG_PATH}"/config/etc/as.conf:/config/etc/as.conf:Z \
	-v "${CONFIG_PATH}"/config/etc/db:/config/etc/db:Z \
	-v "${CONFIG_PATH}"/config/etc/web-ssl:/config/etc/web-ssl:Z \
	--restart always \
	localhost/xs-openvpn-as:latest
