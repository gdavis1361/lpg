import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Interaction, InteractionParticipant, Person, Relationship } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateBoolean, generateNumber, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Common interaction types and statuses are referenced inline using faker.helpers

/**
 * Generate interactions between people
 */
export async function generateInteractions(
  supabase: SupabaseClient<Database>,
  config: SeedConfig,
  people: Person[],
  relationships: Relationship[]
): Promise<Interaction[]> {
  logger.info('Generating interactions...');
  
  // First, check if we already have interactions
  const { data: existingInteractions, error: checkError } = await supabase
    .from('interactions')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing interactions:', checkError);
    throw checkError;
  }
  
  if (existingInteractions && existingInteractions.length > 0) {
    logger.info('Interactions already exist, fetching existing data...');
    const { data: interactions, error } = await supabase
      .from('interactions')
      .select('*');
      
    if (error) {
      logger.error('Error fetching interactions:', error);
      throw error;
    }
    
    logger.success(`Found ${interactions?.length || 0} existing interactions`);
    return interactions || [];
  }
  
  // Generate interactions
  const interactions: Interaction[] = [];
  const interactionParticipants: InteractionParticipant[] = [];
  
  // Special test interactions
  if (config.createSpecialTestCases) {
    const testRelationship = relationships.find(r => r.id === 'c0000000-0000-0000-0000-000000000001');
    
    if (testRelationship) {
      // Add a recent interaction for the test relationship
      const recentDate = new Date();
      recentDate.setDate(recentDate.getDate() - 3);
      
      const interactionId = 'f0000000-0000-0000-0000-000000000001';
      
      interactions.push({
        id: interactionId,
        title: 'Test Recent Meeting',
        description: 'A recent meeting for testing purposes',
        type: 'meeting',
        start_time: recentDate.toISOString(),
        end_time: new Date(recentDate.getTime() + 60 * 60 * 1000).toISOString(), // 1 hour later
        location: 'Test Office',
        is_planned: true,
        status: 'completed',
        quality_score: 80,
        reciprocity_score: 75,
        sentiment_score: 85,
        metadata: { isTestData: true },
        scheduled_at: new Date(recentDate.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString(), // Scheduled 1 week before
        created_by: testRelationship.from_person_id,
        updated_by: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
      
      // Add participants
      interactionParticipants.push({
        id: generateId(),
        interaction_id: interactionId,
        person_id: testRelationship.from_person_id,
        role: 'mentor',
        attended: true,
        created_at: new Date().toISOString()
      });
      
      interactionParticipants.push({
        id: generateId(),
        interaction_id: interactionId,
        person_id: testRelationship.to_person_id,
        role: 'mentee',
        attended: true,
        created_at: new Date().toISOString()
      });
      
      // Add an upcoming interaction
      const upcomingDate = new Date();
      upcomingDate.setDate(upcomingDate.getDate() + 7); // One week in the future
      
      const upcomingId = 'f0000000-0000-0000-0000-000000000002';
      
      interactions.push({
        id: upcomingId,
        title: 'Test Upcoming Meeting',
        description: 'An upcoming meeting for testing purposes',
        type: 'video_call',
        start_time: upcomingDate.toISOString(),
        end_time: new Date(upcomingDate.getTime() + 60 * 60 * 1000).toISOString(), // 1 hour later
        location: 'Zoom',
        is_planned: true,
        status: 'scheduled',
        quality_score: null,
        reciprocity_score: null,
        sentiment_score: null,
        metadata: { isTestData: true, zoomLink: 'https://zoom.us/test' },
        scheduled_at: new Date().toISOString(),
        created_by: testRelationship.from_person_id,
        updated_by: null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      });
      
      // Add participants for upcoming meeting
      interactionParticipants.push({
        id: generateId(),
        interaction_id: upcomingId,
        person_id: testRelationship.from_person_id,
        role: 'mentor',
        attended: null,
        created_at: new Date().toISOString()
      });
      
      interactionParticipants.push({
        id: generateId(),
        interaction_id: upcomingId,
        person_id: testRelationship.to_person_id,
        role: 'mentee',
        attended: null,
        created_at: new Date().toISOString()
      });
    }
  }
  
  // Generate interactions for each relationship
  for (const relationship of relationships) {
    // Skip some relationships to make the data more realistic
    if (!generateBoolean(0.8)) continue;
    
    // How many interactions for this relationship?
    const interactionsCount = 
      relationship.status === 'active' 
        ? generateNumber(1, config.interactionsPerRelationship)
        : generateNumber(0, Math.max(1, Math.floor(config.interactionsPerRelationship / 2)));
    
    for (let i = 0; i < interactionsCount; i++) {
      // Determine if this is a past, current, or future interaction
      const timeframe = faker.helpers.weightedArrayElement([
        { weight: 70, value: 'past' },
        { weight: 10, value: 'future' },
        { weight: 20, value: 'recent' }
      ]);
      
      const relationshipStart = relationship.start_date 
        ? new Date(relationship.start_date) 
        : new Date(config.startDate);
      
      const relationshipEnd = relationship.end_date 
        ? new Date(relationship.end_date) 
        : new Date();
      
      let interactionDate: Date;
      let status: string;
      let isPlanned: boolean;
      
      switch (timeframe) {
        case 'past':
          // Generate a date between relationship start and either end or now
          interactionDate = faker.date.between({ 
            from: relationshipStart, 
            to: relationship.end_date ? relationshipEnd : new Date() 
          });
          status = 'completed';
          isPlanned = generateBoolean(0.7);
          break;
          
        case 'recent':
          // Generate a date in the last 30 days
          interactionDate = faker.date.recent({ days: 30 });
          status = 'completed';
          isPlanned = generateBoolean(0.8);
          break;
          
        case 'future':
          // Generate a date in the next 30 days
          interactionDate = faker.date.soon({ days: 30 });
          status = 'scheduled';
          isPlanned = true;
          break;
          
        default:
          interactionDate = faker.date.between({ 
            from: relationshipStart, 
            to: relationship.end_date ? relationshipEnd : new Date() 
          });
          status = 'completed';
          isPlanned = generateBoolean(0.7);
      }
      
      // Create a random duration (30-120 minutes)
      const durationMinutes = faker.helpers.arrayElement([30, 45, 60, 90, 120]);
      const endTime = new Date(interactionDate);
      endTime.setMinutes(endTime.getMinutes() + durationMinutes);
      
      // Choose interaction type (weight toward common types)
      const type = faker.helpers.weightedArrayElement([
        { weight: 30, value: 'meeting' },
        { weight: 25, value: 'call' },
        { weight: 15, value: 'video_call' },
        { weight: 10, value: 'email' },
        { weight: 5, value: 'text' },
        { weight: 5, value: 'lunch' },
        { weight: 5, value: 'workshop' },
        { weight: 5, value: 'social_event' }
      ]);
      
      // Generate location based on type
      let location: string | null = null;
      
      switch (type) {
        case 'meeting':
          location = faker.helpers.arrayElement([
            faker.company.name() + ' Office',
            'Campus Center',
            'Library',
            faker.location.streetAddress(),
            faker.company.name() + ' Headquarters'
          ]);
          break;
          
        case 'video_call':
          location = faker.helpers.arrayElement([
            'Zoom',
            'Microsoft Teams',
            'Google Meet',
            'Skype'
          ]);
          break;
          
        case 'lunch':
          location = faker.company.name() + ' ' + faker.helpers.arrayElement([
            'Cafe',
            'Restaurant',
            'Bistro',
            'Diner'
          ]);
          break;
          
        case 'workshop':
        case 'social_event':
          location = faker.helpers.arrayElement([
            'Conference Room A',
            'Student Center',
            'Community Hall',
            faker.company.name() + ' Event Space',
            'Downtown Venue'
          ]);
          break;
      }
      
      // Determine if the interaction was scheduled in advance
      const scheduledAt = isPlanned && timeframe !== 'future'
        ? faker.date.past({ years: 1, refDate: interactionDate })
        : timeframe === 'future'
          ? new Date() // For future interactions, scheduled now
          : null;
      
      // Generate quality, reciprocity, and sentiment scores (only for completed interactions)
      const qualityScore = status === 'completed' ? faker.number.int({ min: 50, max: 100 }) : null;
      const reciprocityScore = status === 'completed' ? faker.number.int({ min: 40, max: 100 }) : null;
      const sentimentScore = status === 'completed' ? faker.number.int({ min: 45, max: 100 }) : null;
      
      // Create the interaction
      const interactionId = generateId();
      
      interactions.push({
        id: interactionId,
        title: generateInteractionTitle(type, relationship),
        description: generateBoolean(0.7) ? faker.lorem.paragraph() : null,
        type,
        start_time: interactionDate.toISOString(),
        end_time: endTime.toISOString(),
        location,
        is_planned: isPlanned,
        status,
        quality_score: qualityScore,
        reciprocity_score: reciprocityScore,
        sentiment_score: sentimentScore,
        metadata: generateInteractionMetadata(type),
        scheduled_at: scheduledAt?.toISOString() || null,
        created_by: relationship.from_person_id,
        updated_by: null,
        created_at: scheduledAt?.toISOString() || interactionDate.toISOString(),
        updated_at: interactionDate.toISOString()
      });
      
      // Create participants for this interaction
      
      // Always include the two people from the relationship
      interactionParticipants.push({
        id: generateId(),
        interaction_id: interactionId,
        person_id: relationship.from_person_id,
        role: 'mentor',
        attended: status === 'completed' ? true : null,
        created_at: interactionDate.toISOString()
      });
      
      interactionParticipants.push({
        id: generateId(),
        interaction_id: interactionId,
        person_id: relationship.to_person_id,
        role: 'mentee',
        attended: status === 'completed' 
          ? (timeframe === 'past' && generateBoolean(0.9)) // 90% chance they attended
          : null,
        created_at: interactionDate.toISOString()
      });
      
      // Occasionally add additional participants for group sessions
      if (type === 'workshop' || type === 'social_event' || (generateBoolean(0.2) && type === 'meeting')) {
        // Add 1-3 additional random participants
        const additionalCount = faker.number.int({ min: 1, max: 3 });
        const additionalPeople = faker.helpers.arrayElements(
          people.filter(p => p.id !== relationship.from_person_id && p.id !== relationship.to_person_id),
          additionalCount
        );
        
        for (const person of additionalPeople) {
          interactionParticipants.push({
            id: generateId(),
            interaction_id: interactionId,
            person_id: person.id,
            role: faker.helpers.arrayElement(['observer', 'participant', 'guest']),
            attended: status === 'completed' 
              ? generateBoolean(0.8) // 80% chance they attended
              : null,
            created_at: interactionDate.toISOString()
          });
        }
      }
    }
    
    // Progress logging
    logger.progress(relationships.indexOf(relationship) + 1, relationships.length, 'relationships processed');
  }
  
  // Insert interactions in batches
  await batchProcess(interactions, 50, async (batch) => {
    const { error } = await supabase
      .from('interactions')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting interactions:', error);
      throw error;
    }
  });
  
  // Insert interaction participants in batches
  await batchProcess(interactionParticipants, 100, async (batch) => {
    const { error } = await supabase
      .from('interaction_participants')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting interaction participants:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${interactions.length} interactions with ${interactionParticipants.length} participants`);
  return interactions;
}

/**
 * Generate a realistic title for an interaction
 */
function generateInteractionTitle(type: string, _relationship: Relationship): string {
  switch (type) {
    case 'meeting':
      return faker.helpers.arrayElement([
        'Mentorship Meeting',
        'Check-in Meeting',
        'Progress Review',
        'Planning Session',
        'Goal Setting Meeting',
        'Career Discussion'
      ]);
      
    case 'call':
    case 'video_call':
      return faker.helpers.arrayElement([
        'Mentorship Call',
        'Quick Check-in',
        'Status Update Call',
        'Virtual Meeting',
        'Feedback Session',
        'Progress Discussion'
      ]);
      
    case 'email':
      return faker.helpers.arrayElement([
        'Email Correspondence',
        'Written Update',
        'Resource Sharing',
        'Follow-up Email',
        'Introduction Email',
        'Schedule Coordination'
      ]);
      
    case 'text':
      return faker.helpers.arrayElement([
        'Text Check-in',
        'Quick Update',
        'Text Correspondence',
        'Scheduling Text',
        'Reminder Message',
        'Quick Question'
      ]);
      
    case 'social_event':
      return faker.helpers.arrayElement([
        'Networking Event',
        'Social Gathering',
        'Alumni Mixer',
        'Community Event',
        'Department Social',
        'Industry Meetup'
      ]);
      
    case 'career_event':
      return faker.helpers.arrayElement([
        'Career Fair',
        'Industry Panel',
        'Recruitment Event',
        'Job Shadow Day',
        'Professional Development',
        'Career Workshop'
      ]);
      
    case 'workshop':
      return faker.helpers.arrayElement([
        'Skill-building Workshop',
        'Training Session',
        'Professional Development',
        'Learning Workshop',
        'Hands-on Training',
        'Practical Workshop'
      ]);
      
    case 'lunch':
      return faker.helpers.arrayElement([
        'Mentorship Lunch',
        'Informal Lunch Meeting',
        'Lunch Discussion',
        'Career Lunch',
        'Networking Lunch',
        'Lunch Check-in'
      ]);
      
    default:
      return 'Mentorship Interaction';
  }
}

/**
 * Generate metadata for an interaction based on its type
 */
function generateInteractionMetadata(type: string): Record<string, any> | null {
  if (!generateBoolean(0.7)) {
    return null;
  }
  
  const metadata: Record<string, any> = {};
  
  switch (type) {
    case 'video_call':
      metadata.platform = faker.helpers.arrayElement(['Zoom', 'Teams', 'Google Meet', 'Skype']);
      metadata.link = `https://${metadata.platform.toLowerCase().replace(' ', '')}.com/${faker.string.alphanumeric(10)}`;
      break;
      
    case 'meeting':
      if (generateBoolean(0.5)) {
        metadata.room = faker.helpers.arrayElement(['Conference Room A', 'Meeting Room 3B', 'Office 205', 'Study Room 4']);
      }
      if (generateBoolean(0.3)) {
        metadata.agenda = faker.lorem.sentences(3);
      }
      break;
      
    case 'workshop':
      metadata.materials = faker.helpers.arrayElement([
        'Slides and handouts provided',
        'Bring laptop',
        'Pre-reading required',
        'All materials provided'
      ]);
      metadata.capacity = faker.number.int({ min: 5, max: 30 });
      break;
      
    case 'social_event':
      metadata.attendees = faker.number.int({ min: 10, max: 100 });
      metadata.dress_code = faker.helpers.arrayElement(['Business casual', 'Casual', 'Business formal', 'Smart casual']);
      break;
  }
  
  return metadata;
} 