-- Add additional profile fields to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS employee_status TEXT DEFAULT 'Active' CHECK (employee_status IN ('Active', 'Resigned')),
ADD COLUMN IF NOT EXISTS salutation TEXT CHECK (salutation IN ('Mr.', 'Ms.', 'Mrs.')),
ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('Male', 'Female', 'Other'));

-- Create index for status filtering
CREATE INDEX IF NOT EXISTS idx_users_employee_status ON users(employee_status);

-- Update existing HR user
UPDATE users
SET
  employee_status = 'Active',
  salutation = 'Mr.',
  gender = 'Male'
WHERE cnic = '4200000000001';
