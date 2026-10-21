-- Team members come from Jira (people assigned to issues on the team's board) or are added by an
-- administrator. Removing a member keeps the row as excluded, so the next Jira sync doesn't add them back.
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS source   VARCHAR(10) NOT NULL DEFAULT 'jira' CHECK (source IN ('jira', 'manual'));
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS excluded BOOLEAN     NOT NULL DEFAULT false;
ALTER TABLE team_members ADD COLUMN IF NOT EXISTS added_at TIMESTAMPTZ NOT NULL DEFAULT now();
