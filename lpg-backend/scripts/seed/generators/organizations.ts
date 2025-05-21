import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Organization } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Organization types
const ORGANIZATION_TYPES = [
  'university',
  'nonprofit',
  'corporation',
  'government',
  'k12',
  'religious',
  'community',
];

/**
 * Generate a list of realistic organizations
 */
export async function generateOrganizations(
  supabase: SupabaseClient<Database>,
  config: SeedConfig
): Promise<Organization[]> {
  logger.info(`Generating ${config.organizations} organizations...`);
  
  // First, check if we already have organizations
  const { data: existingOrgs, error: checkError } = await supabase
    .from('organizations')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing organizations:', checkError);
    throw checkError;
  }
  
  if (existingOrgs && existingOrgs.length > 0) {
    logger.info('Organizations already exist, fetching existing data...');
    const { data: orgs, error } = await supabase
      .from('organizations')
      .select('*');
      
    if (error) {
      logger.error('Error fetching organizations:', error);
      throw error;
    }
    
    logger.success(`Found ${orgs?.length || 0} existing organizations`);
    return orgs || [];
  }
  
  // Generate organization data
  const organizations: Organization[] = [];
  
  // Special organizations (with known IDs for test cases)
  if (config.createSpecialTestCases) {
    organizations.push({
      id: 'a0000000-0000-0000-0000-000000000001',
      name: 'Test University',
      description: 'A special test university for development',
      type: 'university',
      metadata: { isTestData: true },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });
  }
  
  // Generate random organizations
  for (let i = 0; i < config.organizations; i++) {
    const now = new Date();
    const createdAt = generateTimestamp(config.startDate, now);
    
    const orgType = faker.helpers.arrayElement(ORGANIZATION_TYPES);
    let name: string;
    
    // Generate realistic names based on organization type
    switch (orgType) {
      case 'university':
        name = `${faker.location.city()} ${faker.helpers.arrayElement([
          'University',
          'College',
          'Institute',
          'Academy',
        ])}`;
        break;
      case 'corporation':
        name = `${faker.company.name()} ${faker.helpers.arrayElement([
          'Inc.',
          'Corp.',
          'LLC',
          'Group',
          '',
        ])}`;
        break;
      case 'nonprofit':
        name = `${faker.word.adjective()} ${faker.helpers.arrayElement([
          'Foundation',
          'Initiative',
          'Alliance',
          'Society',
          'Association',
        ])}`;
        break;
      case 'k12':
        name = `${faker.location.street()} ${faker.helpers.arrayElement([
          'High School',
          'Academy',
          'Preparatory School',
          'Middle School',
          'Elementary',
        ])}`;
        break;
      default:
        name = faker.company.name();
    }
    
    organizations.push({
      id: generateId(),
      name,
      description: faker.company.catchPhrase(),
      type: orgType,
      metadata: null,
      created_at: createdAt,
      updated_at: createdAt,
    });
  }
  
  // Insert organizations in batches
  await batchProcess(organizations, 50, async (batch) => {
    const { error } = await supabase
      .from('organizations')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting organizations:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${organizations.length} organizations`);
  return organizations;
} 