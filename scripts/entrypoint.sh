#!/bin/sh
set -e

if [ "$1" = '/usr/vpnserver/vpnserver' ]; then

    # Linking Logs
    for d in server_log security_log packet_log;
    do
        if [ ! -L /usr/vpnserver/$d ]; then
          mkdir -p /var/log/vpnserver/$d
          ln -s /var/log/vpnserver/$d /usr/vpnserver/$d
        fi
    done

    # Starting
    echo "Starting SoftEther VPN Server"
    exec "$@"
else
    exec "$@"
fi
