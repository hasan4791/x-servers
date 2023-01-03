#!/usr/bin/env bash

set -e

if [[ ! -d /usr/local/openvpn_as ]]; then
        echo "Openvpn isn't installed"
        exit 1
elif [[ $(wc -l < /usr/local/openvpn_as/etc/as.conf) -ne 0 ]]; then
        echo "Starting OpenVPN Server..."
        systemctl start openvpnas
        sleep 10
        echo "Done"
else
        echo "Fresh Installation..."
        echo "Run \"/usr/local/openvpn_as/bin/ovpn-init\" to configure"
fi

SERVER_PID="$(cut -d'=' -f2 < /run/openvpnas.service.status)"
RUN="true"

trap stop-server EXIT SIGTERM SIGINT

stop-server() {
        kill -9 "${SERVER_PID}"
        RUN="false"
}
while "${RUN}"; do sleep 5; done
