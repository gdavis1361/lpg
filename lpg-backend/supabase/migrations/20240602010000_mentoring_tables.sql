-- 20240602010000_mentoring_tables.sql
-- Extracted from 20250522010000_mentor_relationship_milestones_view.sql

-- Create mentor milestones table and initial data
BEGIN;

-- 0. Prerequisites
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Create mentor_milestones table
CREATE TABLE IF NOT EXISTS public.mentor_milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  typical_year INTEGER, -- Year in the 6-year journey (1-6) when this typically occurs
  is_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Apply RLS immediately
ALTER TABLE public.mentor_milestones ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view milestone definitions
CREATE POLICY "mentor_milestones_read_authenticated" ON public.mentor_milestones
  FOR SELECT USING (auth.role() = 'authenticated');

-- Seed basic milestones
INSERT INTO public.mentor_milestones (name, description, typical_year, is_required) VALUES
('Initial Mentor-Student Meeting', 'First formal meeting between mentor and student to establish rapport and expectations.', 1, TRUE),
('Personal Goals Setting', 'Collaborative session to define student''s academic, personal, and/or career goals for the year.', 1, TRUE),
('First School Event Attended by Mentor', 'Mentor attends a school event (e.g., sports game, performance, academic fair) with or in support of the student.', 1, FALSE),
('Academic Year 1 Review & Planning', 'End-of-year reflection on progress towards goals and planning for the next academic year.', 1, TRUE),
('Career Interests Exploration', 'Discussion about student''s career interests, potential pathways, and necessary skills.', 2, TRUE),
('Mentor Workplace Visit by Student', 'Student visits the mentor''s workplace to gain exposure to a professional environment.', 3, FALSE),
('Early College Awareness & Planning', 'Initial discussions about college options, types of institutions, and early preparation steps.', 4, TRUE),
('College Application Support & Review', 'Mentor provides guidance and feedback on college applications, essays, or interview preparation.', 6, TRUE),
('Student Graduation Attended by Mentor', 'Mentor attends the student''s high school graduation ceremony.', 6, TRUE),
('Post-Graduation Relationship Plan', 'Discussion and agreement on how the mentor-student relationship will continue post-graduation.', 6, TRUE)
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE public.mentor_milestones IS 'Defines standard milestones for mentor-student relationships.';
COMMENT ON COLUMN public.mentor_milestones.name IS 'Unique name of the milestone.';
COMMENT ON COLUMN public.mentor_milestones.typical_year IS 'Typical year in a 6-year mentor journey this milestone occurs (1-6).';
COMMENT ON COLUMN public.mentor_milestones.is_required IS 'Indicates if this milestone is considered mandatory.';

COMMIT; 