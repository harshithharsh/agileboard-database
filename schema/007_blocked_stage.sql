-- Where a blocked issue was in the workflow when it got blocked, and who had it,
-- so the dashboard can show whether a blocker sits with development, QA or BA
ALTER TABLE blocked_periods ADD COLUMN IF NOT EXISTS blocked_in_status VARCHAR(100);
ALTER TABLE blocked_periods ADD COLUMN IF NOT EXISTS blocked_assignee VARCHAR(255);
