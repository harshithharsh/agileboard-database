-- AgileBoard initial schema (PostgreSQL 14+)

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT,
  role          VARCHAR(20)  NOT NULL DEFAULT 'member'
                CHECK (role IN ('admin', 'member', 'viewer')),
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         VARCHAR(10)  NOT NULL UNIQUE,          -- e.g. "AB"
  name        VARCHAR(120) NOT NULL,
  description TEXT,
  owner_id    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE project_members (
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES users(id)    ON DELETE CASCADE,
  PRIMARY KEY (project_id, user_id)
);

CREATE TABLE sprints (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name        VARCHAR(120) NOT NULL,
  goal        TEXT,
  start_date  DATE,
  end_date    DATE,
  status      VARCHAR(20) NOT NULL DEFAULT 'planned'
              CHECK (status IN ('planned', 'active', 'completed')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Board columns per project (To Do, In Progress, ...)
CREATE TABLE board_columns (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name        VARCHAR(60) NOT NULL,
  position    INT NOT NULL,
  UNIQUE (project_id, position)
);

CREATE TABLE issues (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  sprint_id    UUID REFERENCES sprints(id) ON DELETE SET NULL,   -- NULL = backlog
  column_id    UUID REFERENCES board_columns(id) ON DELETE SET NULL,
  number       INT  NOT NULL,                                    -- AB-1, AB-2 ...
  title        VARCHAR(255) NOT NULL,
  description  TEXT,
  type         VARCHAR(20) NOT NULL DEFAULT 'task'
               CHECK (type IN ('story', 'task', 'bug', 'epic')),
  priority     VARCHAR(20) NOT NULL DEFAULT 'medium'
               CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  story_points INT,
  assignee_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  reporter_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  position     INT NOT NULL DEFAULT 0,                           -- order inside a column
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (project_id, number)
);

CREATE TABLE comments (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_id   UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
  author_id  UUID REFERENCES users(id) ON DELETE SET NULL,
  body       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_issues_project ON issues(project_id);
CREATE INDEX idx_issues_sprint  ON issues(sprint_id);
CREATE INDEX idx_issues_column  ON issues(column_id);
CREATE INDEX idx_comments_issue ON comments(issue_id);
