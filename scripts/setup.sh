#!/usr/bin/env bash
# Creates the database, applies the schema and loads seed data.
# Usage: ./scripts/setup.sh   (reads DB_* variables from .env if present)
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-postgres}
DB_NAME=${DB_NAME:-agileboard}
export PGPASSWORD=${DB_PASSWORD:-}

PSQL="psql -v ON_ERROR_STOP=1 -h $DB_HOST -p $DB_PORT -U $DB_USER"

echo "Recreating database $DB_NAME..."
$PSQL -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
$PSQL -d postgres -c "CREATE DATABASE $DB_NAME;"

for f in schema/*.sql; do echo "Applying $f"; $PSQL -d "$DB_NAME" -f "$f"; done
for f in seeds/*.sql;  do echo "Seeding  $f"; $PSQL -d "$DB_NAME" -f "$f"; done
echo "Done."
