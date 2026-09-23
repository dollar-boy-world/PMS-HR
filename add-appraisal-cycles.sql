-- Indus Pharma PMS: review period (cycle) lock + SECTION A target achievement
-- Master Control sets/locks a review period (e.g. 2026); employees cannot edit their
-- self-appraisal while the cycle is frozen. Master Control uploads Target Achievement %.

-- 1) Cycles table — one active cycle at a time (enforced by UNIQUE on is_active)
CREATE TABLE IF NOT EXISTS appraisal_cycles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_year INTEGER NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'LOCKED', 'CLOSED')),
  target_achievement_uploaded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  locked_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE
);

-- 2) Reference the active cycle from appraisals
ALTER TABLE appraisals
  ADD COLUMN IF NOT EXISTS review_period INTEGER,
  ADD COLUMN IF NOT EXISTS target_achievement_pct DECIMAL(5,2);

-- 3) Master Control: flip a cycle to LOCKED. Once locked, employee writes are blocked
--    at the app level (UI) + this index makes lookups cheap.
CREATE INDEX IF NOT EXISTS idx_appraisals_review_period ON appraisals(review_period);
CREATE INDEX IF NOT EXISTS idx_appraisal_cycles_active ON appraisal_cycles(review_year) WHERE status = 'OPEN';

-- 4) Seed the 2026 cycle (Master Control will lock it later).
INSERT INTO appraisal_cycles (review_year, status) VALUES (2026, 'OPEN')
ON CONFLICT (review_year) DO NOTHING;

-- 5) Backfill existing appraisals to the 2026 cycle if they have none.
UPDATE appraisals SET review_period = 2026 WHERE review_period IS NULL;
