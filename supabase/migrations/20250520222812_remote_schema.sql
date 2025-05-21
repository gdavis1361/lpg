

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'Standard public schema with enhanced RLS policies.
Access pattern:
- Default user access is controlled by RLS policies checking JWT claims
- Admin users get full access via permission checks in policies  
- Backend services use auth.role() = ''service_role'' check for unrestricted access
- Both approaches are combined with OR conditions in most policies';



CREATE SCHEMA IF NOT EXISTS "search";


ALTER SCHEMA "search" OWNER TO "postgres";


COMMENT ON SCHEMA "search" IS 'Schema for full-text search functionality and related utilities';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA "public";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "search"."find_graduation_cohort"("p_year" integer) RETURNS TABLE("id" "uuid", "first_name" "text", "last_name" "text", "email" "text", "post_grad_status" "text", "college_attending" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.first_name,
    p.last_name,
    p.email,
    p.post_grad_status,
    p.college_attending
  FROM people p
  WHERE p.graduation_year = p_year
  ORDER BY p.last_name, p.first_name;
END;
$$;


ALTER FUNCTION "search"."find_graduation_cohort"("p_year" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "search"."find_graduation_cohort"("p_year" integer) IS 'Find all people in a specific graduation year cohort';



CREATE OR REPLACE FUNCTION "search"."fuzzy_search_people"("p_name" "text", "p_similarity_threshold" double precision DEFAULT 0.3, "p_limit" integer DEFAULT 20) RETURNS TABLE("id" "uuid", "first_name" "text", "last_name" "text", "full_name" "text", "similarity" double precision)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.first_name,
    p.last_name,
    p.first_name || ' ' || p.last_name AS full_name,
    similarity(p.first_name || ' ' || p.last_name, p_name) AS similarity
  FROM people p
  WHERE 
    similarity(p.first_name || ' ' || p.last_name, p_name) > p_similarity_threshold OR
    p.first_name || ' ' || p.last_name ILIKE '%' || p_name || '%'
  ORDER BY similarity DESC
  LIMIT p_limit;
END;
$$;


ALTER FUNCTION "search"."fuzzy_search_people"("p_name" "text", "p_similarity_threshold" double precision, "p_limit" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "search"."fuzzy_search_people"("p_name" "text", "p_similarity_threshold" double precision, "p_limit" integer) IS 'Fuzzy name matching for people using trigram similarity';



CREATE OR REPLACE FUNCTION "search"."generate_search_vector"("p_title" "text", "p_description" "text" DEFAULT NULL::"text", "p_tags" "text"[] DEFAULT NULL::"text"[], "p_additional_text" "text" DEFAULT NULL::"text") RETURNS "tsvector"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
  v_title tsvector;
  v_description tsvector;
  v_tags tsvector;
  v_additional tsvector;
BEGIN
  -- Apply weights for different fields:
  -- A: title (highest relevance)
  -- B: tags 
  -- C: description
  -- D: additional text (lowest relevance)
  
  v_title := setweight(to_tsvector('search.multilingual', COALESCE(p_title, '')), 'A');
  
  IF p_tags IS NOT NULL AND array_length(p_tags, 1) > 0 THEN
    v_tags := setweight(to_tsvector('search.multilingual', array_to_string(p_tags, ' ')), 'B');
  ELSE
    v_tags := to_tsvector('');
  END IF;
  
  IF p_description IS NOT NULL AND p_description <> '' THEN
    v_description := setweight(to_tsvector('search.multilingual', p_description), 'C');
  ELSE
    v_description := to_tsvector('');
  END IF;
  
  IF p_additional_text IS NOT NULL AND p_additional_text <> '' THEN
    v_additional := setweight(to_tsvector('search.multilingual', p_additional_text), 'D');
  ELSE
    v_additional := to_tsvector('');
  END IF;
  
  RETURN v_title || v_tags || v_description || v_additional;
END;
$$;


ALTER FUNCTION "search"."generate_search_vector"("p_title" "text", "p_description" "text", "p_tags" "text"[], "p_additional_text" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "search"."global_search"("p_query" "text", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "entity_type" "text", "title" "text", "description" "text", "search_rank" double precision, "created_at" timestamp with time zone)
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  search_query tsquery;
BEGIN
  -- Convert query to tsquery
  search_query := search.query_to_tsquery(p_query);
  
  -- Return early if empty query
  IF search_query IS NULL THEN
    RETURN;
  END IF;

  -- Unified search across multiple entities
  RETURN QUERY
  (
    -- Search people
    SELECT 
      p.id,
      'person'::TEXT as entity_type,
      p.first_name || ' ' || p.last_name as title,
      CASE 
        WHEN p.college_attending IS NOT NULL THEN 'Student at ' || p.college_attending
        WHEN p.employment_status IS NOT NULL THEN p.employment_status
        ELSE p.post_grad_status
      END as description,
      ts_rank(p.search_vector, search_query) AS search_rank,
      p.created_at
    FROM people p
    WHERE p.search_vector @@ search_query
  )
  UNION ALL
  (
    -- Search relationships (using from_person and to_person names)
    SELECT 
      r.id,
      'relationship'::TEXT as entity_type,
      p1.first_name || ' ' || p1.last_name || ' → ' || p2.first_name || ' ' || p2.last_name as title,
      rt.name || ' relationship' as description,
      0.5 AS search_rank, -- Lower base rank for relationships
      r.created_at
    FROM relationships r
    JOIN people p1 ON r.from_person_id = p1.id
    JOIN people p2 ON r.to_person_id = p2.id
    JOIN relationship_types rt ON r.relationship_type_id = rt.id
    WHERE 
      p1.search_vector @@ search_query OR
      p2.search_vector @@ search_query
  )
  -- Add future entity types here (events, resources, etc.)
  
  ORDER BY search_rank DESC, created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;


ALTER FUNCTION "search"."global_search"("p_query" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "search"."global_search"("p_query" "text", "p_limit" integer, "p_offset" integer) IS 'Unified search function that searches across multiple entity types';



CREATE OR REPLACE FUNCTION "search"."normalize_query"("p_query" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
  RETURN unaccent(lower(trim(p_query)));
END;
$$;


ALTER FUNCTION "search"."normalize_query"("p_query" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "search"."query_to_tsquery"("p_query" "text") RETURNS "tsquery"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
  normalized_query TEXT;
  query_parts TEXT[];
  result tsquery;
BEGIN
  normalized_query := search.normalize_query(p_query);
  
  -- Handle exact phrase searches in quotes
  normalized_query := regexp_replace(normalized_query, '"([^"]*)"', E'\\1:*', 'g');
  
  -- Split into words
  query_parts := regexp_split_to_array(normalized_query, E'\\s+');
  
  -- Create a tsquery that searches for any word (OR) with prefix matching
  result := NULL;
  FOR i IN 1..array_length(query_parts, 1) LOOP
    IF query_parts[i] <> '' THEN
      IF result IS NULL THEN
        result := to_tsquery('search.multilingual', query_parts[i] || ':*');
      ELSE
        result := result || to_tsquery('search.multilingual', query_parts[i] || ':*');
      END IF;
    END IF;
  END LOOP;
  
  RETURN result;
END;
$$;


ALTER FUNCTION "search"."query_to_tsquery"("p_query" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "search"."search_people"("p_query" "text", "p_graduation_year" integer DEFAULT NULL::integer, "p_post_grad_status" "text" DEFAULT NULL::"text", "p_limit" integer DEFAULT 20, "p_offset" integer DEFAULT 0) RETURNS TABLE("id" "uuid", "first_name" "text", "last_name" "text", "email" "text", "graduation_year" integer, "post_grad_status" "text", "search_rank" double precision)
    LANGUAGE "plpgsql"
    AS $_$
DECLARE
  search_query tsquery;
  where_clauses TEXT[];
  where_clause TEXT;
BEGIN
  -- Convert query to tsquery
  search_query := search.query_to_tsquery(p_query);
  
  -- Return early if empty query
  IF search_query IS NULL THEN
    RETURN;
  END IF;
  
  -- Start with the base search vector condition
  where_clauses := ARRAY['p.search_vector @@ $1'];
  
  -- Add graduation year filter if specified
  IF p_graduation_year IS NOT NULL THEN
    where_clauses := array_append(where_clauses, 'p.graduation_year = ' || p_graduation_year::TEXT);
  END IF;
  
  -- Add post grad status filter if specified
  IF p_post_grad_status IS NOT NULL THEN
    where_clauses := array_append(where_clauses, 'p.post_grad_status = ' || quote_literal(p_post_grad_status));
  END IF;
  
  -- Construct the WHERE clause
  where_clause := array_to_string(where_clauses, ' AND ');
  
  -- Execute dynamic query for people search
  RETURN QUERY EXECUTE '
    SELECT 
      p.id,
      p.first_name,
      p.last_name,
      p.email,
      p.graduation_year,
      p.post_grad_status,
      ts_rank(p.search_vector, $1) AS search_rank
    FROM people p
    WHERE ' || where_clause || '
    ORDER BY search_rank DESC, p.last_name, p.first_name
    LIMIT $2
    OFFSET $3'
  USING search_query, p_limit, p_offset;
END;
$_$;


ALTER FUNCTION "search"."search_people"("p_query" "text", "p_graduation_year" integer, "p_post_grad_status" "text", "p_limit" integer, "p_offset" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "search"."search_people"("p_query" "text", "p_graduation_year" integer, "p_post_grad_status" "text", "p_limit" integer, "p_offset" integer) IS 'Specialized search function for finding people with optional graduation year and status filtering';



CREATE OR REPLACE FUNCTION "search"."update_person_search_vector"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.search_vector := search.generate_search_vector(
    -- Title (name) has highest weight
    NEW.first_name || ' ' || NEW.last_name,
    
    -- Description - education/employment details have medium weight
    COALESCE(NEW.post_grad_status, '') || ' ' || COALESCE(NEW.college_attending, '') || ' ' || COALESCE(NEW.employment_status, ''),
    
    -- Tags - graduation year as an array
    ARRAY[COALESCE(NEW.graduation_year::text, ''), COALESCE(NEW.post_grad_status, '')],
    
    -- Additional text (lowest weight)
    NEW.email || ' ' || COALESCE(NEW.phone, '')
  );
  RETURN NEW;
END;
$$;


ALTER FUNCTION "search"."update_person_search_vector"() OWNER TO "postgres";


CREATE TEXT SEARCH CONFIGURATION "search"."multilingual" (
    PARSER = "pg_catalog"."default" );

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "asciiword" WITH "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "word" WITH "public"."unaccent", "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "numword" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "email" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "url" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "host" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "sfloat" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "version" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "hword_numpart" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "hword_part" WITH "public"."unaccent", "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "hword_asciipart" WITH "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "numhword" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "asciihword" WITH "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "hword" WITH "public"."unaccent", "english_stem";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "url_path" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "file" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "float" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "int" WITH "simple";

ALTER TEXT SEARCH CONFIGURATION "search"."multilingual"
    ADD MAPPING FOR "uint" WITH "simple";


ALTER TEXT SEARCH CONFIGURATION "search"."multilingual" OWNER TO "postgres";




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_in"("cstring") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_out"("public"."gtrgm") TO "service_role";
































































































































































































GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_query_trgm"("text", "internal", smallint, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_extract_value_trgm"("text", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_consistent"("internal", smallint, "text", integer, "internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gin_trgm_triconsistent"("internal", smallint, "text", integer, "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_compress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_consistent"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_decompress"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_distance"("internal", "text", smallint, "oid", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_options"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_penalty"("internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_picksplit"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_same"("public"."gtrgm", "public"."gtrgm", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."gtrgm_union"("internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "postgres";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "anon";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_limit"(real) TO "service_role";



GRANT ALL ON FUNCTION "public"."show_limit"() TO "postgres";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "anon";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_limit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."show_trgm"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_dist"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."strict_word_similarity_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent"("regdictionary", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_init"("internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "postgres";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "anon";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "authenticated";
GRANT ALL ON FUNCTION "public"."unaccent_lexize"("internal", "internal", "internal", "internal") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_commutator_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_dist_op"("text", "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "postgres";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "anon";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."word_similarity_op"("text", "text") TO "service_role";






























ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
