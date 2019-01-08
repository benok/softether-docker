FROM alpine:3.8 as prep

ARG GITHUB_REPO=SoftEtherVPN/SoftEtherVPN_Stable
ARG BUILD_VERSION=4.28-9669-beta
ARG ARCHIVE=v4.28-9669-beta.tar.gz
ARG ARCHIVE_SHA256=fbf6e04c4451d0cb1555c3a53c178b5453c7d761119f82fd693538c9f115fecb

RUN apk add -U ca-certificates \
 && wget https://github.com/${GITHUB_REPO}/archive/${ARCHIVE} -O ${ARCHIVE} \
 && echo "${ARCHIVE_SHA256}  ${ARCHIVE}" | sha256sum -c \
 && mkdir -p /usr/local/src \
 && tar -x -C /usr/local/src/ -f ${ARCHIVE} \
 && rm ${ARCHIVE}

FROM alpine:3.8 as build

COPY --from=prep /usr/local/src /usr/local/src

ENV LANG=en_US.UTF-8

RUN apk add -U build-base ncurses-dev openssl-dev readline-dev zip \
 && cd /usr/local/src/SoftEtherVPN_Stable-* \
 && ./configure \
 && make \
 && make install \
 && touch /usr/vpnserver/vpn_server.config

FROM alpine:3.8

# UID and GID of new user
ARG uid=666
ARG gid=666
ARG user=vpn
# GIDs to grant access rights for the new user
ARG gids=

RUN apk update \
 && apk add --update --no-cache bash musl shadow \
            openssl readline iptables ncurses ca-certificates \
 && rm -rf /var/cache/apk/*

COPY scripts /opt

WORKDIR /usr

COPY --from=build /usr/vpnserver/ vpnserver/
COPY --from=build /usr/vpncmd/ vpncmd/
COPY --from=build /usr/vpnbridge/ vpnbridge/
COPY --from=build /usr/bin/vpn* bin/

ENV LANG=en_US.UTF-8

RUN chmod +x /opt/*.sh \
 && mkdir -p /var/log/vpnserver \
 && for fn in server security packet; do \
      if [ ! -d "/var/log/vpnserver/${fn}_log" ]; then \
        mkdir -p /var/log/vpnserver/${fn}_log; \
      fi \
    done \
 && ln -fs /var/log/vpnserver/*_log /usr/vpnserver/

# add new user and set groups
RUN groupadd -g ${gid} ${user} \
 && useradd -rNM -s /bin/bash -g ${user} -u ${uid} ${user} \
 && for g in ${gids//,/ }; do \
      if ! grep -q "[^:]*[:][^:]*[:]$g[:]" /etc/group; then \
        echo "New group grp$g"; \
        groupadd -g $g grp$g && usermod -aG grp$g ${user}; \
      fi; \
    done \
 && chmod g+rw -R /run/ /usr/vpn* /var/log/vpnserver \
 && chown :${user} -R /run/ /usr/vpn* /var/log/vpnserver

VOLUME ["/var/log/vpnserver"]

# switch user
USER ${user}

WORKDIR /usr/vpnserver/

ENTRYPOINT ["/opt/entrypoint.sh"]

CMD ["/usr/bin/vpnserver", "execsvc"]
