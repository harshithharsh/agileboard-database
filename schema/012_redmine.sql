-- Redmine: which Redmine project feeds each Jira project, the people found in its time entries
-- (matched to AgileMetrix users), the imported time entries, and the import history.

-- One Redmine project (optionally with its sub-projects) per AgileMetrix project
CREATE TABLE IF NOT EXISTS redmine_project_links (
  project_id           UUID PRIMARY KEY REFERENCES projects(id) ON DELETE CASCADE,
  redmine_project_id   INTEGER NOT NULL UNIQUE,
  redmine_project_name VARCHAR(255) NOT NULL,
  include_subprojects  BOOLEAN NOT NULL DEFAULT true,
  linked_by            UUID REFERENCES users(id) ON DELETE SET NULL,
  linked_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Redmine people seen in time entries. user_id = the AgileMetrix user they are;
-- match = 'auto' (same name) or 'manual' (chosen in Settings); ignored = not a person to track (e.g. a bot)
CREATE TABLE IF NOT EXISTS redmine_users (
  id         INTEGER PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  user_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  match      VARCHAR(10) CHECK (match IN ('auto', 'manual')),
  ignored    BOOLEAN NOT NULL DEFAULT false,
  first_seen TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Time entries of linked projects (comments are not imported)
CREATE TABLE IF NOT EXISTS redmine_time_entries (
  id                   INTEGER PRIMARY KEY,
  project_id           UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  redmine_project_id   INTEGER NOT NULL,
  redmine_project_name VARCHAR(255),
  redmine_user_id      INTEGER NOT NULL,
  spent_on             DATE NOT NULL,
  hours                NUMERIC(7,2) NOT NULL,
  activity             VARCHAR(100),
  redmine_issue_id     INTEGER,
  jira_key             VARCHAR(30),
  updated_on           TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_rte_project_day ON redmine_time_entries (project_id, spent_on);
CREATE INDEX IF NOT EXISTS idx_rte_user_day ON redmine_time_entries (redmine_user_id, spent_on);

CREATE TABLE IF NOT EXISTS redmine_sync_runs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status      VARCHAR(10) NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'success', 'partial', 'failed')),
  trigger     VARCHAR(10) NOT NULL DEFAULT 'manual' CHECK (trigger IN ('manual', 'scheduled')),
  started_by  UUID REFERENCES users(id) ON DELETE SET NULL,
  projects    INTEGER,
  entries     INTEGER,
  users       INTEGER,
  message     TEXT
);
