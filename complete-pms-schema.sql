-- ============================================================================
-- INDUS PHARMA PMS - COMPLETE DATABASE SCHEMA
-- Role-Based Hierarchical Performance Management System
-- ============================================================================

-- Drop existing tables if rebuilding (careful in production!)
-- DROP TABLE IF EXISTS appraisal_approvals CASCADE;
-- DROP TABLE IF EXISTS appraisals CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;
-- DROP TABLE IF EXISTS roles CASCADE;

-- ============================================================================
-- TABLE: roles
-- Defines the 7-tier hierarchy with approval permissions
-- ============================================================================
CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  tier INTEGER NOT NULL,
  can_approve BOOLEAN DEFAULT FALSE,
  description TEXT
);

-- Insert role hierarchy
INSERT INTO roles (code, title, tier, can_approve, description) VALUES
('SPO', 'Sales Promotion Officer', 1, FALSE, 'Field force - no approval rights'),
('SSPO', 'Senior Sales Promotion Officer', 1, FALSE, 'Field force - no approval rights'),
('TME', 'Territory Medical Executive', 1, FALSE, 'Field force - no approval rights'),
('AFM', 'Area Field Manager', 2, TRUE, 'Approves Tier 1'),
('FM', 'Field Manager', 2, TRUE, 'Approves Tier 1'),
('SFM', 'Senior Field Manager', 2, TRUE, 'Approves Tier 1'),
('ASM', 'Area Sales Manager', 3, TRUE, 'Approves Tier 2'),
('SM', 'Sales Manager', 3, TRUE, 'Approves Tier 2'),
('SSM', 'Senior Sales Manager', 3, TRUE, 'Approves Tier 2'),
('RTL', 'Regional Team Leader', 3, TRUE, 'Approves Tier 2'),
('RTRL', 'Regional Territory Lead', 4, TRUE, 'Approves Tier 3'),
('BM', 'Business Manager', 5, TRUE, 'Approves Tier 4'),
('MM', 'Marketing Manager', 5, TRUE, 'Approves Tier 4'),
('GM', 'General Manager', 5, TRUE, 'Approves Tier 5'),
('DIRECTOR', 'Director', 6, TRUE, 'Approves Tier 5'),
('HR', 'Human Resources', 7, TRUE, 'Master control - can override all')
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- TABLE: users (Enhanced with roles)
-- ============================================================================
ALTER TABLE users DROP COLUMN IF EXISTS role CASCADE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS role_code TEXT REFERENCES roles(code);
ALTER TABLE users ADD COLUMN IF NOT EXISTS line_manager_id UUID REFERENCES users(id);

-- Create index for manager hierarchy lookups
CREATE INDEX IF NOT EXISTS idx_users_line_manager ON users(line_manager_id);
CREATE INDEX IF NOT EXISTS idx_users_role_code ON users(role_code);

