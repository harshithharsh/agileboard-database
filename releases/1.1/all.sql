-- AgileMetrix 1.1: full database for a NEW installation (empty database).
-- Creates every table and loads the starting data (projects, teams, metric targets).
-- Run: psql -v ON_ERROR_STOP=1 -h <host> -U <user> -d <database> -f all.sql
-- Do NOT run this on a database that already has AgileMetrix data: use upgrade.sql instead.

BEGIN;

-- ===== schema/001_init.sql =====
-- AgileBoard schema (PostgreSQL 14+)
-- Sprint performance analytics. Data is synced from Jira by the backend
-- (agileboard-backend: npm run sync). Every dashboard metric is derived from
-- sprint_issues (commitment + outcome, added_at), issues (started/completed),
-- issue_status_history, blocked_periods and defects.
-- jira_* columns hold the Jira ids used to match records on each sync.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(120) NOT NULL,
  email      VARCHAR(255) UNIQUE,                 -- Jira often hides emails
  jira_account_id VARCHAR(128) UNIQUE,
  role       VARCHAR(20)  NOT NULL DEFAULT 'member'
             CHECK (role IN ('admin', 'scrum_master', 'member', 'viewer')),
  created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         VARCHAR(10)  NOT NULL UNIQUE,
  name        VARCHAR(120) NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE teams (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name       VARCHAR(120) NOT NULL,
  wip_limit  INT NOT NULL DEFAULT 5,
  jira_board_id INT UNIQUE,                        -- the team's Jira board
  UNIQUE (project_id, name)
);

CREATE TABLE team_members (
  team_id UUID REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (team_id, user_id)
);

CREATE TABLE releases (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name        VARCHAR(60) NOT NULL,
  target_date DATE,
  UNIQUE (project_id, name)
);

CREATE TABLE sprints (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id    UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  release_id UUID REFERENCES releases(id) ON DELETE SET NULL,
  name       VARCHAR(120) NOT NULL,             -- e.g. "Nexus Sprint 2"
  goal       TEXT,
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  started_at   TIMESTAMPTZ,                     -- exact Jira start time
  completed_at TIMESTAMPTZ,                     -- when the sprint was closed in Jira
  status     VARCHAR(20) NOT NULL DEFAULT 'planned'
             CHECK (status IN ('planned', 'active', 'completed')),
  jira_sprint_id INT UNIQUE
);

CREATE TABLE issues (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  issue_key    VARCHAR(30) NOT NULL UNIQUE,     -- e.g. "FIBI-101"
  title        VARCHAR(255) NOT NULL,
  type         VARCHAR(20) NOT NULL DEFAULT 'story'
               CHECK (type IN ('story', 'task', 'bug', 'spike')),
  story_points INT NOT NULL DEFAULT 0,
  assignee_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  status       VARCHAR(20) NOT NULL DEFAULT 'todo'
               CHECK (status IN ('todo', 'in_progress', 'in_review', 'in_test', 'done')),
  jira_status  VARCHAR(60),                     -- status name as shown in Jira
  started_at   TIMESTAMPTZ,                     -- first move to in_progress
  completed_at TIMESTAMPTZ,                     -- move to done
  -- process compliance; NULL = not tracked
  dor_met                 BOOLEAN,         -- Definition of Ready
  dod_met                 BOOLEAN,         -- Definition of Done
  has_acceptance_criteria BOOLEAN,
  code_reviewed           BOOLEAN,
  tests_complete          BOOLEAN,
  automated               BOOLEAN,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  jira_issue_id VARCHAR(30) UNIQUE
);

-- An issue's participation in a sprint. The same issue can appear in two
-- sprints when it spills over.
CREATE TABLE sprint_issues (
  sprint_id  UUID NOT NULL REFERENCES sprints(id) ON DELETE CASCADE,
  issue_id   UUID NOT NULL REFERENCES issues(id)  ON DELETE CASCADE,
  commitment VARCHAR(20) NOT NULL CHECK (commitment IN ('committed', 'added')),
  outcome    VARCHAR(20) CHECK (outcome IN ('completed', 'spillover', 'removed')),  -- NULL while sprint active
  points     INT NOT NULL,                     -- points at the time it entered the sprint
  added_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (sprint_id, issue_id)
);

CREATE TABLE issue_status_history (
  id          BIGSERIAL PRIMARY KEY,
  issue_id    UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  from_status VARCHAR(20),
  to_status   VARCHAR(20) NOT NULL,
  changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE blocked_periods (
  id         BIGSERIAL PRIMARY KEY,
  issue_id   UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  reason     TEXT,
  external   BOOLEAN NOT NULL DEFAULT false,   -- external dependency
  started_at TIMESTAMPTZ NOT NULL,
  ended_at   TIMESTAMPTZ                        -- NULL = still blocked
);

CREATE TABLE defects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  sprint_id   UUID REFERENCES sprints(id) ON DELETE SET NULL,   -- sprint in which it was raised
  issue_id    UUID REFERENCES issues(id)  ON DELETE SET NULL,   -- story it relates to
  title       VARCHAR(255) NOT NULL,
  severity    VARCHAR(20) NOT NULL DEFAULT 'medium'
              CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  found_in    VARCHAR(10) NOT NULL CHECK (found_in IN ('dev', 'qa', 'uat', 'prod')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at   TIMESTAMPTZ
);

-- One row per Jira sync run; the dashboard shows the last successful one.
CREATE TABLE sync_runs (
  id          BIGSERIAL PRIMARY KEY,
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status      VARCHAR(20) NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'success', 'failed')),
  message     TEXT
);

