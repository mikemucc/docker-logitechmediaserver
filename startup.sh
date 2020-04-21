#!/bin/sh
/lms-setup.sh
# run server directly as lms user to avoid permissions bug on fresh startup
exec su lms -c "/usr/sbin/squeezeboxserver --prefsdir /mnt/state/prefs --logdir /mnt/state/logs --cachedir /mnt/state/cache --charset=utf8"
