-- ============================================================================
-- SIMPLIFIED ROLE HIERARCHY - 7 Tiers Only
-- ============================================================================

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

-- Update existing users to new role codes (if any exist)
-- HR user should remain HR
UPDATE users SET role_code = 'HR' WHERE role_code = 'HR' OR cnic = '4200000000001';
