#!/usr/bin/env ts-node
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { defaultConfig, devConfig, specialCasesConfig, SeedConfig } from './config';
import { generateOrganizations } from './generators/organizations';
import { generateActivityGroups } from './generators/activityGroups';
import { generatePeople } from './generators/people';
import { generateTags } from './generators/tags';
import { generateRelationships } from './generators/relationships';
import { generateMilestones } from './generators/milestones';
import { generateInteractions } from './generators/interactions';
import { generateSpecialCases } from './generators/specialCases';
import { Database } from '../types/supabase';
import { logger } from './utils/logger';

// Load environment variables
dotenv.config();

// Get Supabase credentials from environment
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  logger.error('Missing Supabase credentials. Check environment variables.');
  process.exit(1);
}

// Create Supabase client with admin privileges
const supabase = createClient<Database>(supabaseUrl, supabaseServiceKey);

// Parse command line arguments
const args = process.argv.slice(2);
let config: SeedConfig = defaultConfig;

if (args.includes('--dev')) {
  config = devConfig;
  logger.info('Using development configuration');
} else if (args.includes('--special-cases')) {
  config = specialCasesConfig;
  logger.info('Using special cases configuration');
}

// Check for safety flag to prevent accidental production seeding
const forceSeed = args.includes('--force');
if (process.env.NODE_ENV === 'production' && !forceSeed) {
  logger.error('Refusing to seed production database without --force flag');
  process.exit(1);
}

// Main seeding function
async function seedDatabase() {
  try {
    logger.info('Starting database seeding process...');
    logger.info(`Config: ${JSON.stringify(config, null, 2)}`);

    // Generate data in the correct dependency order
    logger.info('Generating organizations...');
    const organizations = await generateOrganizations(supabase, config);
    
    logger.info('Generating activity groups...');
    const activityGroups = await generateActivityGroups(supabase, config);
    
    logger.info('Generating tags...');
    const tags = await generateTags(supabase, config);
    
    logger.info('Generating people...');
    const people = await generatePeople(supabase, config, organizations, activityGroups);
    
    logger.info('Generating relationships...');
    const relationships = await generateRelationships(supabase, config, people);
    
    logger.info('Generating milestones...');
    await generateMilestones(supabase, config, relationships);
    
    logger.info('Generating interactions...');
    await generateInteractions(supabase, config, people, relationships);
    
    // Generate special test cases if configured
    if (config.createSpecialTestCases) {
      logger.info('Generating special test cases...');
      await generateSpecialCases(supabase, config, people, relationships, activityGroups);
    }
    
    logger.info('Database seeding completed successfully!');
    
    // Output summary
    logger.info('Seeding summary:');
    logger.info(`- Organizations: ${organizations.length}`);
    logger.info(`- Activity Groups: ${activityGroups.length}`);
    logger.info(`- People: ${people.length}`);
    logger.info(`- Relationships: ${relationships.length}`);
    logger.info(`- Tags: ${tags.length}`);
    
  } catch (error) {
    logger.error('Error during database seeding:', error);
    process.exit(1);
  }
}

// Run the seeding process
seedDatabase(); 