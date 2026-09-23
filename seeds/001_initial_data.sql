-- AgileBoard starting data: projects, teams and their Jira boards, metric targets.
-- Sprints, issues, users, defects and blockers are loaded from Jira by the
-- backend sync (cd agileboard-backend && npm run sync).

BEGIN;

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
  ('completion',     '>=', 80),
  ('spillover',      '<=', 10),
  ('unplanned',      '<=', 10),
  ('blocked_items',  '<=', 3),
  ('dod_compliance', '>=', 100)
) AS t(metric, operator, value);

COMMIT;
