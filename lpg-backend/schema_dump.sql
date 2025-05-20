

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


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."handle_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."affiliations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "person_id" "uuid" NOT NULL,
    "organization_id" "uuid" NOT NULL,
    "role" "text",
    "start_date" "date",
    "end_date" "date",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."affiliations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."interaction_participants" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "interaction_id" "uuid" NOT NULL,
    "person_id" "uuid" NOT NULL,
    "role" "text",
    "attended" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."interaction_participants" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."interaction_tags" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "interaction_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid"
);


ALTER TABLE "public"."interaction_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."interactions" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "interaction_type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "occurred_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "duration_minutes" integer,
    "location" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "follow_up_needed" boolean DEFAULT false,
    "follow_up_date" "date",
    "follow_up_notes" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."interactions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."organizations" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "type" "text",
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."organizations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."people" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "auth_id" "uuid",
    "first_name" "text" NOT NULL,
    "last_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone" "text",
    "avatar_url" "text",
    "bio" "text",
    "address_line1" "text",
    "address_line2" "text",
    "city" "text",
    "state" "text",
    "postal_code" "text",
    "country" "text" DEFAULT 'USA'::"text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_active_at" timestamp with time zone,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "people_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'archived'::"text"])))
);


ALTER TABLE "public"."people" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."people_roles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "person_id" "uuid" NOT NULL,
    "role_id" "uuid" NOT NULL,
    "assigned_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "assigned_by" "uuid",
    "primary_role" boolean DEFAULT false,
    "start_date" "date",
    "end_date" "date",
    "notes" "text"
);


ALTER TABLE "public"."people_roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."people_tags" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "person_id" "uuid" NOT NULL,
    "tag_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid"
);


ALTER TABLE "public"."people_tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."relationships" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "from_person_id" "uuid" NOT NULL,
    "to_person_id" "uuid" NOT NULL,
    "relationship_type" "text" NOT NULL,
    "start_date" "date" DEFAULT CURRENT_DATE,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid",
    "notes" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    CONSTRAINT "no_self_relationships" CHECK (("from_person_id" <> "to_person_id")),
    CONSTRAINT "relationships_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text", 'potential'::"text"])))
);


ALTER TABLE "public"."relationships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."roles" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "permissions" "jsonb" DEFAULT '{}'::"jsonb"
);


ALTER TABLE "public"."roles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."tags" (
    "id" "uuid" DEFAULT "extensions"."uuid_generate_v4"() NOT NULL,
    "name" "text" NOT NULL,
    "category" "text",
    "color" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."tags" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text" NOT NULL,
    "name" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."users" OWNER TO "postgres";


COMMENT ON TABLE "public"."users" IS 'Application users';



COMMENT ON COLUMN "public"."users"."id" IS 'Unique identifier for the user';



COMMENT ON COLUMN "public"."users"."email" IS 'User email address';



COMMENT ON COLUMN "public"."users"."name" IS 'User display name';



ALTER TABLE ONLY "public"."affiliations"
    ADD CONSTRAINT "affiliations_person_id_organization_id_role_key" UNIQUE ("person_id", "organization_id", "role");



ALTER TABLE ONLY "public"."affiliations"
    ADD CONSTRAINT "affiliations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."interaction_participants"
    ADD CONSTRAINT "interaction_participants_interaction_id_person_id_key" UNIQUE ("interaction_id", "person_id");



ALTER TABLE ONLY "public"."interaction_participants"
    ADD CONSTRAINT "interaction_participants_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."interaction_tags"
    ADD CONSTRAINT "interaction_tags_interaction_id_tag_id_key" UNIQUE ("interaction_id", "tag_id");



ALTER TABLE ONLY "public"."interaction_tags"
    ADD CONSTRAINT "interaction_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."interactions"
    ADD CONSTRAINT "interactions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."organizations"
    ADD CONSTRAINT "organizations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."people"
    ADD CONSTRAINT "people_auth_id_key" UNIQUE ("auth_id");



ALTER TABLE ONLY "public"."people"
    ADD CONSTRAINT "people_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."people"
    ADD CONSTRAINT "people_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."people_roles"
    ADD CONSTRAINT "people_roles_person_id_role_id_key" UNIQUE ("person_id", "role_id");



ALTER TABLE ONLY "public"."people_roles"
    ADD CONSTRAINT "people_roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."people_tags"
    ADD CONSTRAINT "people_tags_person_id_tag_id_key" UNIQUE ("person_id", "tag_id");



ALTER TABLE ONLY "public"."people_tags"
    ADD CONSTRAINT "people_tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "relationships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."roles"
    ADD CONSTRAINT "roles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."tags"
    ADD CONSTRAINT "tags_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "unique_active_relationship" UNIQUE ("from_person_id", "to_person_id", "relationship_type") DEFERRABLE;



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_interaction_participants_interaction" ON "public"."interaction_participants" USING "btree" ("interaction_id");



CREATE INDEX "idx_interaction_participants_person" ON "public"."interaction_participants" USING "btree" ("person_id");



CREATE INDEX "idx_interactions_occurred_at" ON "public"."interactions" USING "btree" ("occurred_at");



CREATE INDEX "idx_people_email" ON "public"."people" USING "btree" ("email");



CREATE INDEX "idx_people_last_name" ON "public"."people" USING "btree" ("last_name");



CREATE INDEX "idx_people_roles_person" ON "public"."people_roles" USING "btree" ("person_id");



CREATE INDEX "idx_people_roles_role" ON "public"."people_roles" USING "btree" ("role_id");



CREATE INDEX "idx_people_status" ON "public"."people" USING "btree" ("status");



CREATE INDEX "idx_relationships_from" ON "public"."relationships" USING "btree" ("from_person_id");



