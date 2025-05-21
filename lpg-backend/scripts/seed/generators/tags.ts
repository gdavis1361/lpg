import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Tag } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, generateColor, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Tag categories
const TAG_CATEGORIES = [
  'interest',
  'skill',
  'location',
  'status',
  'program',
  'demographic'
];

/**
 * Generate a list of tags
 */
export async function generateTags(
  supabase: SupabaseClient<Database>,
  config: SeedConfig
): Promise<Tag[]> {
  logger.info(`Generating ${config.tagsTotal} tags...`);
  
  // First, check if we already have tags
  const { data: existingTags, error: checkError } = await supabase
    .from('tags')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing tags:', checkError);
    throw checkError;
  }
  
  if (existingTags && existingTags.length > 0) {
    logger.info('Tags already exist, fetching existing data...');
    const { data: tags, error } = await supabase
      .from('tags')
      .select('*');
      
    if (error) {
      logger.error('Error fetching tags:', error);
      throw error;
    }
    
    logger.success(`Found ${tags?.length || 0} existing tags`);
    return tags || [];
  }
  
  // Generate tag data
  const tags: Tag[] = [];
  
  // Special tags for test cases
  if (config.createSpecialTestCases) {
    tags.push({
      id: 'e0000000-0000-0000-0000-000000000001',
      name: 'Test Tag',
      category: 'status',
      color: '#FF5733',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });
  }
  
  // Common tags that are useful for mentorship programs
  const commonTags = [
    { name: 'First Generation', category: 'demographic', color: '#4285F4' },
    { name: 'STEM', category: 'interest', color: '#34A853' },
    { name: 'High Priority', category: 'status', color: '#EA4335' },
    { name: 'New Mentor', category: 'status', color: '#FBBC05' },
    { name: 'Leadership', category: 'skill', color: '#8E44AD' },
    { name: 'Alumni', category: 'status', color: '#3498DB' },
    { name: 'Remote', category: 'location', color: '#1ABC9C' },
    { name: 'Transfer Student', category: 'demographic', color: '#E74C3C' },
    { name: 'Scholarship', category: 'program', color: '#F39C12' },
    { name: 'Needs Check-in', category: 'status', color: '#FF5733' }
  ];
  
  // Add common tags first
  commonTags.slice(0, Math.min(commonTags.length, config.tagsTotal)).forEach(tag => {
    tags.push({
      id: generateId(),
      name: tag.name,
      category: tag.category,
      color: tag.color,
      created_at: generateTimestamp(config.startDate, new Date()),
      updated_at: generateTimestamp(config.startDate, new Date()),
    });
  });
  
  // Add more random tags to reach the desired count
  for (let i = tags.length; i < config.tagsTotal; i++) {
    const category = faker.helpers.arrayElement(TAG_CATEGORIES);
    let name: string;
    
    // Generate name based on category
    switch (category) {
      case 'interest':
        name = faker.helpers.arrayElement([
          'Programming',
          'Design',
          'Marketing',
          'Finance',
          'Research',
          'Entrepreneurship',
          'Data Science',
          'Creative Writing',
          'Public Speaking',
          'Business',
          'Healthcare',
          'Education',
          'Engineering'
        ]);
        break;
        
      case 'skill':
        name = faker.helpers.arrayElement([
          'Python',
          'JavaScript',
          'Leadership',
          'Communication',
          'Project Management',
          'Public Speaking',
          'Writing',
          'Data Analysis',
          'Team Building',
          'Problem Solving',
          'Critical Thinking'
        ]);
        break;
        
      case 'location':
        name = faker.location.city();
        break;
        
      case 'status':
        name = faker.helpers.arrayElement([
          'Active',
          'Inactive',
          'Needs Follow-up',
          'At Risk',
          'Graduated',
          'New',
          'Alumni',
          'VIP'
        ]);
        break;
        
      case 'program':
        name = faker.helpers.arrayElement([
          'Summer Program',
          'Internship Program',
          'Leadership Initiative',
          'Exchange Program',
          'Graduate Program',
          'Scholarship Recipient',
          'Research Grant'
        ]);
        break;
        
      case 'demographic':
        name = faker.helpers.arrayElement([
          'Undergraduate',
          'Graduate',
          'International',
          'First Generation',
          'Transfer',
          'Veteran',
          'Part-time'
        ]);
        break;
        
      default:
        name = faker.word.noun();
    }
    
    // Avoid duplicate tag names
    if (tags.find(t => t.name === name)) {
      name = `${name} ${faker.string.alphanumeric(4)}`;
    }
    
    tags.push({
      id: generateId(),
      name,
      category,
      color: generateColor(),
      created_at: generateTimestamp(config.startDate, new Date()),
      updated_at: generateTimestamp(config.startDate, new Date()),
    });
  }
  
  // Insert tags in batches
  await batchProcess(tags, 50, async (batch) => {
    const { error } = await supabase
      .from('tags')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting tags:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${tags.length} tags`);
  return tags;
} 