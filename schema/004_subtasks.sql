-- Sub-tasks are synced so the dashboard can count them (Issues by Type); they are excluded from
-- velocity, completion and the other sprint metrics.
ALTER TABLE issues DROP CONSTRAINT IF EXISTS issues_type_check;
ALTER TABLE issues ADD CONSTRAINT issues_type_check CHECK (type IN ('story', 'task', 'bug', 'spike', 'subtask'));
