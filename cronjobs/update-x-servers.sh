#!/usr/bin/env bash

set -ex

if [ -e /tmp/lock ]; then
	echo "cronjob locked"
	exit 1
fi

touch /tmp/lock

if [ "$EUID" -ne 0 ]; then
	ALERT_MSG="/tmp/alert-rootless.json"
	CONTAINER_STATUS_TITLE="Rootless Container Status"
else
	ALERT_MSG="/tmp/alert.json"
	CONTAINER_STATUS_TITLE="Container Status"
fi

#Set default install path
if [ -z "${XSERVER_PATH}" ]; then
	XSERVER_PATH="/root/x-servers"
fi

if [ "$(podman ps -a --format "{{.Names}}" | wc -l)" -eq 0 ]; then
	echo "No containers are running"
	node_update
	node_reboot
fi
XSERVERS=$(podman ps -a --format "{{.Names}}")
XSERVER_IMG="baseimage-ubuntu ${XSERVERS}"

send_slack_notification() {
	STATUS="$1"
	if [ "${STATUS}" == "success" ]; then
		STATUS=":white_check_mark:"
	else
		STATUS=":x:"
	fi
	cp "${XSERVER_PATH}"/cronjobs/alert.json.template "${ALERT_MSG}"
	sed -i -e "s/_CONTAINER_STATUS_TITLE_/${CONTAINER_STATUS_TITLE}/g" "${ALERT_MSG}"
	sed -i -e "s/_HOSTNAME_/${HOSTNAME}/g" "${ALERT_MSG}"
	sed -i -e "s/_STATUS_ICON_/${STATUS}/g" "${ALERT_MSG}"
	#shellcheck disable=SC2028
	CONTAINER_STATUS=$(for i in $(podman ps -a --format "{{.Names}}:{{.Status}}" | sed -e "s/ /_/g"); do echo -n "$i\\n"; done)
	sed -i -e "s/_CONTAINER_STATUS_/${CONTAINER_STATUS}/g" "${ALERT_MSG}"
	curl -X POST -H 'Content-type: application/json' --data-binary "@${ALERT_MSG}" "$SLACK_URL"
	rm -rf "${ALERT_MSG}"
}

handle_failure() {
	#Start container with previous image
	start_containers
	send_slack_notification "fail"
	rm -f /tmp/lock
}

start_containers() {
	for server in ${XSERVERS}; do
		cd "${XSERVER_PATH}/$server"
		./start.sh
		cd -
	done
}

node_update() {
	if [ "$EUID" -eq 0 ]; then
		if grep -qi "fedora" </etc/os-release; then
			dnf update -y
			dnf upgrade -y
		elif grep -qi "debian" </etc/os-release; then
			apt-get update -y
			apt-get upgrade -y
		fi
	fi
}

node_reboot() {
	rm -f /tmp/lock

	#Reboot node
	if [ "$EUID" -eq 0 ]; then
		echo "System will reboot in 60 Seconds" | wall
		sleep 60
		reboot
	fi
}

#trap on failure
trap handle_failure EXIT SIGTERM SIGINT

#Stop running containers
for server in ${XSERVERS}; do
	set +e
	podman stop "$server"
	podman rm "$server"
	set -e
done

#Update node packages
node_update

#Update container images
cd "${XSERVER_PATH}"
for server in ${XSERVER_IMG}; do
	./build.sh "${XSERVER_ARCH}" "$server"
done
cd -

#Remove failure handling
trap - EXIT SIGTERM SIGINT

#Start containers
start_containers

#Clear podman cache
podman system prune -a -f

#Send notification to Slack
# shellcheck disable=SC2236
if [ ! -z "${SLACK_URL}" ]; then
	send_slack_notification "success"
fi

#Remove lock & Reboot node
node_reboot
