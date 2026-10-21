-- Public holidays: left out of capacity and planned hours in Resource Management
CREATE TABLE IF NOT EXISTS holidays (
  day        DATE PRIMARY KEY,
  name       VARCHAR(120) NOT NULL,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
