#!/usr/bin/env bash

set -ex

XSERVER_IMG="baseimage-ubuntu openvpn-as wireguard"
XSERVERS="openvpn-as wireguard"

if [ -e /tmp/lock ]; then
	echo "cronjob locked"
	exit 1
fi

touch /tmp/lock

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
for server in ${XSERVER_IMG}; do
	cd /root/x-servers/"$server"
	./build.sh "arm64"
	cd -
done

#Start containers
for server in ${XSERVERS}; do
	cd /root/x-servers/"$server"
	./start.sh
	cd -
done

#Clear podman cache
podman system prune -a -f

echo "System will reboot in 60 Seconds" | wall
sleep 60
rm -f /tmp/lock

#Reboot node
reboot
