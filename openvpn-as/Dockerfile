FROM localhost/xs-baseimage-ubuntu:22.04

#Arch
ARG ARCH="amd64"

#Install dependencies
RUN \
 echo "**** Install dependencies ****" && \
 apt-get update && \
 apt-get install -y --no-install-recommends \
 ca-certificates \
 locales \
 net-tools \
 gnupg \
 tzdata \
 nano \
 wget && \
 echo "**** generate locale ****" && \
 locale-gen en_US.UTF-8 && \
 echo "**** Add openvpn-as repo ****" && \
 wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc && \
 echo "deb [arch=${ARCH} signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian jammy main">/etc/apt/sources.list.d/openvpn-as-repo.list && \
 apt-get update -y && apt-get install -y openvpn-as && \
 apt-get autoremove && \
 apt-get clean && \
 echo "**** Ensure home folder for xuser user set to /config ****" && \
 usermod -d /config xuser && \
 rm -rf \
	/tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /var/log/* \
    #Delete openvpn related config files
    /usr/local/openvpn_as/init.log \
    /usr/local/openvpn_as/etc/db/* \
    /usr/local/openvpn_as/etc/as.conf \
    /usr/local/openvpn_as/etc/web-ssl/* \
    /usr/local/openvpn_as/log

#Copy S6 service files
COPY /root /

#Map Port & Volumes
EXPOSE 943/tcp 1194/udp 1194/tcp
VOLUME /config
