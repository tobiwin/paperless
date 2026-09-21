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

## Restore

### 1. Choose the backup

Choose the backup set to restore and stop the stack:

```sh
BACKUP=backup/2026-09-21T14-28-25+0200
docker compose down
```

### 2. Restore the files

Restore the file-backed Paperless data. This intentionally does not extract
the archived `.env` or `compose.yml`:

```sh
tar -xzf "$BACKUP/paperless-files.tar.gz" -C . data media export consume
```

### 3. Restore the database

Start only PostgreSQL:

```sh
docker compose up -d --wait db
```

Recreate the Paperless database:

```sh
docker compose exec -T db sh -c \
	'dropdb --if-exists -U "$POSTGRES_USER" paperless && \
	 createdb -U "$POSTGRES_USER" paperless'
```

Restore the PostgreSQL dump:

```sh
docker compose exec -T db sh -c \
	'pg_restore --no-owner --no-acl -U "$POSTGRES_USER" -d paperless' \
	< "$BACKUP/paperless.dump"
```

### 4. Start Paperless

Start Paperless again:

```sh
docker compose up -d
```

This replaces the current database and file-backed data. Make a separate copy
of the current `db`, `data`, `media`, `export`, and `consume` directories first
if they may still be needed.

Local backups are not enough for disaster recovery. Copy them to a different
machine or object storage, preferably with an encrypted tool such as Restic,
and periodically perform a test restore. Do not back up the live `db/`
directory by copying it while PostgreSQL is running.