-- AgileMetrix 1.2: upgrade an EXISTING 1.0 database to 1.2.
-- Adds only what is new in this release; existing data is kept. Safe to run more than once.
-- Back up first: pg_dump -Fc <database> > before-1.2.dump
-- Run: psql -v ON_ERROR_STOP=1 -h <host> -U <user> -d <database> -f upgrade.sql

BEGIN;

-- ===== schema/008_sprint_goal_and_added_by.sql =====
-- Sprint goal outcome (recorded by a person) and who added an issue to a sprint mid-way.

-- Issues tagged in Jira as part of the sprint goal (label "sprint-goal")
ALTER TABLE issues ADD COLUMN IF NOT EXISTS is_goal_item BOOLEAN NOT NULL DEFAULT false;

-- Who moved the issue into the sprint (Jira changelog author), or who created it inside the sprint
ALTER TABLE sprint_issues ADD COLUMN IF NOT EXISTS added_by VARCHAR(255);

-- Met / partly met / not met, as confirmed by a Scrum Master. Kept apart from synced data so a
-- Jira sync never overwrites it.
CREATE TABLE IF NOT EXISTS sprint_goal_outcomes (
  sprint_id   UUID PRIMARY KEY REFERENCES sprints(id) ON DELETE CASCADE,
  outcome     VARCHAR(20) NOT NULL CHECK (outcome IN ('met', 'partly_met', 'not_met')),
  note        VARCHAR(500),
  recorded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===== schema/009_app_settings.sql =====
-- Workspace-wide settings chosen by an administrator (e.g. date and time format), as key -> JSON value
CREATE TABLE IF NOT EXISTS app_settings (
  key        VARCHAR(100) PRIMARY KEY,
  value      JSONB NOT NULL,
  updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMIT;
