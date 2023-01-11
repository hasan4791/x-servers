FROM localhost/xs-baseimage-ubuntu:22.04

ARG ARCH="amd64"

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
  COREDNS_VERSION=$(curl -sX GET "https://api.github.com/repos/coredns/coredns/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]' | awk '{print substr($1,2); }') && \
  curl -o \
    /tmp/coredns.tar.gz -L \
    "https://github.com/coredns/coredns/releases/download/v${COREDNS_VERSION}/coredns_${COREDNS_VERSION}_linux_${ARCH}.tgz" && \
  tar xf \
    /tmp/coredns.tar.gz -C \
    /app && \
  echo "**** clean up ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 51820/udp
