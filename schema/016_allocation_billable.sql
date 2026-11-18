-- Billable or non-billable project allocation. Only billable allocations count in effort tracking
-- (planned hours, actual hours, utilization); non-billable ones still take the person's time.
ALTER TABLE resource_allocations ADD COLUMN IF NOT EXISTS billable BOOLEAN NOT NULL DEFAULT true;
