#!/usr/bin/env bash

S6_OVERLAY_VERSION="3.1.2.1"

if [ "$1" == "arm64" ]; then
    TARGET_ARCH="arm64"
    S6_OVERLAY_ARCH="aarch64"
elif [ "$1" == "amd64" ]; then
    TARGET_ARCH="amd64"
    S6_OVERLAY_ARCH="x86_64"
else
    echo "Invalid Arch value $1"
    exit 1
fi

podman build --arch="${TARGET_ARCH}" \
    --build-arg S6_OVERLAY_ARCH="${S6_OVERLAY_ARCH}" \
    --build-arg S6_OVERLAY_VERSION="${S6_OVERLAY_VERSION}" \
    --build-arg ARCH="${TARGET_ARCH}" \
    -t localhost/xs-wireguard:latest \
    -f Dockerfile .
