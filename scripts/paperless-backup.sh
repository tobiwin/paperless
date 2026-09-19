#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BACKUP_ROOT=${BACKUP_ROOT:-"$PROJECT_DIR/backup"}
RETENTION_DAYS=${RETENTION_DAYS:-30}
STAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
WORK_DIR="$BACKUP_ROOT/.working-$STAMP-$$"
ARCHIVE_DIR="$BACKUP_ROOT/$STAMP"

mkdir -p "$BACKUP_ROOT"
cleanup() {
    rm -rf "$WORK_DIR"
}
mkdir -p "$WORK_DIR"

cd "$PROJECT_DIR"
WAS_RUNNING=0
if [ -n "$(docker compose ps -q --status running webserver)" ]; then
    WAS_RUNNING=1
    docker compose stop webserver
fi
on_exit() {
    cleanup
    if [ "$WAS_RUNNING" -eq 1 ]; then
        docker compose start webserver
    fi
}
trap on_exit EXIT INT TERM

docker compose up -d db
docker compose exec -T db pg_dump \
    --format=custom \
    --no-owner \
    --no-acl \
    --username=paperless \
    --dbname=paperless \
    > "$WORK_DIR/paperless.dump"

tar -czf "$WORK_DIR/paperless-files.tar.gz" \
    data media export consume compose.yml

cat > "$WORK_DIR/manifest.txt" <<EOF
created_at=$STAMP
postgres_dump=paperless.dump
files_archive=paperless-files.tar.gz
retention_days=$RETENTION_DAYS
EOF

mv "$WORK_DIR" "$ARCHIVE_DIR"
find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -name '20*' \
    -mtime "+$RETENTION_DAYS" -exec rm -rf {} +

printf 'Backup created at %s\n' "$ARCHIVE_DIR"