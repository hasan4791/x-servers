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
        tzdata && \
    locale-gen en_US.UTF-8 && \
    python3 /tmp/get-pip.py --user && \
    python3 -m pip install --user ansible-core=="${ANSIBLE_CORE_VERSION}" && \
    apt-get autoremove && \
    apt-get clean && \
    rm -rf /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /var/log/* && \
    mkdir -p /x-servers && \
    chown -R xuser:xuser /x-servers

ENV PATH=$PATH:/root/.local/bin

WORKDIR /x-servers/ansible