-- ============================================================================
-- TABLE: appraisals (Enhanced with workflow)
-- ============================================================================
DROP TABLE IF EXISTS appraisals CASCADE;
CREATE TABLE appraisals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  appraisal_year INTEGER NOT NULL,

  -- Workflow Status
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN (
    'DRAFT',           -- Employee filling
    'SUBMITTED',       -- Submitted by employee
    'PENDING_LM',      -- With immediate line manager
    'PENDING_TIER_3',  -- With tier 3 manager (ASM/SM/SSM/RTL)
    'PENDING_TIER_4',  -- With tier 4 (RTRL)
    'PENDING_TIER_5',  -- With tier 5 (BM/MM/GM)
    'PENDING_DIRECTOR',-- With Director
    'PENDING_HR',      -- Final HR review
    'COMPLETED',       -- Fully approved
    'REJECTED',        -- Rejected at any stage
    'SKIPPED'          -- HR override/skip
  )),

  current_approver_id UUID REFERENCES users(id),

  -- Section A: YTD Achievement (80% weight) - Entered by HR
  ytd_percentage DECIMAL(5,2),
  section_a_score DECIMAL(5,2),

  -- Section B: Attributes (20% weight) - 4 attributes, max 10 each
  attr_1_score INTEGER CHECK (attr_1_score >= 0 AND attr_1_score <= 10),
  attr_1_name TEXT DEFAULT 'Leadership',
  attr_2_score INTEGER CHECK (attr_2_score >= 0 AND attr_2_score <= 10),
  attr_2_name TEXT DEFAULT 'Communication',
  attr_3_score INTEGER CHECK (attr_3_score >= 0 AND attr_3_score <= 10),
  attr_3_name TEXT DEFAULT 'Technical Skills',
  attr_4_score INTEGER CHECK (attr_4_score >= 0 AND attr_4_score <= 10),
  attr_4_name TEXT DEFAULT 'Team Collaboration',
  section_b_avg DECIMAL(5,2),
  section_b_score DECIMAL(5,2),

  -- Final Score
  final_score DECIMAL(5,2),

  -- Employee Self-Assessment (Optional)
  employee_comments TEXT,

  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  submitted_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,

  UNIQUE(employee_id, appraisal_year)
);

CREATE INDEX idx_appraisals_status ON appraisals(status);
CREATE INDEX idx_appraisals_employee ON appraisals(employee_id);
CREATE INDEX idx_appraisals_current_approver ON appraisals(current_approver_id);
CREATE INDEX idx_appraisals_year ON appraisals(appraisal_year);

-- ============================================================================
-- TABLE: appraisal_approvals
-- Tracks each approval step in the chain
-- ============================================================================
CREATE TABLE IF NOT EXISTS appraisal_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appraisal_id UUID NOT NULL REFERENCES appraisals(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES users(id),
  approver_role_code TEXT NOT NULL,

  action TEXT NOT NULL CHECK (action IN ('APPROVED', 'REJECTED', 'SKIPPED')),
  comments TEXT,

  -- Manager can update Section B scores during review
  attr_1_score_override INTEGER CHECK (attr_1_score_override >= 0 AND attr_1_score_override <= 10),
  attr_2_score_override INTEGER CHECK (attr_2_score_override >= 0 AND attr_2_score_override <= 10),
  attr_3_score_override INTEGER CHECK (attr_3_score_override >= 0 AND attr_3_score_override <= 10),
  attr_4_score_override INTEGER CHECK (attr_4_score_override >= 0 AND attr_4_score_override <= 10),

  approved_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(appraisal_id, approver_id)
);

CREATE INDEX idx_approvals_appraisal ON appraisal_approvals(appraisal_id);
CREATE INDEX idx_approvals_approver ON appraisal_approvals(approver_id);

-- ============================================================================
-- VIEWS: Useful aggregations
-- ============================================================================

-- View: Pending approvals per manager
CREATE OR REPLACE VIEW vw_pending_approvals AS
SELECT
  a.id AS appraisal_id,
  a.employee_id,
  u.name AS employee_name,
  u.e_code AS employee_code,
  u.designation AS employee_designation,
  a.status,
  a.current_approver_id,
  m.name AS current_approver_name,
  m.role_code AS current_approver_role,
  a.appraisal_year,
  a.submitted_at,
  EXTRACT(DAY FROM NOW() - a.submitted_at) AS days_pending
FROM appraisals a
JOIN users u ON a.employee_id = u.id
LEFT JOIN users m ON a.current_approver_id = m.id
WHERE a.status NOT IN ('DRAFT', 'COMPLETED', 'REJECTED');

