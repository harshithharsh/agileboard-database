-- AgileBoard schema (PostgreSQL 14+)
-- Sprint performance analytics: every dashboard metric is derived from
-- sprint_issues (commitment + outcome, added_at), issues (started/completed),
-- issue_status_history, blocked_periods and defects.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       VARCHAR(120) NOT NULL,
  email      VARCHAR(255) NOT NULL UNIQUE,
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
  name       VARCHAR(60) NOT NULL,              -- e.g. "S42"
  goal       TEXT,
  start_date DATE NOT NULL,
  end_date   DATE NOT NULL,
  status     VARCHAR(20) NOT NULL DEFAULT 'planned'
             CHECK (status IN ('planned', 'active', 'completed')),
  UNIQUE (team_id, name)
);

CREATE TABLE issues (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  issue_key    VARCHAR(20) NOT NULL UNIQUE,     -- e.g. "FIBI-101"
  title        VARCHAR(255) NOT NULL,
  type         VARCHAR(20) NOT NULL DEFAULT 'story'
               CHECK (type IN ('story', 'task', 'bug', 'spike')),
  story_points INT NOT NULL DEFAULT 0,
  assignee_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  status       VARCHAR(20) NOT NULL DEFAULT 'todo'
               CHECK (status IN ('todo', 'in_progress', 'in_review', 'in_test', 'done')),
  started_at   TIMESTAMPTZ,                     -- first move to in_progress
  completed_at TIMESTAMPTZ,                     -- move to done
  -- process compliance
  dor_met                 BOOLEAN NOT NULL DEFAULT false,  -- Definition of Ready
  dod_met                 BOOLEAN NOT NULL DEFAULT false,  -- Definition of Done
  has_acceptance_criteria BOOLEAN NOT NULL DEFAULT false,
  code_reviewed           BOOLEAN NOT NULL DEFAULT false,
  tests_complete          BOOLEAN NOT NULL DEFAULT false,
  automated               BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
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
