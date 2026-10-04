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
PAPERLESS_DBPASS=change-this-password
PAPERLESS_SECRET_KEY=generate-a-long-random-secret

CACHE_DIR=./cache
DB_DIR=./db
BACKUP_DIR=./backup
DATA_DIR=./data
MEDIA_DIR=./media
EXPORT_DIR=./export
CONSUME_DIR=./consume
SCRIPTS_DIR=./scripts

BACKUP_SCHEDULE=15 3 * * *
TZ=Europe/Berlin
```

`POSTGRES_PASSWORD` and `PAPERLESS_DBPASS` must match. The path variables can be changed to store data outside the repository directory. `BACKUP_SCHEDULE` uses cron syntax; the default runs daily at 03:15 in `Europe/Berlin`.

## Start the Stack

On Unraid, deploy and manage the stack with Docker Compose Manager. On other
Docker Compose installations, pull the images and start all services:

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

The `backup` service creates a PostgreSQL dump once a day at 03:15 in `Europe/Berlin`. It keeps daily dumps for 30 days, one dump per month for the previous 12 completed months, and one dump per year for the two years before that. File-backed Paperless data is not included.

On Unraid, deploy the stack with Compose Manager; the scheduled backup service starts with the stack and does not require Compose commands in the Unraid shell. To run a dump immediately, open the backup container's console and run:

```sh
sh /scripts/postgres-backup.sh
```

See [BACKUP.md](BACKUP.md) for retention, restore steps, and guidance for including Paperless files in a later Duplicati backup.

## Services

| Service | Purpose |
| --- | --- |
| `webserver` | Paperless-ngx web application and document processing |
| `db` | PostgreSQL database |
| `broker` | Valkey message broker |
| `gotenberg` | Office and document conversion |
| `tika` | Document text and metadata extraction |
| `backup` | Scheduled PostgreSQL dumps |

## Updating

Pull updated images and recreate the services:

```sh
docker compose pull
docker compose up -d
```

Review the Paperless-ngx release notes before applying major version upgrades, and create a backup first.
