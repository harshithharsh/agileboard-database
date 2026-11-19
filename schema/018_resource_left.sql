-- Last working day of a person who left the organization: from the next day nothing is planned for
-- them, their allocations stop counting, and they drop out of later periods in Resource Management
ALTER TABLE resource_profiles ADD COLUMN IF NOT EXISTS left_on DATE;
