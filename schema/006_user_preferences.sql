-- Per-user preferences, e.g. the dashboard layout (widget order, size and visibility)
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id          UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  dashboard_layout JSONB,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
