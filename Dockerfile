FROM buildpack-deps:stretch-curl

ENV DEBIAN_FRONTEND noninteractive
ARG http_proxy

RUN echo "deb http://www.deb-multimedia.org stretch main non-free" | tee -a /etc/apt/sources.list && \
    apt-get update && apt-get install -y --allow-unauthenticated deb-multimedia-keyring && \
    apt-get install -y --allow-unauthenticated \
    perl \
    libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl libio-socket-ssl-perl \
    locales \
    faad \
    faac \
    flac \
    lame \
    sox \
    ffmpeg \
    wavpack \
    --no-install-recommends && \
    apt-get upgrade -y --allow-unauthenticated && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 7.9.0 final release, 8th Mar 2017.
# http://downloads.slimdevices.com/LogitechMediaServer_v7.9.0/logitechmediaserver_7.9.0_all.deb
# 7.9.1 final release, 19th Apr 2018.
# Pass in LMSDEB to override. Using a nightly release, can be updated in place without rebuilding image.
ARG LMSDEB=http://downloads.slimdevices.com/LogitechMediaServer_v7.9.1/logitechmediaserver_7.9.1_all.deb

RUN curl -o /tmp/lms.deb $LMSDEB && \
    dpkg -i /tmp/lms.deb && \
    rm -f  /tmp/lms.deb

RUN echo "en_GB.UTF-8 UTF-8" > /etc/locale.gen && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
    echo LANG=\"en_GB.UTF-8\" > /etc/default/locale
ENV LANG=en_GB.UTF-8
    
# Move config dir to allow editing convert.conf, use a fixed UID to share externally
RUN useradd --system --uid 819 -M -s /bin/false -d /usr/share/squeezeboxserver -c "Logitech Media Server user" lms && \
    mkdir -p /mnt/state/etc && \
    mv /etc/squeezeboxserver /etc/squeezeboxserver.orig && \
    cp -pr /etc/squeezeboxserver.orig/* /mnt/state/etc && \
    ln -s /mnt/state/etc /etc/squeezeboxserver && \
    chown -R lms.lms /mnt/state

COPY lms-setup.sh startup.sh /

VOLUME ["/mnt/state","/mnt/music","/mnt/playlists"]

EXPOSE 3483 3483/udp 9000 9005 9010 9090 5353 5353/udp

HEALTHCHECK --interval=2m --timeout=5s \
    CMD curl --fail http://localhost:9000/Default/settings/index.html || exit 1

CMD ["/startup.sh"]
