# Backups

The `backup` Compose service runs the portable scheduler. It creates a
PostgreSQL custom-format dump and an archive of Paperless file-backed state
(`data`, `media`, `export`, and `consume`) plus `compose.yml` and `.env`.

Start the scheduler with the rest of the stack:

```sh
docker compose up -d
```

The default schedule is weekly on Sunday at 03:15 in `Europe/Berlin`. The
service retains exactly 52 weekly backups. Change `BACKUP_SCHEDULE`, `TZ`, or
`RETENTION_COUNT` in the `backup` service in `compose.yml`, then recreate it with
`docker compose up -d backup`.

Run a backup immediately without waiting for the schedule:

```sh
docker compose exec backup /usr/local/bin/paperless-container-backup
```

The host-side helper remains available for manual backups and uses the same
Compose backup service:

```sh
./scripts/paperless-backup.sh
```

The container and host-side helper both keep exactly 52 backup sets locally,
as configured by `RETENTION_COUNT` in `compose.yml`.

Local backups are not enough for disaster recovery. Copy them to a different
machine or object storage, preferably with an encrypted tool such as Restic,
and periodically perform a test restore. Do not back up the live `db/`
directory by copying it while PostgreSQL is running.