-- Indus Pharma PMS: appraisal_approvals refactor for per-attribute manager overrides
-- Adds attr_overrides (JSON) + return_to_employee flag to support the new form design.
-- Additive only; safe to re-run.

-- 1) Replace per-attribute override columns with a single JSON column
ALTER TABLE appraisal_approvals
  ADD COLUMN IF NOT EXISTS attr_overrides JSONB;

-- Copy any legacy single-column overrides into the JSON map (defensive; only if old columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'appraisal_approvals' AND column_name = 'attr_1_score_override') THEN
    UPDATE appraisal_approvals
       SET attr_overrides = jsonb_build_object(
         'knowledge',            attr_1_score_override,
         'general_attributes',   attr_2_score_override,
         'skills',               attr_3_score_override,
         'living_values',        attr_4_score_override
       )
     WHERE attr_1_score_override IS NOT NULL
        OR attr_2_score_override IS NOT NULL
        OR attr_3_score_override IS NOT NULL
        OR attr_4_score_override IS NOT NULL;
    -- keep old columns; they're harmless and removing them risks a CASCADE on dependent code
  END IF;
END $$;

-- 2) Add return-to-employee flag
ALTER TABLE appraisal_approvals
  ADD COLUMN IF NOT EXISTS return_to_employee BOOLEAN DEFAULT FALSE;

-- 3) Ensure appraisals table has the new Section B rating columns as JSONB
ALTER TABLE appraisals
  ADD COLUMN IF NOT EXISTS section_b_ratings JSONB,
  ADD COLUMN IF NOT EXISTS section_b_avg_self  DECIMAL(5,2),
  ADD COLUMN IF NOT EXISTS section_b_avg_final  DECIMAL(5,2);

-- 4) Updated scoring trigger:
--    SECTION A = target_achievement_pct * 0.80  (max 80)
--    SECTION B = (avg of 4 attrs on 1-5 scale / 5) * 100 * 0.20  (max 20)
--    Final     = SECTION A + SECTION B
CREATE OR REPLACE FUNCTION calculate_appraisal_scores_v2()
RETURNS TRIGGER AS $$
DECLARE
  _sec_a     DECIMAL(5,2);
  _avg_final DECIMAL(5,2);
  _sec_b     DECIMAL(5,2);
BEGIN
  -- SECTION A (80%): target_achievement_pct (set by Master Control)
  IF NEW.target_achievement_pct IS NOT NULL THEN
    _sec_a := (NEW.target_achievement_pct * 0.80);
  END IF;

  -- SECTION B (20%): use manager overrides when present, otherwise self-ratings
  IF NEW.section_b_ratings IS NOT NULL THEN
    SELECT
      ROUND(
        (
          COALESCE((NEW.section_b_ratings->>'knowledge')::NUMERIC, (NEW.section_b_ratings->'knowledge'->>'self')::NUMERIC),
          COALESCE((NEW.section_b_ratings->>'general_attributes')::NUMERIC, (NEW.section_b_ratings->'general_attributes'->>'self')::NUMERIC),
          COALESCE((NEW.section_b_ratings->>'skills')::NUMERIC, (NEW.section_b_ratings->'skills'->>'self')::NUMERIC),
          COALESCE((NEW.section_b_ratings->>'living_values')::NUMERIC, (NEW.section_b_ratings->'living_values'->>'self')::NUMERIC)
        ) / 4.0, 2
      )
    INTO _avg_final
    FROM (SELECT 1) _;  -- workaround so the statement works standalone

    -- fallback: simple average if JSON parse above returns nothing
    IF _avg_final IS NULL THEN
      SELECT AVG(v)::DECIMAL(5,2) INTO _avg_final
      FROM jsonb_to_recordset(NEW.section_b_ratings) AS x(self NUMERIC);
    END IF;

    NEW.section_b_avg_final := _avg_final;
    _sec_b := ROUND((_avg_final / 5.0) * 100.0 * 0.20, 2);
    NEW.section_b_score := _sec_b;

    -- also store self-only avg for reference
    SELECT AVG(v)::DECIMAL(5,2) INTO NEW.section_b_avg_self
    FROM jsonb_object_keys(NEW.section_b_ratings) k
    CROSS JOIN LATERAL (SELECT (NEW.section_b_ratings->k->>'self')::NUMERIC AS v) r;
  END IF;

  -- Final score = A + B
  IF _sec_a IS NOT NULL AND NEW.section_b_score IS NOT NULL THEN
    NEW.final_score := ROUND(_sec_a + NEW.section_b_score, 2);
  ELSIF _sec_a IS NOT NULL THEN
    NEW.final_score := _sec_a;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_calculate_scores_v2 ON appraisals;
CREATE TRIGGER trg_calculate_scores_v2
BEFORE INSERT OR UPDATE ON appraisals
FOR EACH ROW EXECUTE FUNCTION calculate_appraisal_scores_v2();
