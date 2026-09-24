-- Jira priority of each issue (e.g. "P1 - Blocker"), used for the P1 - Blocker summary card.
ALTER TABLE issues ADD COLUMN IF NOT EXISTS priority VARCHAR(60);