-- ============================================================================
-- FUNCTION: Auto-calculate scores
-- ============================================================================
CREATE OR REPLACE FUNCTION calculate_appraisal_scores()
RETURNS TRIGGER AS $$
BEGIN
  -- Section A: YTD% × 80
  IF NEW.ytd_percentage IS NOT NULL THEN
    NEW.section_a_score := (NEW.ytd_percentage * 0.80);
  END IF;

  -- Section B: Average of 4 attributes × 20
  IF NEW.attr_1_score IS NOT NULL AND NEW.attr_2_score IS NOT NULL
     AND NEW.attr_3_score IS NOT NULL AND NEW.attr_4_score IS NOT NULL THEN
    NEW.section_b_avg := (NEW.attr_1_score + NEW.attr_2_score + NEW.attr_3_score + NEW.attr_4_score) / 4.0;
    NEW.section_b_score := (NEW.section_b_avg * 2.0); -- Max 10 avg × 2 = 20%
  END IF;

  -- Final Score
  IF NEW.section_a_score IS NOT NULL AND NEW.section_b_score IS NOT NULL THEN
    NEW.final_score := NEW.section_a_score + NEW.section_b_score;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
DROP TRIGGER IF EXISTS trg_calculate_scores ON appraisals;
CREATE TRIGGER trg_calculate_scores
BEFORE INSERT OR UPDATE ON appraisals
FOR EACH ROW EXECUTE FUNCTION calculate_appraisal_scores();

-- ============================================================================
-- FUNCTION: Route appraisal to next approver
-- ============================================================================
CREATE OR REPLACE FUNCTION route_to_next_approver(appraisal_uuid UUID)
RETURNS TEXT AS $$
DECLARE
  emp_record RECORD;
  next_approver_id UUID;
  new_status TEXT;
BEGIN
  -- Get employee and current appraisal info
  SELECT u.line_manager_id, u.role_code, a.status
  INTO emp_record
  FROM appraisals a
  JOIN users u ON a.employee_id = u.id
  WHERE a.id = appraisal_uuid;

  -- Determine next step based on current status
  CASE emp_record.status
    WHEN 'SUBMITTED' THEN
      new_status := 'PENDING_LM';
      next_approver_id := emp_record.line_manager_id;

    WHEN 'PENDING_LM' THEN
      -- Find tier 3 manager (lookup chain)
      new_status := 'PENDING_TIER_3';
      -- TODO: Implement manager chain lookup
      next_approver_id := NULL; -- Placeholder

    WHEN 'PENDING_TIER_3' THEN
      new_status := 'PENDING_TIER_4';
      next_approver_id := NULL;

    WHEN 'PENDING_TIER_4' THEN
      new_status := 'PENDING_TIER_5';
      next_approver_id := NULL;

    WHEN 'PENDING_TIER_5' THEN
      new_status := 'PENDING_DIRECTOR';
      next_approver_id := NULL;

    WHEN 'PENDING_DIRECTOR' THEN
      new_status := 'PENDING_HR';
      next_approver_id := NULL; -- HR will pick it up from queue

    WHEN 'PENDING_HR' THEN
      new_status := 'COMPLETED';
      next_approver_id := NULL;

    ELSE
      RETURN 'INVALID_STATUS';
  END CASE;

  -- Update appraisal
  UPDATE appraisals
  SET status = new_status,
      current_approver_id = next_approver_id,
      updated_at = NOW()
  WHERE id = appraisal_uuid;

  RETURN new_status;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS Policies (Simplified for now - will enhance later)
-- ============================================================================
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisal_approvals ENABLE ROW LEVEL SECURITY;

-- Allow all reads for now (we'll refine per-role later)
CREATE POLICY "Allow read access" ON appraisals FOR SELECT USING (true);
CREATE POLICY "Allow approval read access" ON appraisal_approvals FOR SELECT USING (true);

-- ============================================================================
-- Sample Data: Update HR user role
-- ============================================================================
UPDATE users
SET role_code = 'HR',
    line_manager_id = NULL
WHERE cnic = '4200000000001';

-- ============================================================================
-- DONE! Schema ready for full PMS system
-- ============================================================================
