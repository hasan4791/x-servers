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

#Check server is running
SERVER_PID="$(cut -d'=' -f2 < /run/openvpnas.service.status)"
echo "PID:${SERVER_PID}"
#kill -0 "${SERVER_PID}" >/dev/null 2>&1
if ! kill -0 "${SERVER_PID}" >/dev/null 2>&1 ; then
        echo "OpenVPN Server not running..."
        exit 1
fi
echo "OpenVPN Server is running"

#Workaround for SSL error
SERVER_URL="$(sqlite3 /usr/local/openvpn_as/etc/db/config_local.db "SELECT * FROM config;" | grep "host.name" | cut -d'|' -f3)"
SERVER_PORT="$(sqlite3 /usr/local/openvpn_as/etc/db/config_local.db "SELECT * FROM config;" | grep "vpn.server.daemon.tcp.port" | cut -d'|' -f3)"
SSL_ERROR="$(wget https://"${SERVER_URL}":"${SERVER_PORT}" 2>&1 | grep -c "unexpected eof while reading" || true)"

if [[ "${SSL_ERROR}" -ne 0 ]]; then
        echo "SSL Error: unexpected eof while reading"
        exit 1
fi

trap stop-server EXIT SIGTERM SIGINT

stop-server() {
        kill -9 "${SERVER_PID}"
        RUN="false"
}

RUN="true"
while "${RUN}"; do sleep 5; done
