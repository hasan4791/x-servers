FROM ubuntu:22.04

#Install Deps
RUN apt update && \
    apt -y install ca-certificates wget net-tools gnupg systemctl vim

#Add openvpn repo & Install
RUN wget https://as-repository.openvpn.net/as-repo-public.asc -qO /etc/apt/trusted.gpg.d/as-repository.asc && \
    echo "deb [arch=arm64 signed-by=/etc/apt/trusted.gpg.d/as-repository.asc] http://as-repository.openvpn.net/as/debian jammy main">/etc/apt/sources.list.d/openvpn-as-repo.list && \
    DEBIAN_FRONTEND=noninteractive apt update && \
    apt -y install openvpn-as && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /tmp/* \
           /var/lib/apt/lists/* \
           /var/tmp/* \
           /var/log/*

#Copy script
COPY entrypoint.sh /usr/bin/init-vpn

#Block
CMD ["init-vpn"]
