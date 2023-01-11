#!/usr/bin/env bash

set -ex

XSERVER_IMG="baseimage-ubuntu openvpn-as wireguard"
XSERVERS="openvpn-as wireguard"

#Set default install path
if [ -z "${XSERVER_PATH}" ]; then
	XSERVER_PATH="/root/x-servers"
fi

send_slack_notification() {
	STATUS="$1"
	if [ "${STATUS}" == "success" ]; then
		STATUS=":white_check_mark:"
	else
		STATUS=":x:"
	fi
	cp "${XSERVER_PATH}"/cronjobs/alert.json.template "${XSERVER_PATH}"/cronjobs/alert.json
	sed -i -e "s/_HOSTNAME_/${HOSTNAME}/g" "${XSERVER_PATH}"/cronjobs/alert.json
	sed -i -e "s/_STATUS_ICON_/${STATUS}/g" "${XSERVER_PATH}"/cronjobs/alert.json
	#shellcheck disable=SC2028
	CONTAINER_STATUS=$(for i in $(podman ps -a --format "{{.Names}}:{{.Status}}" | sed -e "s/ /_/g"); do echo -n "$i\\n"; done)
	sed -i -e "s/_CONTAINER_STATUS_/${CONTAINER_STATUS}/g" "${XSERVER_PATH}"/cronjobs/alert.json
	curl -X POST -H 'Content-type: application/json' --data-binary "@${XSERVER_PATH}/cronjobs/alert.json" "$SLACK_URL"
	rm -rf "${XSERVER_PATH}"/cronjobs/alert.json
}

handle_failure() {
	#Start container with previous image
	start_containers
	send_slack_notification "fail"
}

start_containers() {
	for server in ${XSERVERS}; do
		cd "${XSERVER_PATH}/$server"
		./start.sh
		cd -
	done
}

if [ -e /tmp/lock ]; then
	echo "cronjob locked"
	exit 1
fi

touch /tmp/lock

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
dnf update -y
dnf upgrade -y

#Update container images
cd "${XSERVER_PATH}"
for server in ${XSERVER_IMG}; do
	./build.sh "arm64" "$server"
done
cd -

#Remove failure handling
trap - EXIT SIGTERM SIGINT

#Start containers
start_containers

#Clear podman cache
podman system prune -a -f

#Send notification to Slack
send_slack_notification "success"

echo "System will reboot in 60 Seconds" | wall
sleep 60
rm -f /tmp/lock

#Reboot node
reboot
