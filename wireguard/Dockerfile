FROM localhost/xs-baseimage-ubuntu:22.04

ARG ARCH="amd64"
ARG COREDNS_VERSION

RUN \
  echo "**** install dependencies ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ifupdown \
    iproute2 \
    iptables \
    iputils-ping \
    locales \
    net-tools \
    netcat \
    openresolv \
    qrencode \
    tzdata \
    nano \
    wireguard-tools && \
  echo "**** generate locale ****" && \
  locale-gen en_US.UTF-8 && \
  echo "**** install CoreDNS ****" && \
  curl -o \
    /tmp/coredns.tar.gz -L \
    "https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_${ARCH}.tgz" && \
  tar xf \
    /tmp/coredns.tar.gz -C \
    /app && \
  echo "**** clean up ****" && \
  apt-get autoremove && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /var/log/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 51820/udp
