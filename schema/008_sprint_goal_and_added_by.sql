-- Sprint goal outcome (recorded by a person) and who added an issue to a sprint mid-way.

-- Issues tagged in Jira as part of the sprint goal (label "sprint-goal")
ALTER TABLE issues ADD COLUMN IF NOT EXISTS is_goal_item BOOLEAN NOT NULL DEFAULT false;

-- Who moved the issue into the sprint (Jira changelog author), or who created it inside the sprint
ALTER TABLE sprint_issues ADD COLUMN IF NOT EXISTS added_by VARCHAR(255);

-- Met / partly met / not met, as confirmed by a Scrum Master. Kept apart from synced data so a
-- Jira sync never overwrites it.
CREATE TABLE IF NOT EXISTS sprint_goal_outcomes (
  sprint_id   UUID PRIMARY KEY REFERENCES sprints(id) ON DELETE CASCADE,
  outcome     VARCHAR(20) NOT NULL CHECK (outcome IN ('met', 'partly_met', 'not_met')),
  note        VARCHAR(500),
  recorded_by UUID REFERENCES users(id) ON DELETE SET NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
