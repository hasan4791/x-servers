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
	-h "${CONTAINER_NAME}" \
	-e PUID="${CONTAINER_USER}" \
	-e PGID="${CONTAINER_GROUP}" \
{% if nd_timezone is defined %}
	-e TZ={{ nd_timezone }} \
{% else %}
	-e TZ=Asia/Kolkata \
{% endif %}
{% if nd_mediafolder is defined %}
	-v {{ nd_mediafolder }}:/music:ro \
{% endif %}
	-v "${CONFIG_PATH}"/config/navidrome.toml:/config/navidrome.toml:ro \
	-v "${CONFIG_PATH}"/config:/config:Z \
	-p 4533:4533 \
	--restart always \
	localhost/xs-navidrome:latest