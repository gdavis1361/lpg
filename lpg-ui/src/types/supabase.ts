export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  public: {
    Tables: {
      activity_groups: {
        Row: {
          category: string
          created_at: string
          description: string | null
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          category: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          category?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      affiliations: {
        Row: {
          created_at: string
          end_date: string | null
          id: string
          is_primary: boolean | null
          organization_id: string
          person_id: string
          role: string | null
          start_date: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          end_date?: string | null
          id?: string
          is_primary?: boolean | null
          organization_id: string
          person_id: string
          role?: string | null
          start_date?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          end_date?: string | null
          id?: string
          is_primary?: boolean | null
          organization_id?: string
          person_id?: string
          role?: string | null
          start_date?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "affiliations_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["organization_id"]
          },
          {
            foreignKeyName: "affiliations_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      alumni_checkins: {
        Row: {
          alumni_id: string
          check_date: string
          check_method: string
          created_at: string
          followup_notes: string | null
          id: string
          needs_followup: boolean | null
          performed_by: string | null
          status_update: string | null
          updated_at: string
          wellbeing_score: number | null
        }
        Insert: {
          alumni_id: string
          check_date?: string
          check_method: string
          created_at?: string
          followup_notes?: string | null
          id?: string
          needs_followup?: boolean | null
          performed_by?: string | null
          status_update?: string | null
          updated_at?: string
          wellbeing_score?: number | null
        }
        Update: {
          alumni_id?: string
          check_date?: string
          check_method?: string
          created_at?: string
          followup_notes?: string | null
          id?: string
          needs_followup?: boolean | null
          performed_by?: string | null
          status_update?: string | null
          updated_at?: string
          wellbeing_score?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_alumni_id_fkey"
            columns: ["alumni_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "alumni_checkins_performed_by_fkey"
            columns: ["performed_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      cross_group_participations: {
        Row: {
          created_at: string
          created_by: string | null
          event_date: string
          event_description: string | null
          home_activity_id: string
          id: string
          person_id: string
          recognition_points: number | null
          updated_at: string
          visited_activity_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          event_date?: string
          event_description?: string | null
          home_activity_id: string
          id?: string
          person_id: string
          recognition_points?: number | null
          updated_at?: string
          visited_activity_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          event_date?: string
          event_description?: string | null
          home_activity_id?: string
          id?: string
          person_id?: string
          recognition_points?: number | null
          updated_at?: string
          visited_activity_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "activity_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["visited_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["visited_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "activity_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["visited_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["visited_activity_id"]
          },
        ]
      }
      interaction_participants: {
        Row: {
          attended: boolean | null
          created_at: string
          id: string
          interaction_id: string
          person_id: string
          role: string | null
        }
        Insert: {
          attended?: boolean | null
          created_at?: string
          id?: string
          interaction_id: string
          person_id: string
          role?: string | null
        }
        Update: {
          attended?: boolean | null
          created_at?: string
          id?: string
          interaction_id?: string
          person_id?: string
          role?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "interaction_participants_interaction_id_fkey"
            columns: ["interaction_id"]
            isOneToOne: false
            referencedRelation: "interactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_participants_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      interaction_tags: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          interaction_id: string
          tag_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          interaction_id: string
          tag_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          interaction_id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interaction_tags_interaction_id_fkey"
            columns: ["interaction_id"]
            isOneToOne: false
            referencedRelation: "interactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interaction_tags_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "tags"
            referencedColumns: ["id"]
          },
        ]
      }
      interactions: {
        Row: {
          created_at: string
          created_by: string | null
          description: string | null
          end_time: string | null
          id: string
          is_planned: boolean | null
          location: string | null
          metadata: Json | null
          quality_score: number | null
          reciprocity_score: number | null
          scheduled_at: string | null
          sentiment_score: number | null
          start_time: string
          status: string | null
          title: string
          type: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          end_time?: string | null
          id?: string
          is_planned?: boolean | null
          location?: string | null
          metadata?: Json | null
          quality_score?: number | null
          reciprocity_score?: number | null
          scheduled_at?: string | null
          sentiment_score?: number | null
          start_time: string
          status?: string | null
          title: string
          type: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          end_time?: string | null
          id?: string
          is_planned?: boolean | null
          location?: string | null
          metadata?: Json | null
          quality_score?: number | null
          reciprocity_score?: number | null
          scheduled_at?: string | null
          sentiment_score?: number | null
          start_time?: string
          status?: string | null
          title?: string
          type?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "interactions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      mentor_milestones: {
        Row: {
          created_at: string
          description: string | null
          id: string
          is_required: boolean | null
          name: string
          typical_year: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          is_required?: boolean | null
          name: string
          typical_year?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          is_required?: boolean | null
          name?: string
          typical_year?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      organization_types: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
      organizations: {
        Row: {
          created_at: string
          description: string | null
          id: string
          metadata: Json | null
          name: string
          type: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          metadata?: Json | null
          name: string
          type?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          metadata?: Json | null
          name?: string
          type?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      people: {
        Row: {
          address: Json | null
          auth_id: string | null
          avatar_url: string | null
          birthdate: string | null
          college_attending: string | null
          created_at: string
          email: string | null
          employment_status: string | null
          first_name: string
          graduation_year: number | null
          id: string
          last_checkin_date: string | null
          last_name: string
          metadata: Json | null
          phone: string | null
          post_grad_status: string | null
          updated_at: string
        }
        Insert: {
          address?: Json | null
          auth_id?: string | null
          avatar_url?: string | null
          birthdate?: string | null
          college_attending?: string | null
          created_at?: string
          email?: string | null
          employment_status?: string | null
          first_name: string
          graduation_year?: number | null
          id?: string
          last_checkin_date?: string | null
          last_name: string
          metadata?: Json | null
          phone?: string | null
          post_grad_status?: string | null
          updated_at?: string
        }
        Update: {
          address?: Json | null
          auth_id?: string | null
          avatar_url?: string | null
          birthdate?: string | null
          college_attending?: string | null
          created_at?: string
          email?: string | null
          employment_status?: string | null
          first_name?: string
          graduation_year?: number | null
          id?: string
          last_checkin_date?: string | null
          last_name?: string
          metadata?: Json | null
          phone?: string | null
          post_grad_status?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      people_roles: {
        Row: {
          created_at: string
          id: string
          person_id: string
          primary_role: boolean | null
          role_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          person_id: string
          primary_role?: boolean | null
          role_id: string
        }
        Update: {
          created_at?: string
          id?: string
          person_id?: string
          primary_role?: boolean | null
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_roles_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      people_tags: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          person_id: string
          tag_id: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          person_id: string
          tag_id: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          person_id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_tags_tag_id_fkey"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "tags"
            referencedColumns: ["id"]
          },
        ]
      }
      permissions: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      person_activities: {
        Row: {
          activity_group_id: string
          created_at: string
          id: string
          joined_at: string
          person_id: string
          primary_activity: boolean | null
          role: string | null
          updated_at: string
        }
        Insert: {
          activity_group_id: string
          created_at?: string
          id?: string
          joined_at?: string
          person_id: string
          primary_activity?: boolean | null
          role?: string | null
          updated_at?: string
        }
        Update: {
          activity_group_id?: string
          created_at?: string
          id?: string
          joined_at?: string
          person_id?: string
          primary_activity?: boolean | null
          role?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "person_activities_activity_group_id_fkey"
            columns: ["activity_group_id"]
            isOneToOne: false
            referencedRelation: "activity_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_activities_activity_group_id_fkey"
            columns: ["activity_group_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "person_activities_activity_group_id_fkey"
            columns: ["activity_group_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["visited_activity_id"]
          },
          {
            foreignKeyName: "person_activities_activity_group_id_fkey"
            columns: ["activity_group_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "person_activities_activity_group_id_fkey"
            columns: ["activity_group_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["visited_activity_id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_milestones: {
        Row: {
          achieved_date: string
          created_at: string
          created_by: string | null
          evidence_url: string | null
          id: string
          milestone_id: string
          notes: string | null
          relationship_id: string
          updated_at: string
        }
        Insert: {
          achieved_date?: string
          created_at?: string
          created_by?: string | null
          evidence_url?: string | null
          id?: string
          milestone_id: string
          notes?: string | null
          relationship_id: string
          updated_at?: string
        }
        Update: {
          achieved_date?: string
          created_at?: string
          created_by?: string | null
          evidence_url?: string | null
          id?: string
          milestone_id?: string
          notes?: string | null
          relationship_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_milestones_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_milestones_milestone_id_fkey"
            columns: ["milestone_id"]
            isOneToOne: false
            referencedRelation: "mentor_milestones"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "mentor_relationship_health"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "mentor_relationship_health_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_pair_timeline"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_strength_analytics"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_strength_analytics_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_milestones_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationships"
            referencedColumns: ["id"]
          },
        ]
      }
      relationship_pattern_detections: {
        Row: {
          confidence_score: number | null
          created_at: string
          detected_at: string
          detection_data: Json | null
          id: string
          pattern_id: string
          person_id: string | null
          relationship_id: string | null
          resolution_notes: string | null
          resolved_by: string | null
          status: string
          updated_at: string
        }
        Insert: {
          confidence_score?: number | null
          created_at?: string
          detected_at?: string
          detection_data?: Json | null
          id?: string
          pattern_id: string
          person_id?: string | null
          relationship_id?: string | null
          resolution_notes?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          confidence_score?: number | null
          created_at?: string
          detected_at?: string
          detection_data?: Json | null
          id?: string
          pattern_id?: string
          person_id?: string | null
          relationship_id?: string | null
          resolution_notes?: string | null
          resolved_by?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "relationship_pattern_detections_pattern_id_fkey"
            columns: ["pattern_id"]
            isOneToOne: false
            referencedRelation: "relationship_patterns"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "mentor_relationship_health"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "mentor_relationship_health_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_pair_timeline"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_strength_analytics"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_strength_analytics_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationships"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_pattern_detections_resolved_by_fkey"
            columns: ["resolved_by"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_patterns: {
        Row: {
          alert_level: string
          created_at: string
          description: string | null
          detection_threshold: Json | null
          id: string
          pattern_type: string
          updated_at: string
        }
        Insert: {
          alert_level?: string
          created_at?: string
          description?: string | null
          detection_threshold?: Json | null
          id?: string
          pattern_type: string
          updated_at?: string
        }
        Update: {
          alert_level?: string
          created_at?: string
          description?: string | null
          detection_threshold?: Json | null
          id?: string
          pattern_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      relationship_suggestions: {
        Row: {
          created_at: string
          detection_id: string | null
          expires_at: string | null
          feedback: string | null
          feedback_rating: number | null
          for_person_id: string
          id: string
          status: string
          suggestion_text: string
          suggestion_type: string
          target_person_id: string | null
          updated_at: string
          urgency: number | null
        }
        Insert: {
          created_at?: string
          detection_id?: string | null
          expires_at?: string | null
          feedback?: string | null
          feedback_rating?: number | null
          for_person_id: string
          id?: string
          status?: string
          suggestion_text: string
          suggestion_type: string
          target_person_id?: string | null
          updated_at?: string
          urgency?: number | null
        }
        Update: {
          created_at?: string
          detection_id?: string | null
          expires_at?: string | null
          feedback?: string | null
          feedback_rating?: number | null
          for_person_id?: string
          id?: string
          status?: string
          suggestion_text?: string
          suggestion_type?: string
          target_person_id?: string | null
          updated_at?: string
          urgency?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "relationship_suggestions_detection_id_fkey"
            columns: ["detection_id"]
            isOneToOne: false
            referencedRelation: "relationship_pattern_detections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_for_person_id_fkey"
            columns: ["for_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationship_suggestions_target_person_id_fkey"
            columns: ["target_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          name: string | null
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string | null
        }
        Relationships: []
      }
      relationships: {
        Row: {
          created_at: string
          end_date: string | null
          from_person_id: string
          id: string
          relationship_type_id: string | null
          status: string | null
          strength_score: number | null
          to_person_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          end_date?: string | null
          from_person_id: string
          id?: string
          relationship_type_id?: string | null
          status?: string | null
          strength_score?: number | null
          to_person_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          end_date?: string | null
          from_person_id?: string
          id?: string
          relationship_type_id?: string | null
          status?: string | null
          strength_score?: number | null
          to_person_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_relationship_type"
            columns: ["relationship_type_id"]
            isOneToOne: false
            referencedRelation: "relationship_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          created_at: string
          id: string
          permission_id: string
          role_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          permission_id: string
          role_id: string
        }
        Update: {
          created_at?: string
          id?: string
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "role_permissions_permission_id_fkey"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_role_id_fkey"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          permissions: Json | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          permissions?: Json | null
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          permissions?: Json | null
        }
        Relationships: []
      }
      tags: {
        Row: {
          category: string | null
          color: string | null
          created_at: string
          id: string
          name: string
          updated_at: string
        }
        Insert: {
          category?: string | null
          color?: string | null
          created_at?: string
          id?: string
          name: string
          updated_at?: string
        }
        Update: {
          category?: string | null
          color?: string | null
          created_at?: string
          id?: string
          name?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      alumni_risk_assessment: {
        Row: {
          college_attending: string | null
          days_since_checkin: number | null
          employment_status: string | null
          first_name: string | null
          graduation_year: number | null
          id: string | null
          last_checkin_date: string | null
          last_name: string | null
          last_wellbeing_score: number | null
          post_grad_status: string | null
          risk_level: string | null
          total_checkins: number | null
        }
        Relationships: []
      }
      alumni_risk_assessment_mv: {
        Row: {
          college_attending: string | null
          days_since_checkin: number | null
          employment_status: string | null
          first_name: string | null
          graduation_year: number | null
          id: string | null
          last_checkin_date: string | null
          last_name: string | null
          last_wellbeing_score: number | null
          post_grad_status: string | null
          risk_level: string | null
          total_checkins: number | null
        }
        Relationships: []
      }
      brotherhood_visibility: {
        Row: {
          first_name: string | null
          home_activity_category: string | null
          home_activity_id: string | null
          home_activity_name: string | null
          last_name: string | null
          person_id: string | null
          total_points: number | null
          visit_count: number | null
          visited_activity_category: string | null
          visited_activity_id: string | null
          visited_activity_name: string | null
        }
        Relationships: []
      }
      brotherhood_visibility_mv: {
        Row: {
          first_name: string | null
          home_activity_category: string | null
          home_activity_id: string | null
          home_activity_name: string | null
          last_name: string | null
          person_id: string | null
          total_points: number | null
          visit_count: number | null
          visited_activity_category: string | null
          visited_activity_id: string | null
          visited_activity_name: string | null
        }
        Relationships: []
      }
      mentor_relationship_health: {
        Row: {
          health_status: string | null
          mentor_first_name: string | null
          mentor_id: string | null
          mentor_last_name: string | null
          milestones_achieved: number | null
          recent_interactions: number | null
          relationship_id: string | null
          relationship_years: number | null
          required_milestones: number | null
          required_milestones_achieved: number | null
          start_date: string | null
          student_first_name: string | null
          student_id: string | null
          student_last_name: string | null
          total_interactions: number | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      mentor_relationship_health_mv: {
        Row: {
          health_status: string | null
          mentor_first_name: string | null
          mentor_id: string | null
          mentor_last_name: string | null
          milestones_achieved: number | null
          recent_interactions: number | null
          relationship_id: string | null
          relationship_years: number | null
          required_milestones: number | null
          required_milestones_achieved: number | null
          start_date: string | null
          student_first_name: string | null
          student_id: string | null
          student_last_name: string | null
          total_interactions: number | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      organization_members: {
        Row: {
          email: string | null
          end_date: string | null
          first_name: string | null
          is_primary: boolean | null
          last_name: string | null
          organization_id: string | null
          organization_name: string | null
          person_id: string | null
          role: string | null
          start_date: string | null
        }
        Relationships: []
      }
      person_details: {
        Row: {
          address: Json | null
          avatar_url: string | null
          birthdate: string | null
          created_at: string | null
          email: string | null
          first_name: string | null
          id: string | null
          last_name: string | null
          metadata: Json | null
          organizations: Json[] | null
          phone: string | null
          roles: string[] | null
          tags: string[] | null
          updated_at: string | null
        }
        Relationships: []
      }
      person_relationship_timeline: {
        Row: {
          created_at: string | null
          event_date: string | null
          event_description: string | null
          event_title: string | null
          event_type: string | null
          first_name: string | null
          last_name: string | null
          milestone_id: string | null
          person_id: string | null
          relationship_id: string | null
          source_id: string | null
        }
        Relationships: []
      }
      relationship_pair_timeline: {
        Row: {
          created_at: string | null
          event_date: string | null
          event_description: string | null
          event_title: string | null
          event_type: string | null
          from_person_id: string | null
          from_person_name: string | null
          relationship_id: string | null
          source_id: string | null
          to_person_id: string | null
          to_person_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_strength_analytics: {
        Row: {
          avg_quality: number | null
          avg_reciprocity: number | null
          from_person_id: string | null
          interaction_count: number | null
          last_interaction: string | null
          relationship_id: string | null
          relationship_type_id: string | null
          strength_score: number | null
          time_since_last_interaction: unknown | null
          to_person_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_relationship_type"
            columns: ["relationship_type_id"]
            isOneToOne: false
            referencedRelation: "relationship_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_strength_analytics_mv: {
        Row: {
          avg_quality: number | null
          avg_reciprocity: number | null
          from_person_id: string | null
          interaction_count: number | null
          last_interaction: string | null
          relationship_id: string | null
          relationship_type_id: string | null
          strength_score: number | null
          time_since_last_interaction: unknown | null
          to_person_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_relationship_type"
            columns: ["relationship_type_id"]
            isOneToOne: false
            referencedRelation: "relationship_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "alumni_risk_assessment_mv"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "organization_members"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_details"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "person_relationship_timeline"
            referencedColumns: ["person_id"]
          },
        ]
      }
      relationship_timeline_events: {
        Row: {
          created_at: string | null
          event_date: string | null
          event_description: string | null
          event_title: string | null
          event_type: string | null
          id: string | null
          milestone_id: string | null
          person_id: string | null
          relationship_id: string | null
          source_id: string | null
        }
        Relationships: []
      }
    }
    Functions: {
      check_duplicate_active_relationships: {
        Args: Record<PropertyKey, never>
        Returns: {
          duplicate_group_count: number
        }[]
      }
      check_relationship_permission: {
        Args: { permission_type: string; target_id?: string }
        Returns: boolean
      }
      check_unmapped_relationship_types: {
        Args: Record<PropertyKey, never>
        Returns: {
          unmapped_count: number
          sample_types: string
        }[]
      }
      current_environment: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      generate_relationship_suggestions: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      get_student_role_id: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      gtrgm_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gtrgm_options: {
        Args: { "": unknown }
        Returns: undefined
      }
      gtrgm_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      has_permission: {
        Args: { permission_name: string }
        Returns: boolean
      }
      is_owner: {
        Args: { auth_id: string }
        Returns: boolean
      }
      refresh_materialized_views: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      set_limit: {
        Args: { "": number }
        Returns: number
      }
      show_limit: {
        Args: Record<PropertyKey, never>
        Returns: number
      }
      show_trgm: {
        Args: { "": string }
        Returns: string[]
      }
      test_branch_workflow: {
        Args: Record<PropertyKey, never>
        Returns: string
      }
      update_relationship_strength_scores: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      update_user_claims: {
        Args: { user_auth_id: string }
        Returns: undefined
      }
      validate_migration_safety: {
        Args: Record<PropertyKey, never>
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DefaultSchema = Database[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? (Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      Database[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof Database },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof Database },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof Database }
  ? Database[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof Database },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof Database
  }
    ? keyof Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends { schema: keyof Database }
  ? Database[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
