FROM localhost/xs-baseimage-ubuntu:22.04

ARG ANSIBLE_CORE_VERSION

ADD https://bootstrap.pypa.io/get-pip.py /tmp/

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        locales \
        nano \
        python3 \
        ssh \
        sshpass \
        tzdata && \
    locale-gen en_US.UTF-8 && \
    python3 /tmp/get-pip.py --user && \
    python3 -m pip install --user ansible-core=="${ANSIBLE_CORE_VERSION}" && \
    python3 -m pip install --user netaddr && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /var/log/* && \
    mkdir -p /x-servers && \
    chown -R xuser:xuser /x-servers && \
    echo "ansible-galaxy install -r /x-servers/ansible/requirements.yml" >> /root/.bashrc

ENV PATH=$PATH:/root/.local/bin

WORKDIR /x-servers/ansible
