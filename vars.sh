
# docker image naming
TAG_BASE=${TAG_BASE:-softether}
TAG_VERSION=4.41-9782-beta
# github 
GITHUB_REPO="SoftEtherVPN/SoftEtherVPN_Stable"
BUILD_VERSION=v${TAG_VERSION}
ARCHIVE=${BUILD_VERSION}.tar.gz
ARCHIVE_SHA256=fbf6e04c4451d0cb1555c3a53c178b5453c7d761119f82fd693538c9f115fecb

# name of runing container
CONT_NAME="vpn"
# new unprivileged user
CONT_UID=666
CONT_GID=666
CONT_USER="vpn"
CONT_HOME="/usr/vpnserver"
# groups of the new user, comma sepparated list
CONT_GROUPS=

# RUNTIME
VOLUMES=$PWD/conf:/etc/vpnserver,softether_log:/var/log/vpnserver
DEVICES=/dev/net/tun
PUBLISH_PORTS=443:443/tcp,500:500/udp,1194:1194/udp,1701:1701/tcp,4500:4500/udp,5555:5555/tcp
HOST_IP=127.0.0.1
CAPS=NET_ADMIN,NET_RAW,NET_BIND_SERVICE,SYSLOG

