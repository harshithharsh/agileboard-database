# AgileBoard – Database

PostgreSQL schema and starting data for the AgileBoard sprint performance dashboard.
Sprints, issues, people, defects and blockers are loaded from Jira by the backend (`npm run sync` in `agileboard-backend`).

## Structure
- `schema/001_init.sql` – tables
- `schema/002_issue_priority.sql` – issue priority (for the P1 - Blocker card)
- `schema/003_admin.sql` – Admin: roles, user role/project assignment, project status
- `schema/004_subtasks.sql` – allows the `subtask` issue type (counted in Issues by Type, excluded from metrics)
- `schema/005_auth.sql` – sign-in: username / password hash on users, sessions
- `schema/006_user_preferences.sql` – per-user dashboard layout
- `schema/007_blocked_stage.sql` – workflow status and assignee when an issue got blocked
- `schema/008_sprint_goal_and_added_by.sql` – sprint goal outcome, goal-tagged issues, who added an issue mid-sprint
- `schema/009_app_settings.sql` – workspace settings (date and time format)
- `schema/010_team_member_source.sql` – team members from Jira or added by an admin; removed members stay out of later syncs
- `schema/011_scrum_master_role.sql` – adds the Scrum Master role (view, create, edit)
- `schema/012_redmine.sql` – Redmine: project links, people, imported time entries and import history
- `schema/013_resources.sql` – Resource Management: employment FTE, weekly hours and dated project allocations per person
- `schema/014_holidays.sql` – public holidays (Settings → General), left out of capacity
- `seeds/holidays_kerala_2026.sql` – Kerala public holidays for 2026 (optional; run once with psql, safe to repeat)

Schema files are applied in filename order. To add a new one to an existing database without losing synced data, run just that file, e.g. `psql -d agileboard -f schema/002_issue_priority.sql`, applied in filename order
- `seeds/001_initial_data.sql` – projects, teams with their Jira board ids, metric targets
- `scripts/setup.sh` – drops/creates the database and applies schema + seeds

## Data model
| Table | Purpose |
|---|---|
| `projects`, `teams`, `team_members`, `users` | Project **Fibi** (teams Nexo → Jira board 524, Vertex → board 12) and project **AI** (team Nexus → board 826). Users come from Jira assignees |
| `releases`, `sprints` | Releases (Jira fix versions) and sprints, matched to Jira by `jira_sprint_id` |
| `issues` | Stories, tasks, bugs, spikes, with start/complete times and compliance flags (DoR, DoD, acceptance criteria, code review, tests, automation) |
| `sprint_issues` | An issue's participation in a sprint: `committed` vs `added` (unplanned), and `completed` / `spillover` outcome |
| `issue_status_history` | Every status change, used for cycle time and WIP at sprint end |
| `blocked_periods` | When an issue was blocked, why, and whether it was an external dependency |
| `defects` | Defects raised per sprint and where they were found (`dev`, `qa`, `uat`, `prod`) |
| `metric_targets` | Targets shown on the dashboard (e.g. predictability ≥ 80%) |
| `sync_runs` | History of Jira syncs (the dashboard shows the last successful one) |

## Setup
```bash
brew install postgresql@16 && brew services start postgresql@16
cp .env.example .env    # with Homebrew, DB_USER is your macOS username and DB_PASSWORD is empty
./scripts/setup.sh
```

Or with Docker: `docker compose up -d`

To add a team, insert it into `teams` with its Jira board id and run the sync.

## Releases
Each release has a folder in `releases/<version>/`:
- `all.sql` — new installation on an empty database (all schema files and the starting data, one transaction)
- `upgrade.sql` — upgrade an existing database from the previous release (only the new schema files; safe to re-run)
- `RELEASE_NOTES.md` and `CONFIGURATION.md`

Build them with `./scripts/build-release-sql.sh <version> <previous> <new schema numbers…>`, e.g. `./scripts/build-release-sql.sh 1.1 1.0 008 009`.
