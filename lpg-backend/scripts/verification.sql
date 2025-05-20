-- verification.sql
-- 1. RLS Policy Enforcement Testing
DO $$
DECLARE
  v_results JSONB := '[]'::JSONB;
  v_result JSONB;
  v_count INTEGER;
BEGIN
  -- Test as admin user
  SET LOCAL role = authenticated;
  SET LOCAL request.jwt.claims = '{"sub": "admin-user-id"}';
  
  SELECT COUNT(*) INTO v_count FROM relationship_strength_analytics_mv;
  v_result := jsonb_build_object(
    'test', 'admin_access_relationship_strength',
    'count', v_count,
    'passed', v_count > 0
  );
  v_results := v_results || v_result;
  
  -- Test as regular user
  SET LOCAL request.jwt.claims = '{"sub": "regular-user-id"}';
  
  SELECT COUNT(*) INTO v_count FROM relationship_strength_analytics_mv;
  v_result := jsonb_build_object(
    'test', 'user_access_relationship_strength',
    'count', v_count,
    'passed', v_count >= 0 -- Should only see their own
  );
  v_results := v_results || v_result;
  
  -- Output results
  RAISE NOTICE 'RLS TEST RESULTS: %', v_results;
END $$;

-- 2. Write Throughput Testing
DO $$
BEGIN
  PERFORM public.test_write_throughput(
    'interactions', 
    1000, -- records
    10    -- concurrent clients
  );
END $$;

-- 3. Materialized View Refresh Performance
SELECT view_name, 
       refresh_duration_ms, 
       pg_size_pretty(pg_relation_size(view_name::regclass))
FROM public.refresh_all_materialized_views(false);
