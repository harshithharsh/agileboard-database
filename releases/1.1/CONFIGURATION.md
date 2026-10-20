# AgileMetrix 1.1 — configuration sheet

Fill in the **Value** column for your environment. Secrets (marked 🔒) go only in the server's `.env` or secrets manager — never in Git, email or chat.

## 1. Backend (`agileboard-backend/.env`)

| Setting | Required | Example | Value | What it does |
|---|---|---|---|---|
| `PORT` | yes | `4000` | | Port the API listens on (the proxy forwards to it) |
| `DB_HOST` | yes | `db.internal` | | PostgreSQL host |
| `DB_PORT` | yes | `5432` | | PostgreSQL port |
| `DB_NAME` | yes | `agilemetrix` | | Database name |
| `DB_USER` | yes | `agilemetrix` | | Database user |
| `DB_PASSWORD` 🔒 | yes | | | Database password |
| `CORS_ORIGIN` | yes | `https://agilemetrix.example.com` | | Exact frontend address (no trailing slash) |
| `COOKIE_SECURE` | yes (production) | `true` | | `true` when served over HTTPS |
| `SESSION_IDLE_HOURS` | no | `6` | | Sign users out after this many idle hours (default 6) |
| `JIRA_BASE_URL` | yes | `https://polussolutions.atlassian.net` | | Jira Cloud site |
| `JIRA_EMAIL` | yes | `svc-agilemetrix@polussolutions.com` | | Atlassian account used to read Jira (read-only use) |
| `JIRA_API_TOKEN` 🔒 | yes | | | API token of that account |
| `JIRA_TIMEZONE` | no | `Asia/Kolkata` | | Time zone for sprint dates (default: the Jira account's) |
| `JIRA_SYNC_SINCE` | no | `2026-01-01` | | Sync every sprint that started on/after this date (default: 1 April this financial year) |
| `JIRA_SYNC_CLOSED_SPRINTS` | no | `6` | | Always keep at least this many closed sprints per board |
| `JIRA_SPRINT_FIELD` | no | `customfield_10021` | | Jira Sprint field id (auto-detected if empty) |
| `JIRA_STORY_POINTS_FIELD` | no | `customfield_10026` | | Story points field id (auto-detected if empty) |
| `SPRINT_GOAL_LABEL` | no | `sprint-goal` | | Jira label that marks sprint-goal issues |
| `SMTP_HOST` | for email | `smtp.office365.com` | | Mail server (`log` = write emails to the log, for testing) |
| `SMTP_PORT` | for email | `587` | | `587` (STARTTLS) or `465` (SSL) |
| `SMTP_SECURE` | for email | `false` | | `true` only for port 465 |
| `SMTP_USER` | for email | `agilemetrix@polussolutions.com` | | Sending mailbox |
| `SMTP_PASS` 🔒 | for email | | | Its password or app password |
| `SMTP_FROM` | for email | `agilemetrix@polussolutions.com` | | From address on emails |
| `APP_URL` | recommended | `https://agilemetrix.example.com` | | Dashboard link included in emails |
| `SCHEDULER` | no | `off` | | `off` disables the scheduled sync on this server |

## 2. Frontend (build time)

| Setting | Required | Example | Value | What it does |
|---|---|---|---|---|
| `VITE_API_URL` | yes | `https://api.agilemetrix.example.com` | | API address baked into the build (`.env.production`) |

## 3. Infrastructure

| Item | Requirement | Value |
|---|---|---|
| Node.js | 20 or newer, long-running process (pm2, systemd or container) | |
| PostgreSQL | 16 (14+ works) | |
| Hostnames | Frontend and API on HTTPS, same parent domain | |
| Outbound | HTTPS to `polussolutions.atlassian.net`; SMTP port to the mail server | |
| Proxy / CDN | Forward `/api/*` with cookies, no caching, read timeout ≥ 60 s | |
| Backups | Daily `pg_dump`, keep ≥ 7 days | |

## 4. In the app (Workspace Settings, administrator)

| Setting | Where | Default | Value |
|---|---|---|---|
| Date format | General → Date and time | 18 Oct 2026 | |
| Time format | General → Date and time | 12-hour | |
| Scheduled Jira sync | General → Scheduled Jira sync | Off | |
| Sync time and time zone | General → Scheduled Jira sync | 22:00, Asia/Kolkata | |
| Email on success / failure | General → Scheduled Jira sync | On / On | |
| Email recipients | General → Scheduled Jira sync | none | |
| Projects, teams, Jira boards | Projects | Fibi (Nexo, Vertex), AI (Nexus) | |
| Users, sign-in, roles | Users, Roles | — | |
| First administrator | Server: `npm run create-admin` | — | |
