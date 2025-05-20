-- 20240603_security_fixes.sql
-- Security fixes for the relationship framework
-- -----------------------------------------------------------------------------

-- 1. Enable Row Level Security on missing tables -----------------------------
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationship_types ENABLE ROW LEVEL SECURITY;

-- 2. Add basic SELECT policies for authenticated users -----------------------
CREATE POLICY "Roles view – authenticated" ON roles
  FOR SELECT USING (auth.role() = 'authenticated');
  
CREATE POLICY "Relationship types view – authenticated" ON relationship_types
  FOR SELECT USING (auth.role() = 'authenticated');

-- -----------------------------------------------------------------------------
-- End 20240603_security_fixes.sql
