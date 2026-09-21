# Paperless-ngx

A Docker Compose deployment of [Paperless-ngx](https://docs.paperless-ngx.com/) with PostgreSQL, Valkey, Apache Tika, Gotenberg, and scheduled backups.

## Requirements

- Docker Desktop or Docker Engine with the Compose plugin
- Enough storage for the database, documents, thumbnails, and backups

## Configuration

Create a `.env` file in the project root. Keep it private because it contains passwords and the Paperless secret key.

```dotenv
POSTGRES_USER=paperless
POSTGRES_PASSWORD=change-this-password
POSTGRES_VERSION=18
PGPASSWORD=change-this-password
PAPERLESS_DBPASS=change-this-password
PAPERLESS_SECRET_KEY=generate-a-long-random-secret

CACHE_DIR=./cache
DB_DIR=./db
BACKUP_DIR=./backup
DATA_DIR=./data
MEDIA_DIR=./media
EXPORT_DIR=./export
CONSUME_DIR=./consume
```

`POSTGRES_PASSWORD`, `PGPASSWORD`, and `PAPERLESS_DBPASS` must match. The path variables can be changed to store data outside the repository directory.

## Start the Stack

Pull the images and start all services:

```sh
docker compose pull
docker compose up -d
```

Paperless-ngx is available at <http://localhost:8000>.

Check service status and logs with:

```sh
docker compose ps
docker compose logs -f webserver
```

Stop the stack without deleting data:

```sh
docker compose down
```

## Document Workflow

- Place documents to be imported in the `CONSUME_DIR` directory.
- Processed documents and application data are stored in `MEDIA_DIR` and `DATA_DIR`.
- Exports are written to `EXPORT_DIR`.

The default filename format is:

```text
{document_type}/{created_year}/{correspondent}/{title}
```

## Backups

The `backup` service creates a PostgreSQL dump and archives the Paperless file-backed state once a week on Sunday at 03:15 in `Europe/Berlin`. It retains 52 backup sets.

Start the backup service with:

```sh
docker compose up -d backup
```

Run a backup immediately:

```sh
docker compose exec backup /usr/local/bin/paperless-container-backup
```

A host-side backup script is also available:

```sh
./scripts/paperless-backup.sh
```

Backups include `.env`, so protect backup storage appropriately. See [BACKUP.md](BACKUP.md) for retention and disaster-recovery guidance.

## Services

| Service | Purpose |
| --- | --- |
| `webserver` | Paperless-ngx web application and document processing |
| `db` | PostgreSQL database |
| `broker` | Valkey message broker |
| `gotenberg` | Office and document conversion |
| `tika` | Document text and metadata extraction |
| `backup` | Scheduled PostgreSQL and file-backed backups |

## Updating

Pull updated images and recreate the services:

```sh
docker compose pull
docker compose up -d
```

Review the Paperless-ngx release notes before applying major version upgrades, and create a backup first.
