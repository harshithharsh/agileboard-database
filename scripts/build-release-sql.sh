#!/usr/bin/env bash
# Builds the SQL files for a release into releases/<version>/:
#   all.sql      - new installation: every schema file (001...) plus the starting data, in one transaction
#   upgrade.sql  - existing installation: only the schema files added since <from-version> (safe to re-run)
# Usage: ./scripts/build-release-sql.sh 1.2 1.0 008 009
#        (version, previous version, then the schema numbers new in this release)
set -euo pipefail
cd "$(dirname "$0")/.."
version=$1; from=$2; shift 2
out="releases/$version"
mkdir -p "$out"

strip_tx() { grep -v -E '^(BEGIN|COMMIT);[[:space:]]*$' "$1"; }

{
  echo "-- AgileMetrix $version: full database for a NEW installation (empty database)."
  echo "-- Creates every table and loads the starting data (projects, teams, metric targets)."
  echo "-- Run: psql -v ON_ERROR_STOP=1 -h <host> -U <user> -d <database> -f all.sql"
  echo "-- Do NOT run this on a database that already has AgileMetrix data: use upgrade.sql instead."
  echo
  echo "BEGIN;"
  for f in schema/*.sql seeds/*.sql; do
    echo; echo "-- ===== $f ====="; strip_tx "$f"
  done
  echo; echo "COMMIT;"
} > "$out/all.sql"

{
  echo "-- AgileMetrix $version: upgrade an EXISTING $from database to $version."
  echo "-- Adds only what is new in this release; existing data is kept. Safe to run more than once."
  echo "-- Back up first: pg_dump -Fc <database> > before-$version.dump"
  echo "-- Run: psql -v ON_ERROR_STOP=1 -h <host> -U <user> -d <database> -f upgrade.sql"
  echo
  echo "BEGIN;"
  for n in "$@"; do
    f=$(ls schema/${n}_*.sql)
    echo; echo "-- ===== $f ====="; strip_tx "$f"
  done
  echo; echo "COMMIT;"
} > "$out/upgrade.sql"

echo "Wrote $out/all.sql and $out/upgrade.sql"
