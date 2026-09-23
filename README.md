# AgileBoard – Database

PostgreSQL schema and seed data for AgileBoard.

## Structure
- `schema/` – DDL, applied in filename order (`001_init.sql`, `002_...`)
- `seeds/`  – initial data (demo users, project, board columns, sprint, issues)
- `scripts/setup.sh` – drops/creates the DB and applies schema + seeds

## Tables
`users`, `projects`, `project_members`, `sprints`, `board_columns`, `issues`, `comments`

## Setup
```bash
brew install postgresql@16 && brew services start postgresql@16
cp .env.example .env    # edit credentials
./scripts/setup.sh
```

Or with Docker:
```bash
docker compose up -d
```