-- Targets shown on the dashboard ("Target ≥ 80%").
CREATE TABLE metric_targets (
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  metric     VARCHAR(40) NOT NULL,
  operator   VARCHAR(2)  NOT NULL CHECK (operator IN ('>=', '<=')),
  value      NUMERIC     NOT NULL,
  PRIMARY KEY (project_id, metric)
);

CREATE INDEX idx_sprints_team            ON sprints(team_id);
CREATE INDEX idx_issues_assignee         ON issues(assignee_id);
CREATE INDEX idx_sprint_issues_issue     ON sprint_issues(issue_id);
CREATE INDEX idx_status_history_issue    ON issue_status_history(issue_id, changed_at);
CREATE INDEX idx_blocked_periods_issue   ON blocked_periods(issue_id);
CREATE INDEX idx_defects_sprint          ON defects(sprint_id);

-- ===== schema/002_issue_priority.sql =====
-- Jira priority of each issue (e.g. "P1 - Blocker"), used for the P1 - Blocker summary card.
ALTER TABLE issues ADD COLUMN IF NOT EXISTS priority VARCHAR(60);

-- ===== schema/003_admin.sql =====
-- Admin: roles, user role/project assignment, project status.

CREATE TABLE IF NOT EXISTS roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(60) NOT NULL UNIQUE,
  description TEXT,
  -- subset of: view, create, edit, delete, admin
  permissions TEXT[] NOT NULL DEFAULT ARRAY['view'],
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO roles (name, description, permissions) VALUES
  ('Administrator',    'Full access to the system',        ARRAY['view','create','edit','delete','admin']),
  ('Product Owner',    'Manage backlog and releases',      ARRAY['view','create','edit']),
  ('Developer',        'Work on sprint items',             ARRAY['view','edit']),
  ('QA',               'Testing and defect management',    ARRAY['view','edit']),
  ('Business Analyst', 'Requirements and analysis',        ARRAY['view','create','edit']),
  ('Viewer',           'Read-only access',                 ARRAY['view'])
ON CONFLICT (name) DO NOTHING;

ALTER TABLE users ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES roles(id) ON DELETE SET NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(10) NOT NULL DEFAULT 'active'
  CHECK (status IN ('active', 'inactive'));

CREATE TABLE IF NOT EXISTS user_projects (
  user_id    UUID REFERENCES users(id)    ON DELETE CASCADE,
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, project_id)
);

ALTER TABLE projects ADD COLUMN IF NOT EXISTS status VARCHAR(10) NOT NULL DEFAULT 'active'
  CHECK (status IN ('active', 'inactive'));

-- Existing people synced from Jira start as Viewers on the projects they work on
UPDATE users SET role_id = (SELECT id FROM roles WHERE name = 'Viewer') WHERE role_id IS NULL;
INSERT INTO user_projects (user_id, project_id)
SELECT DISTINCT tm.user_id, t.project_id FROM team_members tm JOIN teams t ON t.id = tm.team_id
ON CONFLICT DO NOTHING;

-- ===== schema/004_subtasks.sql =====
-- Sub-tasks are synced so the dashboard can count them (Issues by Type); they are excluded from
-- velocity, completion and the other sprint metrics.
ALTER TABLE issues DROP CONSTRAINT IF EXISTS issues_type_check;
ALTER TABLE issues ADD CONSTRAINT issues_type_check CHECK (type IN ('story', 'task', 'bug', 'spike', 'subtask'));

-- ===== schema/005_auth.sql =====
-- Sign-in: usernames/passwords on users, and server-side sessions.
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(60);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;          -- scrypt hash (salt included); NULL = cannot sign in
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
CREATE UNIQUE INDEX IF NOT EXISTS users_username_lower ON users (lower(username));

-- A session is identified by a random token kept in an HttpOnly cookie; only its SHA-256 hash is stored.
CREATE TABLE IF NOT EXISTS sessions (
  token_hash  CHAR(64) PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at  TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS sessions_user ON sessions (user_id);

-- ===== schema/006_user_preferences.sql =====
-- Per-user preferences, e.g. the dashboard layout (widget order, size and visibility)
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id          UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  dashboard_layout JSONB,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ===== schema/007_blocked_stage.sql =====
-- Where a blocked issue was in the workflow when it got blocked, and who had it,
-- so the dashboard can show whether a blocker sits with development, QA or BA
ALTER TABLE blocked_periods ADD COLUMN IF NOT EXISTS blocked_in_status VARCHAR(100);
ALTER TABLE blocked_periods ADD COLUMN IF NOT EXISTS blocked_assignee VARCHAR(255);

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

-- ===== seeds/001_initial_data.sql =====
-- AgileBoard starting data: projects, teams and their Jira boards, metric targets.
-- Sprints, issues, users, defects and blockers are loaded from Jira by the
-- backend sync (cd agileboard-backend && npm run sync).


INSERT INTO projects (id, key, name, description) VALUES
  ('00000000-0000-4000-8000-000000000001', 'FIBI', 'Fibi', 'Jira project FIBI'),
  ('00000000-0000-4000-8000-000000000002', 'AI',   'AI',   'Jira project AI');

INSERT INTO teams (project_id, name, jira_board_id) VALUES
  ('00000000-0000-4000-8000-000000000001', 'Nexo',   524),
  ('00000000-0000-4000-8000-000000000001', 'Vertex', 12),
  ('00000000-0000-4000-8000-000000000002', 'Nexus',  826);

INSERT INTO metric_targets (project_id, metric, operator, value)
SELECT p.id, t.metric, t.operator, t.value
FROM projects p
CROSS JOIN (VALUES
  ('predictability', '>=', 80),
  ('spillover',      '<=', 10),
  ('unplanned',      '<=', 10),
  ('blocked_items',  '<=', 3),
  ('dod_compliance', '>=', 100)
) AS t(metric, operator, value);


COMMIT;
