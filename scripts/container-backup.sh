#!/bin/sh
set -eu

BACKUP_ROOT=${BACKUP_ROOT:-/backup}
RETENTION_COUNT=${RETENTION_COUNT:-52}
STAMP=$(date +%Y-%m-%dT%H-%M-%S%z)
WORK_DIR="$BACKUP_ROOT/.working-$STAMP-$$"
ARCHIVE_DIR="$BACKUP_ROOT/$STAMP"

mkdir -p "$WORK_DIR"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

pg_dump \
    --format=custom \
    --no-owner \
    --no-acl \
    > "$WORK_DIR/paperless.dump"

tar -czf "$WORK_DIR/paperless-files.tar.gz" \
    -C /source data media export consume compose.yml .env

cat > "$WORK_DIR/manifest.txt" <<EOF
created_at=$STAMP
postgres_dump=paperless.dump
files_archive=paperless-files.tar.gz
retention_count=$RETENTION_COUNT
EOF

mv "$WORK_DIR" "$ARCHIVE_DIR"

backup_dirs=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort)
backup_count=$(printf '%s\n' "$backup_dirs" | awk 'NF { count++ } END { print count + 0 }')
while [ "$backup_count" -gt "$RETENTION_COUNT" ]; do
    oldest=$(printf '%s\n' "$backup_dirs" | awk 'NF { print; exit }')
    rm -rf "$oldest"
    backup_dirs=$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' | sort)
    backup_count=$(printf '%s\n' "$backup_dirs" | awk 'NF { count++ } END { print count + 0 }')
done

printf 'Backup created at %s\n' "$ARCHIVE_DIR"