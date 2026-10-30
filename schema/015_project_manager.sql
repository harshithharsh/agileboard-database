-- Project Manager role, and the project manager of each project (one of the users with that role)
INSERT INTO roles (name, description, permissions) VALUES
  ('Project Manager', 'Manages projects: plans resources and tracks delivery', ARRAY['view','create','edit'])
ON CONFLICT (name) DO NOTHING;

ALTER TABLE projects ADD COLUMN IF NOT EXISTS manager_id UUID REFERENCES users(id) ON DELETE SET NULL;
