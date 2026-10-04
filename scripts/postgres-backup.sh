#!/bin/sh
set -eu

BACKUP_ROOT=${BACKUP_ROOT:-/backup}
STAMP=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_ROOT/paperless-$STAMP.dump"
TEMP_FILE="$BACKUP_FILE.tmp-$$"
KEEP_FILE="$BACKUP_ROOT/.paperless-keep-$$"

cleanup() {
    rm -f "$TEMP_FILE" "$KEEP_FILE"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$BACKUP_ROOT"
printf 'Starting PostgreSQL dump: %s\n' "$BACKUP_FILE"
if ! pg_dump \
    --format=custom \
    --no-owner \
    --no-acl \
    --file="$TEMP_FILE"; then
    printf 'ERROR: pg_dump failed; no backup was installed.\n' >&2
    exit 1
fi
if [ ! -s "$TEMP_FILE" ]; then
    printf 'ERROR: pg_dump produced an empty file; no backup was installed.\n' >&2
    exit 1
fi
if ! mv -f "$TEMP_FILE" "$BACKUP_FILE"; then
    printf 'ERROR: could not move the dump into %s.\n' "$BACKUP_ROOT" >&2
    exit 1
fi

DAILY_CUTOFF=$(date -d '29 days ago' +%Y-%m-%d)
MONTH_START=$(date -d "$(date +%Y-%m-01) -12 months" +%Y-%m)
: > "$KEEP_FILE"

is_backup_file() {
    backup_date=${1##*/paperless-}
    backup_date=${backup_date%.dump}
    case "$backup_date" in
        ????-??-??) ;;
        *) return 1 ;;
    esac
    normalized_date=$(date -d "$backup_date" +%Y-%m-%d 2>/dev/null) || return 1
    [ "$normalized_date" = "$backup_date" ]
}

for candidate in "$BACKUP_ROOT"/paperless-????-??-??.dump; do
    [ -f "$candidate" ] || continue
    is_backup_file "$candidate" || continue
    backup_date=${candidate##*/paperless-}
    backup_date=${backup_date%.dump}
    if [ "$backup_date" \> "$DAILY_CUTOFF" ] || [ "$backup_date" = "$DAILY_CUTOFF" ]; then
        printf '%s\n' "$candidate" >> "$KEEP_FILE"
    fi
done

keep_latest_for_prefix() {
    prefix=$1
    latest=
    for candidate in "$BACKUP_ROOT"/paperless-"$prefix"*.dump; do
        [ -f "$candidate" ] || continue
        is_backup_file "$candidate" || continue
        if [ -z "$latest" ] || [ "$candidate" \> "$latest" ]; then
            latest=$candidate
        fi
    done
    if [ -n "$latest" ]; then
        printf '%s\n' "$latest" >> "$KEEP_FILE"
    fi
}

month=1
while [ "$month" -le 12 ]; do
    target_month=$(date -d "$(date +%Y-%m-01) -$month months" +%Y-%m)
    keep_latest_for_prefix "$target_month"
    month=$((month + 1))
done

year=1
while [ "$year" -le 2 ]; do
    target_year=$(date -d "$MONTH_START-01 -$year years" +%Y)
    keep_latest_for_prefix "$target_year"
    year=$((year + 1))
done

for candidate in "$BACKUP_ROOT"/paperless-????-??-??.dump; do
    [ -f "$candidate" ] || continue
    is_backup_file "$candidate" || continue
    if ! grep -F -x -q "$candidate" "$KEEP_FILE"; then
        rm -f "$candidate"
    fi
done

printf 'PostgreSQL backup complete: %s\n' "$BACKUP_FILE"
