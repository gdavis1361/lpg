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
          is_current: boolean | null
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
          is_current?: boolean | null
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
          is_current?: boolean | null
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
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "affiliations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
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
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_home_activity_id_fkey"
            columns: ["home_activity_id"]
            isOneToOne: false
            referencedRelation: "activity_groups"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "cross_group_participations_visited_activity_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "activity_groups"
            referencedColumns: ["id"]
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
        }
        Insert: {
          attended?: boolean | null
          created_at?: string
          id?: string
          interaction_id: string
          person_id: string
        }
        Update: {
          attended?: boolean | null
          created_at?: string
          id?: string
          interaction_id?: string
          person_id?: string
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
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      interaction_tags: {
        Row: {
          created_at: string
          id: string
          interaction_id: string
          tag_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          interaction_id: string
          tag_id: string
        }
        Update: {
          created_at?: string
          id?: string
          interaction_id?: string
          tag_id?: string
        }
        Relationships: [
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
          duration_minutes: number | null
          id: string
          interaction_type: string
          is_planned: boolean | null
          location: string | null
          metadata: Json | null
          notes: string | null
          occurred_at: string
          quality_score: number | null
          reciprocity_score: number | null
          scheduled_at: string | null
          sentiment_score: number | null
          status: string | null
          title: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          interaction_type: string
          is_planned?: boolean | null
          location?: string | null
          metadata?: Json | null
          notes?: string | null
          occurred_at: string
          quality_score?: number | null
          reciprocity_score?: number | null
          scheduled_at?: string | null
          sentiment_score?: number | null
          status?: string | null
          title: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          description?: string | null
          duration_minutes?: number | null
          id?: string
          interaction_type?: string
          is_planned?: boolean | null
          location?: string | null
          metadata?: Json | null
          notes?: string | null
          occurred_at?: string
          quality_score?: number | null
          reciprocity_score?: number | null
          scheduled_at?: string | null
          sentiment_score?: number | null
          status?: string | null
          title?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "interactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
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
      organizations: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          type: string | null
          updated_at: string
          website: string | null
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          type?: string | null
          updated_at?: string
          website?: string | null
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          type?: string | null
          updated_at?: string
          website?: string | null
        }
        Relationships: []
      }
      people: {
        Row: {
          address_line1: string | null
          address_line2: string | null
          auth_id: string | null
          avatar_url: string | null
          bio: string | null
          city: string | null
          country: string | null
          created_at: string
          email: string
          first_name: string
          id: string
          last_active_at: string | null
          last_name: string
          metadata: Json | null
          phone: string | null
          postal_code: string | null
          state: string | null
          status: string
          updated_at: string
        }
        Insert: {
          address_line1?: string | null
          address_line2?: string | null
          auth_id?: string | null
          avatar_url?: string | null
          bio?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          email: string
          first_name: string
          id?: string
          last_active_at?: string | null
          last_name: string
          metadata?: Json | null
          phone?: string | null
          postal_code?: string | null
          state?: string | null
          status?: string
          updated_at?: string
        }
        Update: {
          address_line1?: string | null
          address_line2?: string | null
          auth_id?: string | null
          avatar_url?: string | null
          bio?: string | null
          city?: string | null
          country?: string | null
          created_at?: string
          email?: string
          first_name?: string
          id?: string
          last_active_at?: string | null
          last_name?: string
          metadata?: Json | null
          phone?: string | null
          postal_code?: string | null
          state?: string | null
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      people_roles: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          end_date: string | null
          id: string
          notes: string | null
          person_id: string
          primary_role: boolean | null
          role_id: string
          start_date: string | null
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          end_date?: string | null
          id?: string
          notes?: string | null
          person_id: string
          primary_role?: boolean | null
          role_id: string
          start_date?: string | null
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          end_date?: string | null
          id?: string
          notes?: string | null
          person_id?: string
          primary_role?: boolean | null
          role_id?: string
          start_date?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "people_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "people_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "people_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "people_roles_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
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
          id: string
          person_id: string
          tag_id: string
        }
        Insert: {
          created_at?: string
          id?: string
          person_id: string
          tag_id: string
        }
        Update: {
          created_at?: string
          id?: string
          person_id?: string
          tag_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "people_tags_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
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
            foreignKeyName: "person_activities_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      relationship_milestones: {
        Row: {
          achieved_date: string
          created_at: string
          created_by: string | null
          evidence_description: string | null
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
          evidence_description?: string | null
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
          evidence_description?: string | null
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
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
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
            referencedRelation: "mentor_relationship_health_mv"
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
      relationship_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          id: string
          name: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          id?: string
          name: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          id?: string
          name?: string
        }
        Relationships: []
      }
      relationships: {
        Row: {
          created_at: string
          created_by: string | null
          end_date: string | null
          from_person_id: string
          id: string
          metadata: Json | null
          notes: string | null
          relationship_type: string
          relationship_type_id: string | null
          start_date: string | null
          status: string
          strength_score: number | null
          to_person_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          end_date?: string | null
          from_person_id: string
          id?: string
          metadata?: Json | null
          notes?: string | null
          relationship_type: string
          relationship_type_id?: string | null
          start_date?: string | null
          status?: string
          strength_score?: number | null
          to_person_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          end_date?: string | null
          from_person_id?: string
          id?: string
          metadata?: Json | null
          notes?: string | null
          relationship_type?: string
          relationship_type_id?: string | null
          start_date?: string | null
          status?: string
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
            foreignKeyName: "relationships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "relationships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_relationship_type_id_fkey"
            columns: ["relationship_type_id"]
            isOneToOne: false
            referencedRelation: "relationship_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
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
        }
        Insert: {
          category?: string | null
          color?: string | null
          created_at?: string
          id?: string
          name: string
        }
        Update: {
          category?: string | null
          color?: string | null
          created_at?: string
          id?: string
          name?: string
        }
        Relationships: []
      }
      timeline_event_queue: {
        Row: {
          created_at: string | null
          id: string
          operation: string
          payload: Json
          priority: number | null
          processed: boolean | null
          processing_completed_at: string | null
          processing_started_at: string | null
          record_id: string
          retry_count: number | null
          table_name: string
        }
        Insert: {
          created_at?: string | null
          id?: string
          operation: string
          payload: Json
          priority?: number | null
          processed?: boolean | null
          processing_completed_at?: string | null
          processing_started_at?: string | null
          record_id: string
          retry_count?: number | null
          table_name: string
        }
        Update: {
          created_at?: string | null
          id?: string
          operation?: string
          payload?: Json
          priority?: number | null
          processed?: boolean | null
          processing_completed_at?: string | null
          processing_started_at?: string | null
          record_id?: string
          retry_count?: number | null
          table_name?: string
        }
        Relationships: []
      }
      timeline_events: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "timeline_events_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "timeline_events_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "timeline_events_person_id_fkey"
            columns: ["person_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "timeline_events_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "mentor_relationship_health_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "timeline_events_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationship_strength_analytics_mv"
            referencedColumns: ["relationship_id"]
          },
          {
            foreignKeyName: "timeline_events_relationship_id_fkey"
            columns: ["relationship_id"]
            isOneToOne: false
            referencedRelation: "relationships"
            referencedColumns: ["id"]
          },
        ]
      }
      timeline_events_2024q1: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_2024q2: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_2024q3: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_2024q4: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_2025q1: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_future: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
      timeline_events_historical: {
        Row: {
          created_at: string
          event_date: string
          event_description: string | null
          event_title: string
          event_type: string
          id: string
          is_deleted: boolean | null
          payload: Json | null
          person_id: string | null
          relationship_id: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          event_date: string
          event_description?: string | null
          event_title: string
          event_type: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id: string
          source_entity_type: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          event_date?: string
          event_description?: string | null
          event_title?: string
          event_type?: string
          id?: string
          is_deleted?: boolean | null
          payload?: Json | null
          person_id?: string | null
          relationship_id?: string | null
          source_entity_id?: string
          source_entity_type?: string
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      brotherhood_visibility_mv: {
        Row: {
          first_name: string | null
          home_activity_category: string | null
          home_activity_id: string | null
          home_activity_name: string | null
          last_name: string | null
          person_id: string | null
          total_recognition_points: number | null
          visit_count: number | null
          visited_activity_category: string | null
          visited_activity_id: string | null
          visited_activity_name: string | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["person_id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["visited_activity_id"]
            isOneToOne: false
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      mentor_relationship_health_mv: {
        Row: {
          health_status: string | null
          interaction_count: number | null
          mentor_first_name: string | null
          mentor_id: string | null
          mentor_last_name: string | null
          milestones_achieved_count: number | null
          recent_avg_quality: number | null
          recent_interaction_count: number | null
          relationship_duration: unknown | null
          relationship_id: string | null
          required_milestones_achieved_count: number | null
          start_date: string | null
          student_first_name: string | null
          student_id: string | null
          student_last_name: string | null
          total_required_milestones_overall: number | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["mentor_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["student_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
      relationship_strength_analytics_mv: {
        Row: {
          avg_quality: number | null
          avg_reciprocity: number | null
          from_person_id: string | null
          interaction_count: number | null
          last_interaction_at: string | null
          relationship_id: string | null
          relationship_type: string | null
          strength_score: number | null
          time_since_last_interaction: unknown | null
          to_person_id: string | null
        }
        Relationships: [
          {
            foreignKeyName: "relationships_from_person_id_fkey"
            columns: ["from_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "relationships_to_person_id_fkey"
            columns: ["to_person_id"]
            isOneToOne: false
            referencedRelation: "brotherhood_visibility_mv"
            referencedColumns: ["home_activity_id"]
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
            referencedRelation: "people"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      gbt_bit_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_bool_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_bool_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_bpchar_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_bytea_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_cash_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_cash_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_date_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_date_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_enum_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_enum_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_float4_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_float4_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_float8_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_float8_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_inet_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int2_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int2_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int4_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int4_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int8_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_int8_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_intv_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_intv_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_intv_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_macad_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_macad_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_macad8_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_macad8_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_numeric_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_oid_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_oid_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_text_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_time_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_time_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_timetz_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_ts_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_ts_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_tstz_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_uuid_compress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_uuid_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_var_decompress: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbt_var_fetch: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey_var_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey_var_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey16_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey16_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey2_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey2_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey32_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey32_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey4_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey4_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey8_in: {
        Args: { "": unknown }
        Returns: unknown
      }
      gbtreekey8_out: {
        Args: { "": unknown }
        Returns: unknown
      }
      get_brotherhood_visibility: {
        Args: { p_user_id?: string }
        Returns: unknown[]
      }
      get_mentor_relationship_health: {
        Args: { p_user_id?: string }
        Returns: unknown[]
      }
      get_primary_activity_id: {
        Args: { p_person_id: string }
        Returns: string
      }
      get_relationship_strength: {
        Args: { p_user_id?: string }
        Returns: unknown[]
      }
      get_relationship_timeline: {
        Args: {
          p_relationship_id: string
          p_limit?: number
          p_offset?: number
          p_user_id?: string
        }
        Returns: {
          id: string
          event_type: string
          event_date: string
          event_title: string
          event_description: string
          source_entity_type: string
        }[]
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
      maintain_timeline_partitions: {
        Args: Record<PropertyKey, never>
        Returns: undefined
      }
      merge_timeline_event: {
        Args: {
          p_event_type: string
          p_event_date: string
          p_event_title: string
          p_event_description: string
          p_person_id: string
          p_relationship_id: string
          p_source_entity_type: string
          p_source_entity_id: string
          p_payload?: Json
        }
        Returns: string
      }
      merge_timeline_event_sql: {
        Args: {
          p_event_type: string
          p_event_date: string
          p_event_title: string
          p_event_description: string
          p_person_id: string
          p_relationship_id: string
          p_source_entity_type: string
          p_source_entity_id: string
          p_payload?: Json
        }
        Returns: string
      }
      process_timeline_event: {
        Args: { p_record_id: string }
        Returns: boolean
      }
      process_timeline_events_batch: {
        Args: { p_table_name?: string; p_limit?: number }
        Returns: number
      }
      record_cross_group_participation: {
        Args: {
          p_person_id: string
          p_visited_activity_id: string
          p_event_description?: string
          p_event_date?: string
          p_recognition_points?: number
        }
        Returns: string
      }
      refresh_analytics_views: {
        Args: { p_concurrently?: boolean }
        Returns: {
          view_name: string
          refresh_duration_ms: number
          refreshed_at: string
        }[]
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
      soft_delete_timeline_event: {
        Args: { p_source_entity_type: string; p_source_entity_id: string }
        Returns: undefined
      }
      soft_delete_timeline_event_sql: {
        Args: { p_source_entity_type: string; p_source_entity_id: string }
        Returns: undefined
      }
      unaccent: {
        Args: { "": string }
        Returns: string
      }
      unaccent_init: {
        Args: { "": unknown }
        Returns: unknown
      }
      update_user_claims: {
        Args: { user_auth_id: string }
        Returns: undefined
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
