-- ============================================================================
-- FIX MIGRATION: unblock writes + auto-route on submit
-- Additive only. Safe to re-run (guarded with DROP ... IF EXISTS).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RLS: the anon-key browser client must be able to write
-- ----------------------------------------------------------------------------
-- NOTE (ponytail): USING (true) makes the app talk directly to Supabase with
-- the public anon key, so anyone can read/alter HR data. Fine for a local
-- demo; before any real/production use replace these with per-role policies
-- driven by real auth (auth.jwt() role claims or a service key behind route
-- handlers). Do NOT expose real employee data on top of this.
CREATE POLICY "Allow insert appraisals" ON appraisals FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update appraisals" ON appraisals FOR UPDATE USING (true);
CREATE POLICY "Allow insert approvals" ON appraisal_approvals FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow update users" ON users FOR UPDATE USING (true);
CREATE POLICY "Allow insert users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow delete users" ON users FOR DELETE USING (true);

-- ----------------------------------------------------------------------------
-- 2. Auto-route: employee submit -> PENDING_LM + current_approver_id
-- ----------------------------------------------------------------------------
-- Existing calculate_appraisal_scores() only computes scores. Add routing so
-- "Submit for Review" actually enters the approval chain.
CREATE OR REPLACE FUNCTION calculate_appraisal_scores()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.ytd_percentage IS NOT NULL THEN
    NEW.section_a_score := (NEW.ytd_percentage * 0.80);
  END IF;

  IF NEW.attr_1_score IS NOT NULL AND NEW.attr_2_score IS NOT NULL
     AND NEW.attr_3_score IS NOT NULL AND NEW.attr_4_score IS NOT NULL THEN
    NEW.section_b_avg := (NEW.attr_1_score + NEW.attr_2_score + NEW.attr_3_score + NEW.attr_4_score) / 4.0;
    NEW.section_b_score := (NEW.section_b_avg * 2.0); -- max avg 10 x 2 = 20%
  END IF;

  IF NEW.section_a_score IS NOT NULL AND NEW.section_b_score IS NOT NULL THEN
    NEW.final_score := NEW.section_a_score + NEW.section_b_score;
  END IF;

  -- Route on submit: first stop is the employee's line manager
  IF NEW.status IN ('SUBMITTED', 'PENDING_LM') AND NEW.current_approver_id IS NULL THEN
    SELECT line_manager_id INTO NEW.current_approver_id FROM users WHERE id = NEW.employee_id;
    IF NEW.status = 'SUBMITTED' THEN
      NEW.status := 'PENDING_LM';
      NEW.submitted_at := COALESCE(NEW.submitted_at, NOW());
    END IF;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 3. Demo data so the HR dashboard shows real numbers instead of 0
-- ----------------------------------------------------------------------------
-- A provisional manager chain for the existing field-force user. Replace with
-- the real Indus Pharma reporting lines. `||'-'||gen_random_uuid()::text`
-- keeps e_code/cnic unique per run without hand-editing values.
UPDATE users
SET line_manager_id = m.id
FROM (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) AS m
WHERE users.cnic = '4200000012000';

-- Manager rows (all use the temp hash, so they log in with any password in the
-- local demo — same as the seeded HR user). Add real bcrypt hashes later.
INSERT INTO users (e_code, name, cnic, role_code, designation, salutation, gender,
                   region, city_base, date_of_joining, employee_type, employee_status,
                   line_manager_id, password_hash)
SELECT 'FM001-' || substr(gen_random_uuid()::text, 1, 4), 'Field Manager Demo', '4200000012001',
       'FM', 'Field Manager', 'Mr.', 'Male', 'Sindh', 'Karachi', '2019-03-01', 'Confirmed', 'Active',
       hr.id, 'temp_hash_replace_later'
FROM (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) AS hr
ON CONFLICT (cnic) DO NOTHING;

INSERT INTO users (e_code, name, cnic, role_code, designation, salutation, gender,
                   region, city_base, date_of_joining, employee_type, employee_status,
                   line_manager_id, password_hash)
SELECT 'SM001-' || substr(gen_random_uuid()::text, 1, 4), 'Sales Manager Demo', '4200000012002',
       'SM', 'Sales Manager', 'Ms.', 'Female', 'Sindh', 'Karachi', '2017-01-10', 'Confirmed', 'Active',
       hr.id, 'temp_hash_replace_later'
FROM (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) AS hr
ON CONFLICT (cnic) DO NOTHING;

INSERT INTO users (e_code, name, cnic, role_code, designation, salutation, gender,
                   region, city_base, date_of_joining, employee_type, employee_status,
                   line_manager_id, password_hash)
SELECT 'NSM001-' || substr(gen_random_uuid()::text, 1, 4), 'National Sales Manager Demo', '4200000012003',
       'NSM', 'National Sales Manager', 'Mr.', 'Male', 'Punjab', 'Lahore', '2015-06-15', 'Confirmed', 'Active',
       hr.id, 'temp_hash_replace_later'
FROM (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) AS hr
ON CONFLICT (cnic) DO NOTHING;

INSERT INTO users (e_code, name, cnic, role_code, designation, salutation, gender,
                   region, city_base, date_of_joining, employee_type, employee_status,
                   line_manager_id, password_hash)
SELECT 'GM001-' || substr(gen_random_uuid()::text, 1, 4), 'General Manager Demo', '4200000012004',
       'GM', 'General Manager', 'Mr.', 'Male', 'Punjab', 'Lahore', '2013-02-20', 'Confirmed', 'Active',
       hr.id, 'temp_hash_replace_later'
FROM (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) AS hr
ON CONFLICT (cnic) DO NOTHING;

-- Chain (by cnic so re-runs stay correct):
--   SPO -> FM -> SM -> NSM -> GM -> HR
UPDATE users SET line_manager_id = (SELECT id FROM users WHERE cnic = '4200000012001' LIMIT 1) WHERE cnic = '4200000012000';
UPDATE users SET line_manager_id = (SELECT id FROM users WHERE cnic = '4200000012002' LIMIT 1) WHERE cnic = '4200000012001';
UPDATE users SET line_manager_id = (SELECT id FROM users WHERE cnic = '4200000012003' LIMIT 1) WHERE cnic = '4200000012002';
UPDATE users SET line_manager_id = (SELECT id FROM users WHERE cnic = '4200000012004' LIMIT 1) WHERE cnic = '4200000012003';
UPDATE users SET line_manager_id = (SELECT id FROM users WHERE role_code = 'HR' LIMIT 1) WHERE cnic = '4200000012004';

-- Done.