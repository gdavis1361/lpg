import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { ActivityGroup } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Activity group categories
const ACTIVITY_CATEGORIES = [
  'academic',
  'career',
  'volunteer',
  'leadership',
  'extracurricular',
  'service',
  'community',
  'religious'
];

/**
 * Generate a list of activity groups
 */
export async function generateActivityGroups(
  supabase: SupabaseClient<Database>,
  config: SeedConfig
): Promise<ActivityGroup[]> {
  logger.info(`Generating ${config.activityGroups} activity groups...`);
  
  // First, check if we already have activity groups
  const { data: existingGroups, error: checkError } = await supabase
    .from('activity_groups')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing activity groups:', checkError);
    throw checkError;
  }
  
  if (existingGroups && existingGroups.length > 0) {
    logger.info('Activity groups already exist, fetching existing data...');
    const { data: groups, error } = await supabase
      .from('activity_groups')
      .select('*');
      
    if (error) {
      logger.error('Error fetching activity groups:', error);
      throw error;
    }
    
    logger.success(`Found ${groups?.length || 0} existing activity groups`);
    return groups || [];
  }
  
  // Generate activity group data
  const activityGroups: ActivityGroup[] = [];
  
  // Special activity groups for test cases
  if (config.createSpecialTestCases) {
    activityGroups.push({
      id: 'd0000000-0000-0000-0000-000000000001',
      name: 'Test Activity Group',
      description: 'A special test activity group for development',
      category: 'academic',
      created_at: new Date().toISOString(),
    });
  }
  
  // Common activity groups that fit well with mentorship programs
  const commonGroups = [
    { name: 'Mentorship Program', category: 'leadership' },
    { name: 'Career Development', category: 'career' },
    { name: 'Academic Support', category: 'academic' },
    { name: 'Alumni Association', category: 'community' },
    { name: 'Community Service', category: 'service' },
    { name: 'Leadership Training', category: 'leadership' },
    { name: 'Professional Development', category: 'career' },
    { name: 'Peer Tutoring', category: 'academic' }
  ];
  
  // Add common groups first
  commonGroups.slice(0, Math.min(commonGroups.length, config.activityGroups)).forEach(group => {
    activityGroups.push({
      id: generateId(),
      name: group.name,
      description: faker.lorem.sentence(),
      category: group.category,
      created_at: generateTimestamp(config.startDate, new Date()),
    });
  });
  
  // Add more random groups to reach the desired count
  for (let i = activityGroups.length; i < config.activityGroups; i++) {
    const category = faker.helpers.arrayElement(ACTIVITY_CATEGORIES);
    let name: string;
    
    // Generate name based on category
    switch (category) {
      case 'academic':
        name = `${faker.word.adjective()} ${faker.helpers.arrayElement([
          'Study Group',
          'Academic Club',
          'Learning Circle',
          'Scholarship Program'
        ])}`;
        break;
        
      case 'career':
        name = `${faker.company.buzzNoun()} ${faker.helpers.arrayElement([
          'Career Track',
          'Professional Group',
          'Industry Connect',
          'Career Prep'
        ])}`;
        break;
        
      case 'leadership':
        name = `${faker.word.adjective()} ${faker.helpers.arrayElement([
          'Leaders',
          'Leadership Circle',
          'Directors Program',
          'Executive Training'
        ])}`;
        break;
        
      default:
        name = `${faker.word.adjective()} ${faker.helpers.arrayElement([
          'Club',
          'Group',
          'Association',
          'Program',
          'Initiative'
        ])}`;
    }
    
    activityGroups.push({
      id: generateId(),
      name,
      description: faker.lorem.sentence(),
      category,
      created_at: generateTimestamp(config.startDate, new Date()),
    });
  }
  
  // Insert activity groups in batches
  await batchProcess(activityGroups, 50, async (batch) => {
    const { error } = await supabase
      .from('activity_groups')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting activity groups:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${activityGroups.length} activity groups`);
  return activityGroups;
} 