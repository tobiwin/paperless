#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$PROJECT_DIR"
exec docker compose run --rm --entrypoint /usr/local/bin/paperless-container-backup backup