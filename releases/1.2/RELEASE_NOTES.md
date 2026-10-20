# AgileMetrix 1.2 — release notes

**Release date:** 20 Oct 2026 · **Previous release:** 1.0 (version 1.1 was not released) · **Branch:** `release/1.2` in all three repositories · **Tag:** `v1.2`

## What's new

- **Sprint goal outcome.** Record each finished sprint as *Met*, *Partly met* or *Not met* with a note. Issues labelled `sprint-goal` in Jira are listed under the goal and used to suggest the outcome. The widget shows the goal hit rate over recent sprints.
- **Who added work mid-sprint.** The Scope Change popup has summary tiles (issues added, story points added, committed at start, unplanned %), an *Added by* breakdown per person, and a cleaner table. The CSV includes *Added by*.
- **Jira sync progress bar.** Refresh shows the current sprint, *n of N sprints*, percent and elapsed time. Only one sync runs at a time; anyone opening the dashboard during a sync sees its progress.
- **Scheduled Jira sync with email.** An administrator can run the sync automatically every day (e.g. 10:00 PM IST) and email chosen people when it succeeds or fails.
- **Workspace Settings redesigned.** Tabs for General, Users, Roles and Projects. *General* holds the date and time format and the scheduled sync.
- **Date and time format.** Administrators choose the date format (18 Oct 2026, 18/10/2026, 10/18/2026, 2026-10-18) and 12- or 24-hour time for everyone.
- **Automatic sign-out.** Users are signed out after 6 hours without activity (configurable).

## Fixes

- Month names are consistent ("Sep", not "Sept").
- Older frontends that send calendar quarters no longer break the dashboard.

## Upgrade from 1.0

1. Back up the database: `pg_dump -Fc <database> > before-1.2.dump`
2. Database: run `releases/1.2/upgrade.sql` from the `agileboard-database` repository (adds schema 008 and 009; existing data is kept; safe to run twice).
3. Backend: deploy `release/1.2`, run `npm ci --omit=dev`, add the new settings from the [configuration sheet](CONFIGURATION.md) (email `SMTP_*`, `APP_URL`, `COOKIE_SECURE`), restart.
4. Frontend: build `release/1.2` with `VITE_API_URL` set, upload `dist/`.
5. Sign in as an administrator, click **Refresh** once, then set up **Workspace Settings → General → Scheduled Jira sync**.

**New installation:** run `releases/1.2/all.sql` on an empty database instead of step 2, then follow the deployment guide.

## Notes

- Email needs an SMTP server in the backend `.env`; until then the scheduled sync runs but sends no email.
- The scheduler runs inside the backend. With more than one backend server, set `SCHEDULER=off` on all but one (a run is never duplicated, but one scheduler is simpler).
- Teams that want the goal suggestion add the `sprint-goal` label to goal issues during sprint planning.
