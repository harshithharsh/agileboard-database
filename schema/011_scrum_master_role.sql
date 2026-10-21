-- Scrum Master: runs the sprints, records sprint goal outcomes; no delete or admin rights
INSERT INTO roles (name, description, permissions) VALUES
  ('Scrum Master', 'Run sprints and record sprint goal outcomes', ARRAY['view','create','edit'])
ON CONFLICT (name) DO NOTHING;
