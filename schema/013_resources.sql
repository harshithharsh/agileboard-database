-- Resource Management: each person's capacity (employment FTE, optional weekly hours, team for
-- resource reports) and their dated project allocations. People are AgileMetrix users.

CREATE TABLE IF NOT EXISTS resource_profiles (
  user_id        UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  employment_fte NUMERIC(4,2) CHECK (employment_fte >= 0 AND employment_fte <= 1.5),
  weekly_hours   NUMERIC(5,2) CHECK (weekly_hours > 0 AND weekly_hours <= 80),
  team_id        UUID REFERENCES teams(id) ON DELETE SET NULL, -- overrides the Jira team in Resource Management
  updated_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A change ends the old allocation the day before and starts a new one, so history is kept
CREATE TABLE IF NOT EXISTS resource_allocations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  fte         NUMERIC(4,2) NOT NULL CHECK (fte > 0 AND fte <= 1.5),
  start_date  DATE NOT NULL,
  end_date    DATE CHECK (end_date IS NULL OR end_date >= start_date),
  modified_by VARCHAR(120),
  modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_resource_allocations_user ON resource_allocations (user_id);
