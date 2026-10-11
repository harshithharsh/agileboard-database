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