CREATE INDEX "idx_relationships_to" ON "public"."relationships" USING "btree" ("to_person_id");



CREATE INDEX "idx_tags_category" ON "public"."tags" USING "btree" ("category");



CREATE UNIQUE INDEX "unique_primary_role_per_person" ON "public"."people_roles" USING "btree" ("person_id") WHERE ("primary_role" IS TRUE);



CREATE OR REPLACE TRIGGER "set_interactions_updated_at" BEFORE UPDATE ON "public"."interactions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "set_people_updated_at" BEFORE UPDATE ON "public"."people" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "set_relationships_updated_at" BEFORE UPDATE ON "public"."relationships" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION "public"."handle_updated_at"();



ALTER TABLE ONLY "public"."affiliations"
    ADD CONSTRAINT "affiliations_organization_id_fkey" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."affiliations"
    ADD CONSTRAINT "affiliations_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."interaction_participants"
    ADD CONSTRAINT "interaction_participants_interaction_id_fkey" FOREIGN KEY ("interaction_id") REFERENCES "public"."interactions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."interaction_participants"
    ADD CONSTRAINT "interaction_participants_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."interaction_tags"
    ADD CONSTRAINT "interaction_tags_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."people"("id");



ALTER TABLE ONLY "public"."interaction_tags"
    ADD CONSTRAINT "interaction_tags_interaction_id_fkey" FOREIGN KEY ("interaction_id") REFERENCES "public"."interactions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."interaction_tags"
    ADD CONSTRAINT "interaction_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."interactions"
    ADD CONSTRAINT "interactions_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."people"("id");



ALTER TABLE ONLY "public"."people_roles"
    ADD CONSTRAINT "people_roles_assigned_by_fkey" FOREIGN KEY ("assigned_by") REFERENCES "public"."people"("id");



ALTER TABLE ONLY "public"."people_roles"
    ADD CONSTRAINT "people_roles_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."people_roles"
    ADD CONSTRAINT "people_roles_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."people_tags"
    ADD CONSTRAINT "people_tags_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."people"("id");



ALTER TABLE ONLY "public"."people_tags"
    ADD CONSTRAINT "people_tags_person_id_fkey" FOREIGN KEY ("person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."people_tags"
    ADD CONSTRAINT "people_tags_tag_id_fkey" FOREIGN KEY ("tag_id") REFERENCES "public"."tags"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "relationships_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."people"("id");



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "relationships_from_person_id_fkey" FOREIGN KEY ("from_person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."relationships"
    ADD CONSTRAINT "relationships_to_person_id_fkey" FOREIGN KEY ("to_person_id") REFERENCES "public"."people"("id") ON DELETE CASCADE;



CREATE POLICY "Affiliations view – authenticated" ON "public"."affiliations" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Interaction participants view – authenticated" ON "public"."interaction_participants" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Interaction-tags view – authenticated" ON "public"."interaction_tags" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Interactions view – authenticated" ON "public"."interactions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Organizations view – authenticated" ON "public"."organizations" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "People view – authenticated" ON "public"."people" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "People-roles view – authenticated" ON "public"."people_roles" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "People-tags view – authenticated" ON "public"."people_tags" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Relationships view – authenticated" ON "public"."relationships" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Tags view – authenticated" ON "public"."tags" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."affiliations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."interaction_participants" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."interaction_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."interactions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."organizations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."people" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."people_roles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."people_tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."relationships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."tags" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";


















GRANT ALL ON TABLE "public"."affiliations" TO "anon";
GRANT ALL ON TABLE "public"."affiliations" TO "authenticated";
GRANT ALL ON TABLE "public"."affiliations" TO "service_role";



GRANT ALL ON TABLE "public"."interaction_participants" TO "anon";
GRANT ALL ON TABLE "public"."interaction_participants" TO "authenticated";
GRANT ALL ON TABLE "public"."interaction_participants" TO "service_role";



GRANT ALL ON TABLE "public"."interaction_tags" TO "anon";
GRANT ALL ON TABLE "public"."interaction_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."interaction_tags" TO "service_role";



GRANT ALL ON TABLE "public"."interactions" TO "anon";
GRANT ALL ON TABLE "public"."interactions" TO "authenticated";
GRANT ALL ON TABLE "public"."interactions" TO "service_role";



GRANT ALL ON TABLE "public"."organizations" TO "anon";
GRANT ALL ON TABLE "public"."organizations" TO "authenticated";
GRANT ALL ON TABLE "public"."organizations" TO "service_role";



GRANT ALL ON TABLE "public"."people" TO "anon";
GRANT ALL ON TABLE "public"."people" TO "authenticated";
GRANT ALL ON TABLE "public"."people" TO "service_role";



GRANT ALL ON TABLE "public"."people_roles" TO "anon";
GRANT ALL ON TABLE "public"."people_roles" TO "authenticated";
GRANT ALL ON TABLE "public"."people_roles" TO "service_role";



GRANT ALL ON TABLE "public"."people_tags" TO "anon";
GRANT ALL ON TABLE "public"."people_tags" TO "authenticated";
GRANT ALL ON TABLE "public"."people_tags" TO "service_role";



GRANT ALL ON TABLE "public"."relationships" TO "anon";
GRANT ALL ON TABLE "public"."relationships" TO "authenticated";
GRANT ALL ON TABLE "public"."relationships" TO "service_role";



GRANT ALL ON TABLE "public"."roles" TO "anon";
GRANT ALL ON TABLE "public"."roles" TO "authenticated";
GRANT ALL ON TABLE "public"."roles" TO "service_role";



GRANT ALL ON TABLE "public"."tags" TO "anon";
GRANT ALL ON TABLE "public"."tags" TO "authenticated";
GRANT ALL ON TABLE "public"."tags" TO "service_role";



GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";









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
