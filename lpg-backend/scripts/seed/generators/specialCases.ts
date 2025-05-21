import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Person, Relationship, ActivityGroup } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, deterministicUuid } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

/**
 * Generate special test cases for development and testing
 * These are specific scenarios that are useful for UI development and testing
 */
export async function generateSpecialCases(
  supabase: SupabaseClient<Database>,
  config: SeedConfig,
  people: Person[],
  relationships: Relationship[],
  _activityGroups: ActivityGroup[] // Unused but kept for consistent interfaces
): Promise<void> {
  logger.info('Generating special test cases...');
  
  // Skip if we're not configured to create special test cases
  if (!config.createSpecialTestCases) {
    logger.info('Special test cases generation is disabled in config');
    return;
  }
  
  // =================================================
  // Case 1: A mentor with multiple mentees
  // =================================================
  await generateMentorWithMultipleMentees(supabase, people);
  
  // =================================================
  // Case 2: A mentee with no recent interactions
  // =================================================
  await generateMenteeWithNoRecentInteractions(supabase, people, relationships);
  
  // =================================================
  // Case 3: A relationship with all milestones completed
  // =================================================
  await generateRelationshipWithAllMilestones(supabase, relationships);
  
  // =================================================
  // Case 4: A person with many tags
  // =================================================
  await generatePersonWithManyTags(supabase, people);
  
  logger.success('Successfully generated special test cases');
}

/**
 * Generate a mentor with multiple mentees (useful for testing mentor dashboards)
 */
