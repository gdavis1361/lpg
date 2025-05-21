import { createServerSupabaseClient } from '../supabase-server';
import { Database } from '../../types/supabase';

type Tables = Database['public']['Tables'];

/**
 * Get a list of people with pagination
 */
export async function getPeople(page = 1, pageSize = 10) {
  const supabase = createServerSupabaseClient();
  const start = (page - 1) * pageSize;
  
  return await supabase
    .from('people')
    .select('*')
    .range(start, start + pageSize - 1)
    .order('last_name', { ascending: true });
}

/**
 * Get a person by ID
 */
export async function getPersonById(id: string) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('people')
    .select(`
      *,
      affiliations (
        *,
        organization: organizations (*)
      ),
      people_roles (
        *,
        role: roles (*)
      ),
      people_tags (
        *,
        tag: tags (*)
      )
    `)
    .eq('id', id)
    .single();
}

/**
 * Get relationships for a person
 */
export async function getPersonRelationships(personId: string) {
  const supabase = createServerSupabaseClient();
  
  // Get relationships where the person is either mentor or student
  const mentorResult = await supabase
    .from('relationships')
    .select('*, student:student_id(*), relationship_type:relationship_type_id(*)')
    .eq('mentor_id', personId);
  
  const studentResult = await supabase
    .from('relationships')
    .select('*, mentor:mentor_id(*), relationship_type:relationship_type_id(*)')
    .eq('student_id', personId);
  
  return {
    asMentor: mentorResult,
    asStudent: studentResult
  };
}

/**
 * Get timeline events for a relationship
 */
export async function getRelationshipTimeline(relationshipId: string) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('person_relationship_timeline')
    .select('*')
    .eq('relationship_id', relationshipId)
    .order('event_date', { ascending: false });
}

/**
 * Get interactions involving a person
 */
export async function getPersonInteractions(personId: string, limit = 10) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('interactions')
    .select(`
      *,
      participants: interaction_participants!inner (*)
    `)
    .eq('interaction_participants.person_id', personId)
    .order('start_time', { ascending: false })
    .limit(limit);
}

/**
 * Create a new person
 */
export async function createPerson(personData: Tables['people']['Insert']) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('people')
    .insert(personData)
    .select()
    .single();
}

/**
 * Update a person
 */
export async function updatePerson(id: string, personData: Tables['people']['Update']) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('people')
    .update(personData)
    .eq('id', id)
    .select()
    .single();
}

/**
 * Create a new relationship
 */
export async function createRelationship(relationshipData: Tables['relationships']['Insert']) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('relationships')
    .insert(relationshipData)
    .select()
    .single();
}

/**
 * Create an interaction
 */
export async function createInteraction(interactionData: Tables['interactions']['Insert']) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('interactions')
    .insert(interactionData)
    .select()
    .single();
}

/**
 * Create interaction participants
 */
export async function createInteractionParticipants(
  participantsData: Tables['interaction_participants']['Insert'][]
) {
  const supabase = createServerSupabaseClient();
  
  return await supabase
    .from('interaction_participants')
    .insert(participantsData)
    .select();
} 