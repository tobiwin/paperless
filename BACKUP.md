# PostgreSQL backups

The `backup` service makes one custom-format PostgreSQL dump each day at
03:15 in `Europe/Berlin`. Each dump is written directly into `BACKUP_DIR` as
`paperless-YYYY-MM-DD.dump`. This service backs up only the database; it does
not archive Paperless documents or application files.

## Unraid setup and use

Deploy or update the stack with Unraid's Docker Compose Manager. The `backup`
service starts with the stack and schedules backups itself, so no
`docker-compose` or `docker compose` command is needed on the Unraid shell.
Make sure `BACKUP_DIR` points to a persistent Unraid share with enough free
space and write permissions.

To run a dump immediately, open the `backup` container's console in Unraid and
run:

```sh
/usr/local/bin/paperless-postgres-backup
```

The scheduled service logs success or failure in the container log. Set
`BACKUP_SCHEDULE` in `.env` to change the cron schedule; its default is
`15 3 * * *`.

## Retention

The service keeps the union of these tiers:

- Every daily dump from the last 30 days, including today.
- The latest dump from each of the 12 completed calendar months before the
  current month.
- The latest dump from each of the two calendar years before that 12-month
  window.

The same dump can satisfy more than one tier. Retention only removes files
named `paperless-YYYY-MM-DD.dump`; any older backup directories or unrelated
files in `BACKUP_DIR` are left untouched.

## Restore

Use Unraid's Compose Manager to stop the `webserver` service before restoring
so the application does not write to the database. Open the `backup`
container's console and replace `2026-10-04` below with the date to restore:

```sh
dropdb --if-exists -h "$PGHOST" -U "$PGUSER" "$PGDATABASE"
createdb -h "$PGHOST" -U "$PGUSER" "$PGDATABASE"
pg_restore --no-owner --no-acl -h "$PGHOST" -U "$PGUSER" \
  -d "$PGDATABASE" "/backup/paperless-2026-10-04.dump"
```

Start `webserver` again from Compose Manager when the restore is complete.
Restoring replaces the current database. Take a separate copy first if the
current database may still be needed.

These dumps cover only PostgreSQL. Back up the Paperless data, media, export,
and consume directories separately. A later Duplicati job can include those
directories and this dump folder, then copy the backup to another drive and
S3. Periodically test a restore.
