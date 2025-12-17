#!/usr/bin/env bash

set -e

#Input parametes
BUILD_ARCH=$1
BUILD_SERVERS=$2

#Build arguments
ANSIBLE_CORE_VERSION="2.16.2"
S6_OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')
COREDNS_VERSION=$(curl -sX GET "https://api.github.com/repos/coredns/coredns/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')
NAVIDROME_VERSION=$(curl -sX GET "https://api.github.com/repos/navidrome/navidrome/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')
TAILSCALE_VERSION=$(curl -sX GET "https://api.github.com/repos/tailscale/tailscale/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')
ADGUARDHOME_VERSION=$(curl -sX GET "https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest" |
	awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')

XSERVER_DIRS=("baseimage-ubuntu" "openvpn-as" "wireguard" "navidrome" "tailscale" "adguard-home")
XSERVER_REGISTRY="localhost"
#shellcheck disable=SC2034
declare -A XSERVER_IMG
for dir in "${XSERVER_DIRS[@]}"; do
	tag="latest"
	if [[ "$dir" = *"ubuntu"* ]]; then
		tag="22.04"
	fi
	XSERVER_IMG["$dir"]="xs-$dir:$tag"
done
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

#Create images
for server in ${BUILD_SERVERS}; do
	podman build --arch="${TARGET_ARCH}" \
		--build-arg S6_OVERLAY_ARCH="${S6_OVERLAY_ARCH}" \
		--build-arg S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}" \
		--build-arg ARCH="${TARGET_ARCH}" \
		--build-arg ANSIBLE_CORE_VERSION="${ANSIBLE_CORE_VERSION}" \
		--build-arg COREDNS_VERSION="${COREDNS_VERSION}" \
		--build-arg NAVIDROME_VERSION="${NAVIDROME_VERSION}" \
		--build-arg TAILSCALE_VERSION="${TAILSCALE_VERSION}" \
		--build-arg ADGUARDHOME_VERSION="${ADGUARDHOME_VERSION}" \
		-t "${XSERVER_REGISTRY}"/"${XSERVER_IMG[$server]}" \
		-f "$server"/Containerfile \
		"$server"/.
done
