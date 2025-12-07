FROM alpine:3.21

ARG ZAPRET_REPO=https://github.com/bol-van/zapret.git
ARG ZAPRET_REF=master

# nfqws için gerekli netfilter dev paketleri + curl
RUN apk add --no-cache \
    bash git ca-certificates curl \
    build-base linux-headers \
    libevent-dev openssl-dev zlib-dev \
    bsd-compat-headers libcap-dev \
    iptables ip6tables nftables iproute2 \
    libmnl-dev libnfnetlink-dev libnetfilter_queue-dev \
    libpcap-dev \
    nmap-ncat \
    tinyproxy dumb-init coreutils

WORKDIR /opt
RUN git clone --depth=1 --branch ${ZAPRET_REF} ${ZAPRET_REPO} zapret

WORKDIR /opt/zapret

# nfqws ve mdig'i derle (top-level make bazı sürümlerde daha sağlıklı)
RUN make \
 && test -x /opt/zapret/nfq/nfqws \
 && test -x /opt/zapret/mdig/mdig

WORKDIR /opt/app
COPY start.sh /opt/app/start.sh
RUN chmod +x /opt/app/start.sh \
 && mkdir -p /opt/app/ipset

EXPOSE 8888

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/app/start.sh"]
