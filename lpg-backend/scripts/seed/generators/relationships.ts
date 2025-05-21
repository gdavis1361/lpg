import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Relationship, Person } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, generateBoolean, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Relationship statuses 
// These values are used when creating relationships

// Relationship types
const RELATIONSHIP_TYPES = [
  'mentor_student',  // Primary mentorship relationship
  'peer_mentor',     // Peer mentorship
  'coach',           // Coaching relationship
  'sponsor',         // Career sponsorship
  'alumni_student',  // Alumni to current student connection
];

/**
 * Generate relationships between people
 */
export async function generateRelationships(
  supabase: SupabaseClient<Database>,
  config: SeedConfig,
  people: Person[]
): Promise<Relationship[]> {
  logger.info('Generating relationships...');
  
  // First, check if we already have relationship types
  const { data: existingTypes, error: typeCheckError } = await supabase
    .from('relationship_types')
    .select('id, code')
    .limit(RELATIONSHIP_TYPES.length);
    
  if (typeCheckError) {
    logger.error('Error checking relationship types:', typeCheckError);
    throw typeCheckError;
  }
  
  // Create relationship types if they don't exist
  if (!existingTypes || existingTypes.length < RELATIONSHIP_TYPES.length) {
    logger.info('Creating relationship types...');
    
    const relationshipTypes = RELATIONSHIP_TYPES.map(type => ({
      id: generateId(),
      code: type,
      name: type.split('_').map(word => word.charAt(0).toUpperCase() + word.slice(1)).join(' '),
      description: `A ${type.replace('_', ' ')} relationship`,
      created_at: new Date().toISOString(),
    }));
    
    const { error: createTypeError } = await supabase
      .from('relationship_types')
      .insert(relationshipTypes);
      
    if (createTypeError) {
      logger.error('Error creating relationship types:', createTypeError);
      throw createTypeError;
    }
  }
  
  // Fetch relationship types
  const { data: relationshipTypes, error: fetchTypeError } = await supabase
    .from('relationship_types')
    .select('id, code');
    
  if (fetchTypeError) {
    logger.error('Error fetching relationship types:', fetchTypeError);
    throw fetchTypeError;
  }
  
  // Check if we already have relationships
  const { data: existingRelationships, error: checkError } = await supabase
    .from('relationships')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing relationships:', checkError);
    throw checkError;
  }
  
  if (existingRelationships && existingRelationships.length > 0) {
    logger.info('Relationships already exist, fetching existing data...');
    const { data: relationships, error } = await supabase
      .from('relationships')
      .select('*');
      
    if (error) {
      logger.error('Error fetching relationships:', error);
      throw error;
    }
    
    logger.success(`Found ${relationships?.length || 0} existing relationships`);
    return relationships || [];
  }
  
  // Create a map of relationship types for lookup
  const typeMap = new Map(relationshipTypes!.map(type => [type.code, type.id]));
  
  // Filter people by graduation year to get mentors (older) and students (younger)
  const currentYear = new Date().getFullYear();
  const potentialMentors = people.filter(p => 
    p.graduation_year && p.graduation_year <= currentYear - 3
  );
  
  const potentialStudents = people.filter(p => 
    p.graduation_year && p.graduation_year > currentYear - 5
  );
  
  // Generate relationships
  const relationships: Relationship[] = [];
  
  // Special test relationship
  if (config.createSpecialTestCases) {
    // Find our special test people
    const testMentor = people.find(p => p.id === 'b0000000-0000-0000-0000-000000000001');
    const testStudent = people.find(p => p.id === 'b0000000-0000-0000-0000-000000000002');
    
    if (testMentor && testStudent) {
      relationships.push({
        id: 'c0000000-0000-0000-0000-000000000001',
        from_person_id: testMentor.id,
        to_person_id: testStudent.id,
        relationship_type_id: typeMap.get('mentor_student') || null,
        status: 'active',
        start_date: new Date(currentYear - 1, 0, 1).toISOString(),
        end_date: null,
        strength_score: 85,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  }
  
  // Generate mentor-student relationships
  const totalRelationships = Math.min(
    potentialMentors.length * config.relationshipsPerPerson,
    potentialStudents.length * 2 // Assume each student has at most 2 mentors
  );
  
  logger.info(`Generating ${totalRelationships} mentor-student relationships...`);
  
  // Track assigned mentors to avoid duplicates
  const assignedPairs = new Set<string>();
  
  for (let i = 0; i < totalRelationships; i++) {
    // Keep trying until we find a unique pair
    let attempts = 0;
    let mentor, student, pairKey;
    
    do {
      mentor = faker.helpers.arrayElement(potentialMentors);
      student = faker.helpers.arrayElement(potentialStudents);
      pairKey = `${mentor.id}-${student.id}`;
      attempts++;
    } while (assignedPairs.has(pairKey) && attempts < 10);
    
    // Skip if we couldn't find a unique pair after several attempts
    if (assignedPairs.has(pairKey)) continue;
    
    assignedPairs.add(pairKey);
    
    // Determine relationship type (mostly mentor-student, some peer mentors)
    const relationshipType = generateBoolean(0.8) 
      ? 'mentor_student' 
      : faker.helpers.arrayElement(RELATIONSHIP_TYPES);
    
    // Generate a realistic start date
    const now = new Date();
    const startDate = generateTimestamp(
      new Date(Math.max(now.getFullYear() - config.relationshipMaxAgeDays / 365, 2015), 0, 1),
      now
    );
    
    // Determine if relationship is active or has an end date
    const isActive = generateBoolean(config.activeMentorshipProbability);
    const endDate = isActive 
      ? null 
      : generateTimestamp(new Date(startDate), now);
    
    // Generate relationship strength score (higher for active relationships)
    const strengthScore = isActive
      ? faker.number.int({ min: 50, max: 95 })
      : faker.number.int({ min: 20, max: 70 });
    
    relationships.push({
      id: generateId(),
      from_person_id: mentor.id,
      to_person_id: student.id,
      relationship_type_id: typeMap.get(relationshipType) || null,
      status: isActive ? 'active' : faker.helpers.arrayElement(['inactive', 'completed']),
      start_date: startDate,
      end_date: endDate,
      strength_score: strengthScore,
      created_at: startDate,
      updated_at: endDate || startDate,
    });
    
    logger.progress(i + 1, totalRelationships, 'relationships');
  }
  
  // Insert relationships in batches
  await batchProcess(relationships, 50, async (batch) => {
    const { error } = await supabase
      .from('relationships')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting relationships:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${relationships.length} relationships`);
  return relationships;
} 