-- Add HOS and NSM roles to tier 5
INSERT INTO roles (code, title, tier, can_approve, description) VALUES
('HOS', 'Head of Sales', 5, TRUE, 'Approves Tier 4'),
('NSM', 'National Sales Manager', 5, TRUE, 'Approves Tier 4')
ON CONFLICT (code) DO NOTHING;
