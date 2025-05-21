// Type definitions for generated entities

// Organizations
export interface Organization {
  id: string;
  name: string;
  description: string | null;
  type: string | null;
  metadata: Record<string, any> | null;
  created_at: string;
  updated_at: string;
}

// Activity Groups
export interface ActivityGroup {
  id: string;
  name: string;
  description: string | null;
  category: string;
  created_at: string;
}

// People
export interface Person {
  id: string;
  auth_id: string | null;
  first_name: string;
  last_name: string;
  email: string | null;
  phone: string | null;
  birthdate: string | null;
  graduation_year: number | null;
  avatar_url: string | null;
  metadata: Record<string, any> | null;
  address: Record<string, any> | null;
  created_at: string;
  updated_at: string;
  employment_status: string | null;
  post_grad_status: string | null;
  college_attending: string | null;
  last_checkin_date: string | null;
}

// Roles
export interface Role {
  id: string;
  name: string;
  description: string | null;
  permissions: Record<string, any> | null;
  created_at: string;
}

// People Roles
export interface PersonRole {
  id: string;
  person_id: string;
  role_id: string;
  primary_role: boolean | null;
  created_at: string;
}

// Tags
export interface Tag {
  id: string;
  name: string;
  category: string | null;
  color: string | null;
  created_at: string;
  updated_at: string;
}

// People Tags
export interface PersonTag {
  id: string;
  person_id: string;
  tag_id: string;
  created_by: string | null;
  created_at: string;
}

// Person Activities
export interface PersonActivity {
  id: string;
  person_id: string;
  activity_group_id: string;
  primary_activity: boolean | null;
  role: string | null;
  joined_at: string;
  created_at: string;
  updated_at: string;
}

// Relationships
export interface Relationship {
  id: string;
  from_person_id: string;
  to_person_id: string;
  relationship_type_id: string | null;
  status: string | null;
  start_date: string | null;
  end_date: string | null;
  strength_score: number | null;
  created_at: string;
  updated_at: string;
}

// Mentor Milestones
export interface MentorMilestone {
  id: string;
  name: string;
  description: string | null;
  is_required: boolean | null;
  typical_year: number | null;
  created_at: string;
  updated_at: string;
}

// Relationship Milestones
export interface RelationshipMilestone {
  id: string;
  relationship_id: string;
  milestone_id: string;
  achieved_date: string;
  notes: string | null;
  evidence_url: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

// Interactions
export interface Interaction {
  id: string;
  title: string;
  description: string | null;
  type: string;
  start_time: string;
  end_time: string | null;
  location: string | null;
  is_planned: boolean | null;
  status: string | null;
  quality_score: number | null;
  reciprocity_score: number | null;
  sentiment_score: number | null;
  metadata: Record<string, any> | null;
  scheduled_at: string | null;
  created_by: string | null;
  updated_by: string | null;
  created_at: string;
  updated_at: string;
}

// Interaction Participants
export interface InteractionParticipant {
  id: string;
  interaction_id: string;
  person_id: string;
  role: string | null;
  attended: boolean | null;
  created_at: string;
} 