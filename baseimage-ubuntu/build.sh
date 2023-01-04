#!/usr/bin/env bash

S6_OVERLAY_VERSION=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | \
                        awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }')

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
    -t localhost/xs-baseimage-ubuntu:22.04 \
    -f Dockerfile .
