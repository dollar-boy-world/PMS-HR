-- Fix RLS for appraisal_cycles and appraisals
ALTER TABLE appraisal_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisals ENABLE ROW LEVEL SECURITY;
ALTER TABLE appraisal_approvals ENABLE ROW LEVEL SECURITY;

-- Allow all operations for demo (RLS USING (true))
CREATE POLICY "Allow all on appraisal_cycles" ON appraisal_cycles
  FOR ALL USING (true);

CREATE POLICY "Allow all on appraisals" ON appraisals
  FOR ALL USING (true);

CREATE POLICY "Allow all on appraisal_approvals" ON appraisal_approvals
  FOR ALL USING (true);
