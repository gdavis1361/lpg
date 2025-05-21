import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { MentorMilestone, RelationshipMilestone, Relationship } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, generateBoolean, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

/**
 * Generate milestone templates
 */
async function generateMentorMilestoneTemplates(
  supabase: SupabaseClient<Database>,
  _config: SeedConfig // Note: config is unused but kept for consistent interfaces
): Promise<MentorMilestone[]> {
  // First, check if we already have milestone templates
  const { data: existingMilestones, error: checkError } = await supabase
    .from('mentor_milestones')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing milestone templates:', checkError);
    throw checkError;
  }
  
  if (existingMilestones && existingMilestones.length > 0) {
    logger.info('Milestone templates already exist, fetching existing data...');
    const { data: milestones, error } = await supabase
      .from('mentor_milestones')
      .select('*');
      
    if (error) {
      logger.error('Error fetching milestone templates:', error);
      throw error;
    }
    
    logger.success(`Found ${milestones?.length || 0} existing milestone templates`);
    return milestones || [];
  }
  
  // Common milestone types for mentorship programs
  const milestoneTemplates: MentorMilestone[] = [
    {
      id: generateId(),
      name: 'Initial Meeting',
      description: 'First meeting between mentor and mentee to establish relationship',
      is_required: true,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Goal Setting',
      description: 'Establish key goals and outcomes for the mentorship',
      is_required: true,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Mid-term Check-in',
      description: 'Review progress toward goals and adjust as needed',
      is_required: false,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Career Planning',
      description: 'Discussion about career paths and opportunities',
      is_required: false,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Resume Review',
      description: 'Review and improve resume/CV',
      is_required: false,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Annual Review',
      description: 'End of year review and planning for next year',
      is_required: true,
      typical_year: 1,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Job Shadow Day',
      description: 'Mentee shadows mentor at workplace',
      is_required: false,
      typical_year: 2,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Internship/Job Search',
      description: 'Support with internship or job search process',
      is_required: false,
      typical_year: 2,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Interview Preparation',
      description: 'Mock interviews and feedback',
      is_required: false,
      typical_year: 2,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    },
    {
      id: generateId(),
      name: 'Professional Network Introduction',
      description: 'Introduction to professional network and contacts',
      is_required: false,
      typical_year: 2,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    }
  ];
  
  // Insert milestone templates in batches
  await batchProcess(milestoneTemplates, 50, async (batch) => {
    const { error } = await supabase
      .from('mentor_milestones')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting milestone templates:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${milestoneTemplates.length} milestone templates`);
  return milestoneTemplates;
}

/**
 * Generate relationship milestone achievements
 */
export async function generateMilestones(
  supabase: SupabaseClient<Database>,
  config: SeedConfig,
  relationships: Relationship[]
): Promise<RelationshipMilestone[]> {
  logger.info('Generating relationship milestones...');
  
  // First, check if we already have relationship milestones
  const { data: existingMilestones, error: checkError } = await supabase
    .from('relationship_milestones')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing relationship milestones:', checkError);
    throw checkError;
  }
  
  if (existingMilestones && existingMilestones.length > 0) {
    logger.info('Relationship milestones already exist, fetching existing data...');
    const { data: milestones, error } = await supabase
      .from('relationship_milestones')
      .select('*');
      
    if (error) {
      logger.error('Error fetching relationship milestones:', error);
      throw error;
    }
    
    logger.success(`Found ${milestones?.length || 0} existing relationship milestones`);
    return milestones || [];
  }
  
  // First, ensure we have milestone templates
  const milestoneTemplates = await generateMentorMilestoneTemplates(supabase, config);
  
  // Generate relationship milestones
  const relationshipMilestones: RelationshipMilestone[] = [];
  
  // Temporary map to avoid duplicate milestones for the same relationship
  const relationshipMilestoneMap = new Map<string, Set<string>>();
  
  // Generate milestones for each relationship
  for (const relationship of relationships) {
    // Skip inactive or completed relationships sometimes
    if (relationship.status !== 'active' && generateBoolean(0.3)) {
      continue;
    }
    
    // How many milestones for this relationship?
    const milestonesCount = Math.floor(Math.random() * (config.milestonesPerRelationship + 1));
    
    // Initialize tracking set for this relationship
    relationshipMilestoneMap.set(relationship.id, new Set<string>());
    
    // Choose milestones with preference for required ones
    const requiredMilestones = milestoneTemplates.filter(m => m.is_required === true);
    const optionalMilestones = milestoneTemplates.filter(m => m.is_required !== true);
    
    // Add required milestones first (with some randomness)
    for (const milestone of requiredMilestones) {
      if (generateBoolean(config.requiredMilestoneProbability)) {
        // Check if this relationship already has this milestone
        const milestoneSet = relationshipMilestoneMap.get(relationship.id);
        if (milestoneSet && !milestoneSet.has(milestone.id)) {
          // Track that we've used this milestone
          milestoneSet.add(milestone.id);
          
          // Generate achievement date (sometime between relationship start and now)
          const relationshipStart = relationship.start_date ? new Date(relationship.start_date) : config.startDate;
          const achievedDate = generateTimestamp(relationshipStart, new Date());
          
          // Create the relationship milestone
          relationshipMilestones.push({
            id: generateId(),
            relationship_id: relationship.id,
            milestone_id: milestone.id,
            achieved_date: achievedDate,
            notes: generateBoolean(0.7) ? faker.lorem.sentences(2) : null,
            evidence_url: generateBoolean(0.3) ? faker.internet.url() : null,
            created_by: relationship.from_person_id,
            created_at: achievedDate,
            updated_at: achievedDate
          });
        }
      }
    }
    
    // Add optional milestones up to the count
    const currentCount = relationshipMilestones.filter(m => m.relationship_id === relationship.id).length;
    if (currentCount < milestonesCount) {
      // Shuffle the optional milestones to randomize selection
      const shuffledOptional = [...optionalMilestones].sort(() => 0.5 - Math.random());
      
      for (const milestone of shuffledOptional.slice(0, milestonesCount - currentCount)) {
        // Check if this relationship already has this milestone
        const milestoneSet = relationshipMilestoneMap.get(relationship.id);
        if (milestoneSet && !milestoneSet.has(milestone.id)) {
          // Track that we've used this milestone
          milestoneSet.add(milestone.id);
          
          // Generate achievement date (sometime between relationship start and now)
          const relationshipStart = relationship.start_date ? new Date(relationship.start_date) : config.startDate;
          const achievedDate = generateTimestamp(relationshipStart, new Date());
          
          // Create the relationship milestone
          relationshipMilestones.push({
            id: generateId(),
            relationship_id: relationship.id,
            milestone_id: milestone.id,
            achieved_date: achievedDate,
            notes: generateBoolean(0.6) ? faker.lorem.sentences(2) : null,
            evidence_url: generateBoolean(0.2) ? faker.internet.url() : null,
            created_by: relationship.from_person_id,
            created_at: achievedDate,
            updated_at: achievedDate
          });
        }
      }
    }
    
    // Progress logging
    logger.progress(relationships.indexOf(relationship) + 1, relationships.length, 'relationships processed');
  }
  
  // Insert relationship milestones in batches
  await batchProcess(relationshipMilestones, 100, async (batch) => {
    const { error } = await supabase
      .from('relationship_milestones')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting relationship milestones:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${relationshipMilestones.length} relationship milestones`);
  return relationshipMilestones;
} 