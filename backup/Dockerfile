FROM docker.io/library/postgres:18

RUN apt-get update \
	&& apt-get install -y --no-install-recommends cron \
	&& rm -rf /var/lib/apt/lists/*

COPY scripts/container-backup.sh /usr/local/bin/paperless-container-backup
COPY scripts/backup-scheduler.sh /usr/local/bin/backup-scheduler
RUN chmod 0755 /usr/local/bin/paperless-container-backup /usr/local/bin/backup-scheduler

ENTRYPOINT ["/usr/local/bin/backup-scheduler"]