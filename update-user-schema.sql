-- Add new columns to users table for complete employee profile
ALTER TABLE users
ADD COLUMN IF NOT EXISTS e_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS team TEXT,
ADD COLUMN IF NOT EXISTS grade TEXT,
ADD COLUMN IF NOT EXISTS designation TEXT,
ADD COLUMN IF NOT EXISTS city_base TEXT,
ADD COLUMN IF NOT EXISTS region TEXT,
ADD COLUMN IF NOT EXISTS date_of_joining DATE,
ADD COLUMN IF NOT EXISTS date_of_confirmation DATE,
ADD COLUMN IF NOT EXISTS employee_type TEXT CHECK (employee_type IN ('Confirmed', 'On Probation'));

-- Create index for employee code (for fast searching)
CREATE INDEX IF NOT EXISTS idx_users_ecode ON users(e_code);

-- Update the test HR user with sample data
UPDATE users
SET
  e_code = 'HR001',
  team = 'Human Resources',
  grade = 'G5',
  designation = 'Assistant Manager HR',
  city_base = 'Karachi',
  region = 'Sindh',
  date_of_joining = '2020-01-15',
  date_of_confirmation = '2020-07-15',
  employee_type = 'Confirmed'
WHERE cnic = '4200000000001';
