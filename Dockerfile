FROM buildpack-deps:buster-curl

ARG DEBIAN_FRONTEND=noninteractive

# Env variables persisted in container
ARG LMS_PATCHES
ENV LMS_PATCHES=$LMS_PATCHES
ARG PUID=819
ARG PGID=819
ENV PUID $PUID
ENV PGID $PGID

# 7.9.3 nightly release
ARG LMSDEB=http://downloads.slimdevices.com/nightly/7.9/sc/11c9213d53dce3231feb3ca6e4ee5fa63d81fc0d/logitechmediaserver_7.9.3~1586752599_all.deb

RUN echo "deb http://www.deb-multimedia.org buster main non-free" | tee -a /etc/apt/sources.list && \
    apt-get update -o Acquire::AllowInsecureRepositories=true && apt-get install -y --allow-unauthenticated deb-multimedia-keyring && \
    apt-get install -y --allow-unauthenticated \
    perl \
    libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl libio-socket-ssl-perl \
    locales \
    espeak \
    faad \
    faac \
    flac \
    lame \
    sox \
    ffmpeg \
    wavpack \
    patch \
    --no-install-recommends && \
    apt-get upgrade -y --allow-unauthenticated && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -o /tmp/lms.deb $LMSDEB && \
    dpkg -i /tmp/lms.deb && \
    rm -f  /tmp/lms.deb

RUN mkdir /mnt/state /mnt/music /mnt/playlists

ARG LOCALE=en_GB.UTF-8
ENV LANG=$LOCALE
RUN echo "$LOCALE UTF-8" > /etc/locale.gen && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
    echo LANG=\"$LOCALE\" > /etc/default/locale
    
COPY lms-setup.sh startup.sh *.patch /

# Apply our patches if LMS_PATCHES=y
RUN if [ -n "$LMS_PATCHES" ]; then cd /usr/share/perl5; for f in /*.patch; do patch -p1 < "$f"; done; fi

VOLUME ["/mnt/state","/mnt/music","/mnt/playlists"]

EXPOSE 3483 3483/udp 9000 9005 9010 9090 5353 5353/udp

HEALTHCHECK --interval=3m --timeout=30s \
    CMD curl --fail http://localhost:9000/Default/settings/index.html || exit 1

CMD ["/startup.sh"]
