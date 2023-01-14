#!/usr/bin/env bash

set -e

#Input parametes
BUILD_ARCH=$1
BUILD_SERVERS=$2
BUILD_MODE=$3

#Build arguments
S6_OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')
ANSIBLE_CORE_VERSION="2.13.7"
COREDNS_VERSION=$(curl -sX GET "https://api.github.com/repos/coredns/coredns/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')

XSERVER_DIRS=("baseimage-ubuntu" "openvpn-as" "wireguard")
XSERVER_REGISTRY="localhost"
#shellcheck disable=SC2034
declare -A XSERVER_IMG
XSERVER_IMG["baseimage-ubuntu"]="xs-baseimage-ubuntu:22.04"
XSERVER_IMG["openvpn-as"]="xs-openvpn-as:latest"
XSERVER_IMG["wireguard"]="xs-wireguard:latest"
XSERVER_IMG["."]="xs-ansible-core:latest"

if [ "$BUILD_ARCH" == "arm64" ]; then
	TARGET_ARCH="arm64"
	S6_OVERLAY_ARCH="aarch64"
elif [ "$BUILD_ARCH" == "amd64" ]; then
	TARGET_ARCH="amd64"
	S6_OVERLAY_ARCH="x86_64"
else
	echo "Invalid Arch value $BUILD_ARCH"
	exit 1
fi

if [ -z "${BUILD_SERVERS}" ]; then
	BUILD_SERVERS="${XSERVER_DIRS[*]}"
fi

#Defaults to rootful mode
CONTAINER_BIN="sudo podman"
if [ "${BUILD_MODE}" == "rootless" ]; then
	CONTAINER_BIN="podman"
fi

#Create images
for server in ${BUILD_SERVERS}; do
	${CONTAINER_BIN} build --arch="${TARGET_ARCH}" \
		--build-arg S6_OVERLAY_ARCH="${S6_OVERLAY_ARCH}" \
		--build-arg S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}" \
		--build-arg ARCH="${TARGET_ARCH}" \
		--build-arg ANSIBLE_CORE_VERSION="${ANSIBLE_CORE_VERSION}" \
		--build-arg COREDNS_VERSION="${COREDNS_VERSION}" \
		-t "${XSERVER_REGISTRY}"/"${XSERVER_IMG[$server]}" \
		-f "$server"/Dockerfile \
		"$server"/.
done
