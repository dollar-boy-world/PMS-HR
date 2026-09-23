-- ============================================================================
-- SIMPLIFIED ROLE HIERARCHY - 7 Tiers Only (Fixed)
-- ============================================================================

-- First, temporarily remove the foreign key constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_code_fkey;

-- Clear existing roles
DELETE FROM roles;

-- Insert simplified 7-tier structure
INSERT INTO roles (code, title, tier, can_approve, description) VALUES
('SPO', 'Sales Promotion Officer', 1, FALSE, 'Field force - no approval rights'),
('FM', 'Field Manager', 2, TRUE, 'Approves Tier 1'),
('SM', 'Sales Manager', 3, TRUE, 'Approves Tier 2'),
('NSM', 'National Sales Manager', 4, TRUE, 'Approves Tier 3'),
('GM', 'General Manager', 5, TRUE, 'Approves Tier 4'),
('DC_COMMERCIAL', 'DC Commercial', 6, TRUE, 'Approves Tier 5'),
('HR', 'Human Resources', 7, TRUE, 'Master control - can override all');

-- Re-add the foreign key constraint
ALTER TABLE users
ADD CONSTRAINT users_role_code_fkey
FOREIGN KEY (role_code) REFERENCES roles(code);

-- Update existing HR user
UPDATE users
SET role_code = 'HR'
WHERE cnic = '4200000000001';

-- Update any other users who might have old role codes (set them to SPO as default)
UPDATE users
SET role_code = 'SPO'
WHERE role_code NOT IN ('SPO', 'FM', 'SM', 'NSM', 'GM', 'DC_COMMERCIAL', 'HR')
   OR role_code IS NULL;
