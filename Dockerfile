FROM alpine:3.20.3 as prep

ARG GITHUB_REPO=SoftEtherVPN/SoftEtherVPN_Stable
ARG BUILD_VERSION=v4.41-9782-beta
ARG ARCHIVE=v4.41-9782-beta.tar.gz
ARG ARCHIVE_SHA256=98e67f1d2ba7287ba8c04ecee32d48ae9da65e2ea799012822343cf9221976f6

RUN apk add --update --no-cache ca-certificates \
 && rm -rf /var/cache/apk/* \
 && wget https://github.com/${GITHUB_REPO}/archive/${ARCHIVE} -O ${ARCHIVE} \
 && echo "${ARCHIVE_SHA256}  ${ARCHIVE}" | sha256sum -c \
 && mkdir -p /usr/local/src \
 && tar -x -C /usr/local/src/ -f ${ARCHIVE} \
 && rm ${ARCHIVE}

FROM alpine:3.20.3 as build

COPY --from=prep /usr/local/src /usr/local/src
COPY patches/ /usr/local/src/patches/

ENV LANG=en_US.UTF-8

WORKDIR /usr/local/src/

# TODO: make under unpriveleged user
RUN apk add --update --no-cache build-base ncurses-dev openssl-dev \
            readline-dev zip ethtool zlib-dev \
 && rm -rf /var/cache/apk/* \
 && cd /usr/local/src/SoftEtherVPN_Stable-* \
 && if [ -d /usr/local/src/patches ]; then \
      for i in /usr/local/src/patches/*.patch; do \
        patch -p0 < $i; \
      done; \
    fi \
 && ./configure \
 && make \
 && make install \
 && strip /usr/vpnserver/vpnserver

FROM alpine:3.20.3

# UID and GID of new user
ARG uid=666
ARG gid=666
ARG user=vpn
# additional GIDs for the new user
ARG gids=

# install runtime dependecies
RUN apk add --update --no-cache musl libcap \
            libressl ncurses-libs readline bash iptables \
 && rm -rf /var/cache/apk/*

COPY scripts/ /
COPY --from=build /usr/vpnserver/ /usr/vpnserver/
COPY --from=build /usr/bin/vpnserver /usr/bin/
COPY --from=build /usr/vpncmd/ /usr/vpncmd/
COPY --from=build /usr/bin/vpncmd /usr/bin/

ENV LANG=en_US.UTF-8

RUN chmod +x /entrypoint.sh \
 && mkdir -p /var/log/vpnserver \
 && for fn in server security packet; do \
        mkdir -p /var/log/vpnserver/${fn}_log; \
    done \
 && ln -fs /var/log/vpnserver/*_log /usr/vpnserver/ \
 && mkdir -p /etc/vpnserver \
 && touch /etc/vpnserver/vpn_server.config \
 && mkdir /etc/vpnserver/backup.vpn_server.config \
 && mkdir /etc/vpnserver/chain_certs \
 && chmod 600 /etc/vpnserver/vpn_server.config \
 && chmod 700 /etc/vpnserver/backup.vpn_server.config \
 && chmod 700 /etc/vpnserver/chain_certs \
 && ln -fs /etc/vpnserver/vpn_server.config /usr/vpnserver/ \
 && ln -fs /etc/vpnserver/backup.vpn_server.config /usr/vpnserver/ \
 && ln -fs /etc/vpnserver/chain_certs /usr/vpnserver/

# add new user and set groups
RUN addgroup -g ${gid} -S ${user} \
 && adduser -SHD -G ${user} -u ${uid} ${user} \
 && for g in ${gids//,/ }; do \
      if ! grep -q "[^:]*[:][^:]*[:]$g[:]" /etc/group; then \
        echo "New group grp$g"; \
        addgroup -g $g -S grp$g && adduser $user grp$g; \
      fi; \
    done \
 && chmod g+rw -R /run/ /usr/vpn* /var/log/vpnserver /etc/vpnserver \
 && chown :${user} -R /run/ /usr/vpn* /var/log/vpnserver /etc/vpnserver $(readlink -f /sbin/iptables) \
 && setcap 'cap_net_admin,cap_net_broadcast,cap_sys_nice,cap_sys_admin,cap_net_bind_service,cap_net_raw,cap_setuid=+epi' /usr/vpnserver/vpnserver \
 && setcap 'cap_net_admin,cap_net_raw=+epi' $(readlink -f /sbin/iptables)

VOLUME ["/var/log/vpnserver", "/etc/vpnserver"]

# switch user
USER ${user}

WORKDIR /usr/vpnserver/

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/bin/vpnserver", "execsvc"]
