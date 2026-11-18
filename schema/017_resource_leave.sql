-- Leave marked on a person in Resource allocation: no planned hours (and no capacity) on those days
CREATE TABLE IF NOT EXISTS resource_leave (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL CHECK (end_date >= start_date),
  note        VARCHAR(200),
  modified_by VARCHAR(120),
  modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_resource_leave_user ON resource_leave (user_id);
