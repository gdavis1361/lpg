-- Prerequisites:
--   - 20250519000000_enable_extensions.sql (for uuid-ossp for uuid_generate_v4())
--   - Assumes 'people' table exists.
-- Purpose: Implements the "Post-Graduation Continuity System" by:
--          1. Altering 'people' table to add alumni-specific fields (idempotently).
--          2. Creating 'alumni_checkins' table.
--          3. Creating 'alumni_risk_assessment' view.
--          4. Creating a trigger function to update 'last_checkin_date' on 'people' table.
--          RLS policies for 'alumni_checkins' will be in a later, consolidated file (20250526010000_apply_rls_policies.sql).

-- Add alumni-specific fields to the people table if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='people' AND column_name='graduation_year') THEN
    ALTER TABLE public.people ADD COLUMN graduation_year INTEGER;
    COMMENT ON COLUMN public.people.graduation_year IS 'Year the person graduated or is expected to graduate.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='people' AND column_name='post_grad_status') THEN
    ALTER TABLE public.people ADD COLUMN post_grad_status TEXT;
    COMMENT ON COLUMN public.people.post_grad_status IS 'Current status after graduation (e.g., College, Employed, Gap Year).';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='people' AND column_name='college_attending') THEN
    ALTER TABLE public.people ADD COLUMN college_attending TEXT;
    COMMENT ON COLUMN public.people.college_attending IS 'Name of the college the alumnus is attending, if applicable.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='people' AND column_name='employment_status') THEN
    ALTER TABLE public.people ADD COLUMN employment_status TEXT;
    COMMENT ON COLUMN public.people.employment_status IS 'Current employment status of the alumnus (e.g., Employed, Seeking).';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='people' AND column_name='last_checkin_date') THEN
    ALTER TABLE public.people ADD COLUMN last_checkin_date DATE;
    COMMENT ON COLUMN public.people.last_checkin_date IS 'Date of the last formal check-in with the alumnus.';
  END IF;
END $$;

-- Create table for alumni check-in records
CREATE TABLE IF NOT EXISTS public.alumni_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alumni_id UUID NOT NULL REFERENCES public.people(id) ON DELETE CASCADE,
  check_date DATE NOT NULL DEFAULT CURRENT_DATE,
  check_method TEXT NOT NULL, -- e.g., 'phone', 'email', 'in-person'
  performed_by UUID REFERENCES public.people(id) ON DELETE SET NULL, -- Staff/mentor who performed check-in
  status_update TEXT, -- General update from the alumnus
  wellbeing_score INTEGER CHECK (wellbeing_score BETWEEN 1 AND 10), -- Optional wellbeing score
  needs_followup BOOLEAN DEFAULT FALSE,
  followup_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.alumni_checkins IS 'Records of check-ins with alumni.';
COMMENT ON COLUMN public.alumni_checkins.alumni_id IS 'Reference to the alumnus (person_id).';
COMMENT ON COLUMN public.alumni_checkins.check_method IS 'Method used for the check-in (e.g., phone, email).';
COMMENT ON COLUMN public.alumni_checkins.performed_by IS 'ID of the staff member or mentor who performed the check-in.';
COMMENT ON COLUMN public.alumni_checkins.wellbeing_score IS 'Optional wellbeing score (1-10) reported during check-in.';
COMMENT ON COLUMN public.alumni_checkins.needs_followup IS 'Indicates if this check-in requires further follow-up.';

-- Create alumni risk assessment view
CREATE OR REPLACE VIEW public.alumni_risk_assessment AS
SELECT
  p.id as alumni_person_id,
  p.first_name,
  p.last_name,
  p.graduation_year,
  p.post_grad_status,
  p.college_attending,
  p.employment_status,
  p.last_checkin_date,
  CASE
    WHEN p.last_checkin_date IS NOT NULL THEN CURRENT_DATE - p.last_checkin_date
    ELSE NULL
  END AS days_since_last_checkin,
  (SELECT MAX(ac_inner.wellbeing_score) FROM public.alumni_checkins ac_inner WHERE ac_inner.alumni_id = p.id AND ac_inner.check_date = p.last_checkin_date) AS last_wellbeing_score,
  (SELECT COUNT(ac_inner.id) FROM public.alumni_checkins ac_inner WHERE ac_inner.alumni_id = p.id) AS total_checkins,
  -- Risk score calculation
  CASE
    WHEN p.last_checkin_date IS NULL THEN 'high' -- No check-ins ever
    WHEN CURRENT_DATE - p.last_checkin_date > 180 THEN 'high' -- More than 6 months since last check-in
    WHEN CURRENT_DATE - p.last_checkin_date > 90 THEN 'medium' -- More than 3 months
    WHEN (SELECT MAX(ac_inner.wellbeing_score) FROM public.alumni_checkins ac_inner WHERE ac_inner.alumni_id = p.id AND ac_inner.check_date = p.last_checkin_date) < 5 THEN 'medium' -- Low wellbeing score
    WHEN (SELECT COUNT(ac_inner.id) FROM public.alumni_checkins ac_inner WHERE ac_inner.alumni_id = p.id) < 2 AND p.graduation_year IS NOT NULL AND EXTRACT(YEAR FROM CURRENT_DATE) - p.graduation_year < 2 THEN 'medium' -- Few check-ins for recent grads
    ELSE 'low'
  END AS risk_level
FROM public.people p
WHERE p.graduation_year IS NOT NULL -- Consider only people who have a graduation year (alumni)
GROUP BY p.id, p.first_name, p.last_name, p.graduation_year, p.post_grad_status,
         p.college_attending, p.employment_status, p.last_checkin_date;

COMMENT ON VIEW public.alumni_risk_assessment IS 'Assesses potential risk or need for follow-up for alumni based on check-in history and status.';
COMMENT ON COLUMN public.alumni_risk_assessment.days_since_last_checkin IS 'Number of days since the alumnus was last checked in on.';
COMMENT ON COLUMN public.alumni_risk_assessment.last_wellbeing_score IS 'Wellbeing score from the most recent check-in.';
COMMENT ON COLUMN public.alumni_risk_assessment.total_checkins IS 'Total number of check-ins recorded for the alumnus.';
COMMENT ON COLUMN public.alumni_risk_assessment.risk_level IS 'Calculated risk level (high, medium, low) for the alumnus.';

-- Create a function to automatically update last_checkin_date on people table
CREATE OR REPLACE FUNCTION public.update_alumni_last_checkin()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.people
  SET 
    last_checkin_date = NEW.check_date,
    updated_at = NOW()
  WHERE id = NEW.alumni_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION public.update_alumni_last_checkin() IS 'Trigger function to update the last_checkin_date on the people table after an alumni_checkin is inserted.';

-- Create a trigger to execute the function after insert on alumni_checkins
CREATE TRIGGER trigger_update_alumni_last_checkin
AFTER INSERT ON public.alumni_checkins
FOR EACH ROW EXECUTE FUNCTION public.update_alumni_last_checkin();
COMMENT ON TRIGGER trigger_update_alumni_last_checkin ON public.alumni_checkins IS 'Updates the associated person''s last_checkin_date upon new alumni check-in.';

-- Note: RLS policy (ALTER TABLE ... ENABLE ROW LEVEL SECURITY; CREATE POLICY ...) 
-- for alumni_checkins will be added in the consolidated RLS migration file: 20250526010000_apply_rls_policies.sql.
