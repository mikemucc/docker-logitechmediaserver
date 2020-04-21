#!/bin/bash

# First startup: use a fixed UID/GID to share externally and move config dir to allow editing convert.conf.
if ! id -u lms >/dev/null 2>&1 ; then
    groupadd --gid $PGID lms
    useradd --system --uid $PUID --gid $PGID -M -d /usr/share/squeezeboxserver -c "Logitech Media Server user" lms
    mv /etc/squeezeboxserver /etc/squeezeboxserver.orig
    ln -s /mnt/state/etc /etc/squeezeboxserver
fi    

# Automatically update to newer version if exists
if [ -f /mnt/state/cache/updates/server.version ]; then
    cd /mnt/state/cache/updates
    UPDATE=`cat server.version`
    dpkg -i $UPDATE
    mv server.version this-server.version
    # Keep a history for rollback in case of problems;
    # to prune this add:  rm -f $UPDATE.

    # Apply patches if wanted
    if [ -n "$LMS_PATCHES" ]; then cd /usr/share/perl5; for f in /*.patch; do patch -p1 < "$f"; done; fi
    
    # Update the new config defaults (but leave user dir alone)
    rm -rf /etc/squeezeboxserver.orig
    mv /etc/squeezeboxserver /etc/squeezeboxserver.orig
    ln -s /mnt/state/etc /etc/squeezeboxserver
fi

# recreate startup config and cache dirs in case lost
mkdir -p /mnt/state/prefs /mnt/state/logs /mnt/state/cache
if [ ! -d /mnt/state/etc ]; then
   mkdir -p /mnt/state/etc
   cp -pr /etc/squeezeboxserver.orig/* /mnt/state/etc
fi

# State directory and playlists should be editable by the server
chown lms.lms -R /mnt/playlists
chown lms.lms -R /mnt/state
chmod g+s /mnt/state  /mnt/playlists
