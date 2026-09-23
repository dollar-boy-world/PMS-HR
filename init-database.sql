-- Create Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cnic TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  email TEXT,
  role TEXT NOT NULL CHECK (role IN ('FIELD', 'LM', 'SR_LM', 'GM', 'HR')),
  manager_id UUID REFERENCES users(id),
  password_hash TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Appraisals Table
CREATE TABLE IF NOT EXISTS appraisals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES users(id),
  year INTEGER NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('DRAFT', 'PENDING_LM', 'PENDING_SR_LM', 'PENDING_GM', 'PENDING_HR', 'COMPLETED', 'REJECTED')),

  -- Section A (80% - YTD Achievement)
  ytd_achievement DECIMAL(5,2),
  section_a_score DECIMAL(5,2),

  -- Section B (20% - 4 Attributes)
  attr_1 INTEGER CHECK (attr_1 >= 0 AND attr_1 <= 10),
  attr_2 INTEGER CHECK (attr_2 >= 0 AND attr_2 <= 10),
  attr_3 INTEGER CHECK (attr_3 >= 0 AND attr_3 <= 10),
  attr_4 INTEGER CHECK (attr_4 >= 0 AND attr_4 <= 10),
  section_b_score DECIMAL(5,2),

  -- Final Score
  final_score DECIMAL(5,2),

  -- Comments and tracking
  lm_comments TEXT,
  sr_lm_comments TEXT,
  gm_comments TEXT,
  hr_comments TEXT,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(employee_id, year)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_appraisals_status ON appraisals(status);
CREATE INDEX IF NOT EXISTS idx_appraisals_employee ON appraisals(employee_id);
CREATE INDEX IF NOT EXISTS idx_users_cnic ON users(cnic);
CREATE INDEX IF NOT EXISTS idx_users_manager ON users(manager_id);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can read their own data and their reportees
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid()::text = id::text);

CREATE POLICY "Users can view their appraisals" ON appraisals
  FOR SELECT USING (
    employee_id IN (
      SELECT id FROM users WHERE id::text = auth.uid()::text
    )
  );

-- Insert a test HR user (CNIC: 4200000000001, Password: admin123)
-- Password hash for 'admin123' (you'll need to replace this with actual bcrypt hash)
INSERT INTO users (cnic, name, email, role, password_hash)
VALUES ('4200000000001', 'HR Admin', 'hr@induspharma.com', 'HR', 'temp_hash_replace_later')
ON CONFLICT (cnic) DO NOTHING;
