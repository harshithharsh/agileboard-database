#!/bin/bash
# Postgres image only runs top-level files; apply schema then seeds from subfolders.
set -e
for f in /docker-entrypoint-initdb.d/1-schema/*.sql /docker-entrypoint-initdb.d/2-seeds/*.sql; do
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$f"
done
