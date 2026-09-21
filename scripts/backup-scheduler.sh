#!/bin/sh
set -eu

BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-"15 3 * * *"}

printf '%s root /bin/sh /usr/local/bin/paperless-container-backup >> /proc/1/fd/1 2>> /proc/1/fd/2\n' \
    "$BACKUP_SCHEDULE" \
    > /etc/cron.d/paperless-backup

chmod 0644 /etc/cron.d/paperless-backup

exec cron -f