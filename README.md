# AgileBoard – Database

PostgreSQL schema and seed data for the AgileBoard sprint performance dashboard.

## Structure
- `schema/001_init.sql` – tables, applied in filename order
- `seeds/001_initial_data.sql` – generated starting data (do not edit by hand)
- `scripts/generate-seed.js` – regenerates the seed file (deterministic)
- `scripts/setup.sh` – drops/creates the database and applies schema + seeds

## Data model
| Table | Purpose |
|---|---|
| `projects`, `teams`, `team_members`, `users` | Who is doing the work: project **Fibi** (teams Nexo, Vertex) and project **AI** (team Nexus) |
| `releases`, `sprints` | Releases per project (Fibi R2.3/R2.4, AI R1.1/R1.2); sprints S37–S42 per team |
| `issues` | Stories, tasks, bugs, spikes, with start/complete times and compliance flags (DoR, DoD, acceptance criteria, code review, tests, automation) |
| `sprint_issues` | An issue's participation in a sprint: `committed` vs `added` (unplanned), and `completed` / `spillover` outcome |
| `issue_status_history` | Every status change, used for cycle time and WIP at sprint end |
| `blocked_periods` | When an issue was blocked, why, and whether it was an external dependency |
| `defects` | Defects raised per sprint and where they were found (`dev`, `qa`, `uat`, `prod`) |
| `metric_targets` | Targets shown on the dashboard (e.g. predictability ≥ 80%) |

Team names are real; the people in the seed data are demo users (`@example.com`).

## Setup
```bash
brew install postgresql@16 && brew services start postgresql@16
cp .env.example .env    # with Homebrew, DB_USER is your macOS username and DB_PASSWORD is empty
./scripts/setup.sh
```

Or with Docker: `docker compose up -d`

To change the starting data, edit `scripts/generate-seed.js`, then:
```bash
node scripts/generate-seed.js && ./scripts/setup.sh
```