async function generateMentorWithMultipleMentees(
  supabase: SupabaseClient<Database>,
  people: Person[]
): Promise<void> {
  logger.info('Creating special case: Mentor with multiple mentees');
  
  // Use the test mentor if it exists
  const testMentor = people.find(p => p.id === 'b0000000-0000-0000-0000-000000000001');
  
  if (!testMentor) {
    logger.error('Test mentor not found. Special case cannot be created.');
    return;
  }
  
  // Create several mentees for the test mentor
  const menteeCount = 5;
  const menteeIds = [];
  
  for (let i = 0; i < menteeCount; i++) {
    // Generate a deterministic ID for the special case
    const menteeId = deterministicUuid(`special-mentee-${i}`);
    menteeIds.push(menteeId);
    
    // Check if mentee already exists
    const { data: existingMentee } = await supabase
      .from('people')
      .select('id')
      .eq('id', menteeId)
      .limit(1);
      
    if (existingMentee && existingMentee.length > 0) {
      logger.info(`Special mentee ${i + 1} already exists`);
      continue;
    }
    
    // Create the mentee
    const mentee = {
      id: menteeId,
      auth_id: null,
      first_name: `Special${i + 1}`,
      last_name: 'Mentee',
      email: `special.mentee${i + 1}@example.com`,
      phone: faker.phone.number(),
      birthdate: faker.date.birthdate({ min: 18, max: 25, mode: 'age' }).toISOString().split('T')[0],
      graduation_year: new Date().getFullYear() + faker.number.int({ min: 1, max: 4 }),
      avatar_url: `https://ui-avatars.com/api/?name=Special+Mentee${i + 1}&background=random`,
      employment_status: 'student',
      post_grad_status: null,
      college_attending: 'Test University',
      last_checkin_date: i < 3 ? new Date().toISOString() : null, // First 3 have recent check-ins
      address: {
        street: faker.location.streetAddress(),
        city: faker.location.city(),
        state: faker.location.state({ abbreviated: true }),
        zip: faker.location.zipCode(),
      },
      metadata: { isSpecialTestCase: true, specialCaseType: 'multipleMentees' },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    // Insert the mentee
    const { error: menteeError } = await supabase
      .from('people')
      .insert(mentee);
      
    if (menteeError) {
      logger.error(`Error creating special mentee ${i + 1}:`, menteeError);
      continue;
    }
    
    logger.info(`Created special mentee ${i + 1}`);
  }
  
  // Create relationships between mentor and mentees
  for (let i = 0; i < menteeIds.length; i++) {
    // Generate a deterministic ID for the relationship
    const relationshipId = deterministicUuid(`special-relationship-${i}`);
    
    // Check if relationship already exists
    const { data: existingRelationship } = await supabase
      .from('relationships')
      .select('id')
      .eq('id', relationshipId)
      .limit(1);
      
    if (existingRelationship && existingRelationship.length > 0) {
      logger.info(`Special relationship ${i + 1} already exists`);
      continue;
    }
    
    // Get relationship type ID
    const { data: relationshipTypes } = await supabase
      .from('relationship_types')
      .select('id')
      .eq('code', 'mentor_student')
      .limit(1);
      
    const relationshipTypeId = relationshipTypes && relationshipTypes.length > 0
      ? relationshipTypes[0].id
      : null;
    
    // Create the relationship
    const relationship = {
      id: relationshipId,
      from_person_id: testMentor.id,
      to_person_id: menteeIds[i],
      relationship_type_id: relationshipTypeId,
      status: i < 4 ? 'active' : 'pending', // First 4 are active, last is pending
      start_date: new Date(new Date().setMonth(new Date().getMonth() - i * 2)).toISOString(), // Staggered start dates
      end_date: null,
      strength_score: i === 0 ? 95 : i === 1 ? 80 : i === 2 ? 65 : i === 3 ? 40 : null, // Varying strength scores
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    // Insert the relationship
    const { error: relationshipError } = await supabase
      .from('relationships')
      .insert(relationship);
      
    if (relationshipError) {
      logger.error(`Error creating special relationship ${i + 1}:`, relationshipError);
      continue;
    }
    
    logger.info(`Created special relationship ${i + 1}`);
  }
}

/**
 * Generate a mentee with no recent interactions (useful for testing follow-up reminders)
 */
async function generateMenteeWithNoRecentInteractions(
  supabase: SupabaseClient<Database>,
  people: Person[],
  _relationships: Relationship[] // Unused but kept for consistent interfaces
): Promise<void> {
  logger.info('Creating special case: Mentee with no recent interactions');
  
  // Use the test mentor if it exists
  const testMentor = people.find(p => p.id === 'b0000000-0000-0000-0000-000000000001');
  
  if (!testMentor) {
    logger.error('Test mentor not found. Special case cannot be created.');
    return;
  }
  
  // Generate a deterministic ID for the special case
  const neglectedMenteeId = deterministicUuid('neglected-mentee');
  
  // Check if mentee already exists
  const { data: existingMentee } = await supabase
    .from('people')
    .select('id')
    .eq('id', neglectedMenteeId)
    .limit(1);
    
  if (existingMentee && existingMentee.length > 0) {
    logger.info('Neglected mentee already exists');
  } else {
    // Create the neglected mentee
    const neglectedMentee = {
      id: neglectedMenteeId,
      auth_id: null,
      first_name: 'Neglected',
      last_name: 'Mentee',
      email: 'neglected.mentee@example.com',
      phone: faker.phone.number(),
      birthdate: faker.date.birthdate({ min: 18, max: 25, mode: 'age' }).toISOString().split('T')[0],
      graduation_year: new Date().getFullYear() + 1,
      avatar_url: `https://ui-avatars.com/api/?name=Neglected+Mentee&background=random`,
      employment_status: 'student',
      post_grad_status: null,
      college_attending: 'Test University',
      last_checkin_date: new Date(new Date().setMonth(new Date().getMonth() - 3)).toISOString(), // Last check-in was 3 months ago
      address: {
        street: faker.location.streetAddress(),
        city: faker.location.city(),
        state: faker.location.state({ abbreviated: true }),
        zip: faker.location.zipCode(),
      },
      metadata: { isSpecialTestCase: true, specialCaseType: 'neglectedMentee', needsFollowUp: true },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    // Insert the neglected mentee
    const { error: menteeError } = await supabase
      .from('people')
      .insert(neglectedMentee);
      
    if (menteeError) {
      logger.error('Error creating neglected mentee:', menteeError);
      return;
    }
    
    logger.info('Created neglected mentee');
  }
  
  // Generate a deterministic ID for the relationship
  const relationshipId = deterministicUuid('neglected-relationship');
  
  // Check if relationship already exists
  const { data: existingRelationship } = await supabase
    .from('relationships')
    .select('id')
    .eq('id', relationshipId)
    .limit(1);
    
  if (existingRelationship && existingRelationship.length > 0) {
    logger.info('Neglected relationship already exists');
  } else {
    // Get relationship type ID
    const { data: relationshipTypes } = await supabase
      .from('relationship_types')
      .select('id')
      .eq('code', 'mentor_student')
      .limit(1);
      
    const relationshipTypeId = relationshipTypes && relationshipTypes.length > 0
      ? relationshipTypes[0].id
      : null;
    
    // Create the relationship
    const relationship = {
      id: relationshipId,
      from_person_id: testMentor.id,
      to_person_id: neglectedMenteeId,
      relationship_type_id: relationshipTypeId,
      status: 'active',
      start_date: new Date(new Date().setMonth(new Date().getMonth() - 6)).toISOString(), // Started 6 months ago
      end_date: null,
      strength_score: 45, // Low strength score
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    
    // Insert the relationship
    const { error: relationshipError } = await supabase
      .from('relationships')
      .insert(relationship);
      
    if (relationshipError) {
      logger.error('Error creating neglected relationship:', relationshipError);
      return;
    }
    
    logger.info('Created neglected relationship');
  }
  
  // Create an old interaction from 3 months ago
  const interactionId = deterministicUuid('neglected-interaction');
  
  // Check if interaction already exists
  const { data: existingInteraction } = await supabase
    .from('interactions')
    .select('id')
    .eq('id', interactionId)
    .limit(1);
    
  if (existingInteraction && existingInteraction.length > 0) {
    logger.info('Neglected interaction already exists');
    return;
  }
  
  // Create the interaction
  const oldDate = new Date(new Date().setMonth(new Date().getMonth() - 3));
  const interaction = {
    id: interactionId,
    title: 'Last Check-in Meeting',
    description: 'This was the last meeting before radio silence',
    type: 'meeting',
    start_time: oldDate.toISOString(),
    end_time: new Date(oldDate.getTime() + 60 * 60 * 1000).toISOString(), // 1 hour later
    location: 'Campus Center',
    is_planned: true,
    status: 'completed',
    quality_score: 60,
    reciprocity_score: 50,
    sentiment_score: 55,
    metadata: { isSpecialTestCase: true, specialCaseType: 'neglectedMentee', notes: 'Mentee seemed disengaged' },
    scheduled_at: new Date(oldDate.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString(), // Scheduled 1 week before
    created_by: testMentor.id,
    updated_by: null,
    created_at: oldDate.toISOString(),
    updated_at: oldDate.toISOString()
  };
  
  // Insert the interaction
  const { error: interactionError } = await supabase
    .from('interactions')
    .insert(interaction);
    
  if (interactionError) {
    logger.error('Error creating neglected interaction:', interactionError);
    return;
  }
  
  // Add participants
  const participants = [
    {
      id: generateId(),
      interaction_id: interactionId,
      person_id: testMentor.id,
      role: 'mentor',
      attended: true,
      created_at: oldDate.toISOString()
    },
    {
      id: generateId(),
      interaction_id: interactionId,
      person_id: neglectedMenteeId,
      role: 'mentee',
      attended: true,
      created_at: oldDate.toISOString()
    }
  ];
  
  // Insert participants
  const { error: participantsError } = await supabase
    .from('interaction_participants')
    .insert(participants);
    
  if (participantsError) {
    logger.error('Error creating neglected interaction participants:', participantsError);
    return;
  }
  
  logger.info('Created neglected interaction from 3 months ago');
}

/**
 * Generate a relationship with all milestones completed
 */
async function generateRelationshipWithAllMilestones(
  supabase: SupabaseClient<Database>,
  relationships: Relationship[]
): Promise<void> {
  logger.info('Creating special case: Relationship with all milestones completed');
  
  // Use a test relationship if it exists
  const testRelationship = relationships.find(r => r.id === 'c0000000-0000-0000-0000-000000000001');
  
  if (!testRelationship) {
    logger.error('Test relationship not found. Special case cannot be created.');
    return;
  }
  
  // Get all milestone templates
  const { data: milestoneTemplates, error: templatesError } = await supabase
    .from('mentor_milestones')
    .select('*');
    
  if (templatesError) {
    logger.error('Error fetching milestone templates:', templatesError);
    return;
  }
  
  if (!milestoneTemplates || milestoneTemplates.length === 0) {
    logger.error('No milestone templates found. Special case cannot be created.');
    return;
  }
  
  // Check if milestones already exist for this relationship
  const { data: existingMilestones, error: milestonesCheckError } = await supabase
    .from('relationship_milestones')
    .select('milestone_id')
    .eq('relationship_id', testRelationship.id);
    
  if (milestonesCheckError) {
    logger.error('Error checking existing milestones:', milestonesCheckError);
    return;
  }
  
  // Filter out milestone templates that already have achievements
  const existingMilestoneIds = existingMilestones?.map(m => m.milestone_id) || [];
  const remainingTemplates = milestoneTemplates.filter(t => !existingMilestoneIds.includes(t.id));
  
  if (remainingTemplates.length === 0) {
    logger.info('All milestones already achieved for test relationship');
    return;
  }
  
  // Create milestone achievements for all remaining templates
  const achievements = remainingTemplates.map((template, index) => {
    // Calculate a date somewhere in the past, with earlier templates being achieved earlier
    const monthsAgo = remainingTemplates.length - index;
    const achievedDate = new Date(new Date().setMonth(new Date().getMonth() - monthsAgo));
    
    return {
      id: generateId(),
      relationship_id: testRelationship.id,
      milestone_id: template.id,
      achieved_date: achievedDate.toISOString(),
      notes: faker.lorem.paragraph(),
      evidence_url: faker.internet.url(),
      created_by: testRelationship.from_person_id,
      created_at: achievedDate.toISOString(),
      updated_at: achievedDate.toISOString()
    };
  });
  
  // Insert the milestone achievements
  if (achievements.length > 0) {
    const { error: achievementsError } = await supabase
      .from('relationship_milestones')
      .insert(achievements);
      
    if (achievementsError) {
      logger.error('Error creating milestone achievements:', achievementsError);
      return;
    }
    
    logger.info(`Created ${achievements.length} milestone achievements for test relationship`);
  }
}

/**
 * Generate a person with many tags
 */
async function generatePersonWithManyTags(
  supabase: SupabaseClient<Database>,
  people: Person[]
): Promise<void> {
  logger.info('Creating special case: Person with many tags');
  
  // Use the test student if it exists
  const testStudent = people.find(p => p.id === 'b0000000-0000-0000-0000-000000000002');
  
  if (!testStudent) {
    logger.error('Test student not found. Special case cannot be created.');
    return;
  }
  
  // Get all available tags
  const { data: allTags, error: tagsError } = await supabase
    .from('tags')
    .select('*');
    
  if (tagsError) {
    logger.error('Error fetching tags:', tagsError);
    return;
  }
  
  if (!allTags || allTags.length === 0) {
    logger.error('No tags found. Special case cannot be created.');
    return;
  }
  
  // Check which tags the person already has
  const { data: existingPersonTags, error: personTagsError } = await supabase
    .from('person_tags')
    .select('tag_id')
    .eq('person_id', testStudent.id);
    
  if (personTagsError) {
    logger.error('Error checking existing person tags:', personTagsError);
    return;
  }
  
  // Filter out tags that the person already has
  const existingTagIds = existingPersonTags?.map(pt => pt.tag_id) || [];
  const remainingTags = allTags.filter(t => !existingTagIds.includes(t.id));
  
  // Assign up to 10 tags to the test student
  const tagsToAssign = remainingTags.slice(0, 10);
  
  if (tagsToAssign.length === 0) {
    logger.info('Test student already has many tags');
    return;
  }
  
  // Create person_tags entries
  const personTags = tagsToAssign.map(tag => ({
    id: generateId(),
    person_id: testStudent.id,
    tag_id: tag.id,
    created_by: null,
    created_at: new Date().toISOString()
  }));
  
  // Insert the person_tags
  const { error: insertError } = await supabase
    .from('person_tags')
    .insert(personTags);
    
  if (insertError) {
    logger.error('Error creating person tags:', insertError);
    return;
  }
  
  logger.info(`Assigned ${personTags.length} additional tags to test student`);
} 