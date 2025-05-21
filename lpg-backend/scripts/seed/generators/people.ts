import { faker } from '@faker-js/faker';
import { SupabaseClient } from '@supabase/supabase-js';
import { Person, Organization, ActivityGroup } from '../types/entities';
import { SeedConfig } from '../config';
import { generateId, generateTimestamp, generateBoolean, generateNumber, batchProcess } from '../utils/helpers';
import { logger } from '../utils/logger';
import { Database } from '../../types/supabase';

// Employment statuses
const EMPLOYMENT_STATUSES = [
  'full_time',
  'part_time',
  'intern',
  'unemployed',
  'self_employed',
  'freelance',
  'student',
];

// Post-graduation statuses
const POST_GRAD_STATUSES = [
  'employed',
  'seeking_employment',
  'grad_school',
  'gap_year',
  'service_year',
  'entrepreneurship',
];

/**
 * Generate a list of realistic people
 */
export async function generatePeople(
  supabase: SupabaseClient<Database>,
  config: SeedConfig,
  organizations: Organization[],
  activityGroups: ActivityGroup[]
): Promise<Person[]> {
  logger.info(`Generating ${config.people} people...`);
  
  // First, check if we already have people
  const { data: existingPeople, error: checkError } = await supabase
    .from('people')
    .select('id')
    .limit(1);
    
  if (checkError) {
    logger.error('Error checking existing people:', checkError);
    throw checkError;
  }
  
  if (existingPeople && existingPeople.length > 0) {
    logger.info('People already exist, fetching existing data...');
    const { data: people, error } = await supabase
      .from('people')
      .select('*');
      
    if (error) {
      logger.error('Error fetching people:', error);
      throw error;
    }
    
    logger.success(`Found ${people?.length || 0} existing people`);
    return people || [];
  }
  
  // Generate people data
  const people: Person[] = [];
  
  // Special people (with known IDs for test cases)
  if (config.createSpecialTestCases) {
    // Create a mentor for test cases
    people.push({
      id: 'b0000000-0000-0000-0000-000000000001',
      auth_id: null,
      first_name: 'Test',
      last_name: 'Mentor',
      email: 'test.mentor@example.com',
      phone: '(555) 123-4567',
      birthdate: '1980-01-01',
      graduation_year: 2000,
      avatar_url: `https://ui-avatars.com/api/?name=Test+Mentor&background=random`,
      employment_status: 'full_time',
      post_grad_status: 'employed',
      college_attending: null,
      last_checkin_date: null,
      address: {
        street: '123 Main St',
        city: 'Anytown',
        state: 'CA',
        zip: '90210',
      },
      metadata: { isTestData: true },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });
    
    // Create a student for test cases
    people.push({
      id: 'b0000000-0000-0000-0000-000000000002',
      auth_id: null,
      first_name: 'Test',
      last_name: 'Student',
      email: 'test.student@example.com',
      phone: '(555) 987-6543',
      birthdate: '2000-01-01',
      graduation_year: 2022,
      avatar_url: `https://ui-avatars.com/api/?name=Test+Student&background=random`,
      employment_status: 'student',
      post_grad_status: null,
      college_attending: 'Test University',
      last_checkin_date: new Date().toISOString(),
      address: {
        street: '456 Campus Dr',
        city: 'College Town',
        state: 'CA',
        zip: '90211',
      },
      metadata: { isTestData: true },
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    });
  }
  
  // Generate random people
  for (let i = 0; i < config.people; i++) {
    const now = new Date();
    const createdAt = generateTimestamp(config.startDate, now);
    
    const firstName = faker.person.firstName();
    const lastName = faker.person.lastName();
    const email = faker.internet.email({ firstName, lastName }).toLowerCase();
    
    // Randomly choose if this is a student or graduate
    const isStudent = generateBoolean(0.3);
    const graduationYear = isStudent
      ? faker.number.int({ min: new Date().getFullYear(), max: new Date().getFullYear() + 5 })
      : faker.number.int({ min: 1990, max: new Date().getFullYear() - 1 });
    
    // For students, set a college
    const collegeAttending = isStudent
      ? organizations.find(org => org.type === 'university')?.name || faker.company.name() + ' University'
      : null;
    
    // For graduates, set employment details
    const employmentStatus = isStudent
      ? 'student'
      : faker.helpers.arrayElement(EMPLOYMENT_STATUSES.filter(s => s !== 'student'));
    
    const postGradStatus = !isStudent
      ? faker.helpers.arrayElement(POST_GRAD_STATUSES)
      : null;
    
    const lastCheckinDate = generateBoolean(0.7)
      ? generateTimestamp(new Date(now.getFullYear() - 1, 0, 1), now)
      : null;
    
    // Generate a random avatar URL using UI Avatars service
    const avatarUrl = `https://ui-avatars.com/api/?name=${firstName}+${lastName}&background=random`;
    
    people.push({
      id: generateId(),
      auth_id: null,
      first_name: firstName,
      last_name: lastName,
      email,
      phone: faker.phone.number(),
      birthdate: generateBoolean(0.8)
        ? faker.date.birthdate({ min: 18, max: 65, mode: 'age' }).toISOString().split('T')[0]
        : null,
      graduation_year: graduationYear,
      avatar_url: generateBoolean(0.9) ? avatarUrl : null,
      employment_status: employmentStatus,
      post_grad_status: postGradStatus,
      college_attending: collegeAttending,
      last_checkin_date: lastCheckinDate,
      address: generateBoolean(0.7)
        ? {
            street: faker.location.streetAddress(),
            city: faker.location.city(),
            state: faker.location.state({ abbreviated: true }),
            zip: faker.location.zipCode(),
          }
        : null,
      metadata: null,
      created_at: createdAt,
      updated_at: createdAt,
    });
    
    logger.progress(i + 1, config.people, 'people');
  }
  
  // Insert people in batches (max 50 people per batch to avoid payload size limits)
  await batchProcess(people, 50, async (batch) => {
    const { error } = await supabase
      .from('people')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting people:', error);
      throw error;
    }
  });
  
  // Also create affiliations with organizations
  logger.info('Creating affiliations between people and organizations...');
  
  const affiliations = [];
  
  for (const person of people) {
    // Skip some people to make the data realistic
    if (!generateBoolean(0.8)) continue;
    
    // Assign 1-2 organizations per person
    const numOrgs = generateNumber(1, 2);
    const personOrgs = faker.helpers.arrayElements(organizations, numOrgs);
    
    for (const org of personOrgs) {
      const isPrimary = personOrgs.length === 1 || generateBoolean(0.7);
      
      affiliations.push({
        id: generateId(),
        person_id: person.id,
        organization_id: org.id,
        is_primary: isPrimary,
        role: faker.person.jobTitle(),
        start_date: generateTimestamp(config.startDate, new Date()),
        end_date: generateBoolean(0.2) ? generateTimestamp(config.startDate, new Date()) : null,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  }
  
  // Insert affiliations in batches
  await batchProcess(affiliations, 50, async (batch) => {
    const { error } = await supabase
      .from('affiliations')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting affiliations:', error);
      throw error;
    }
  });
  
  // Create activity memberships for people
  logger.info('Creating activity memberships...');
  
  const activities = [];
  
  for (const person of people) {
    // Skip some people to make the data realistic
    if (!generateBoolean(0.7)) continue;
    
    // Assign 1-3 activity groups per person
    const numGroups = generateNumber(1, 3);
    const personGroups = faker.helpers.arrayElements(activityGroups, numGroups);
    
    for (const group of personGroups) {
      const isPrimary = personGroups.length === 1 || generateBoolean(0.6);
      
      activities.push({
        id: generateId(),
        person_id: person.id,
        activity_group_id: group.id,
        primary_activity: isPrimary,
        role: faker.helpers.arrayElement(['member', 'leader', 'coordinator', 'participant']),
        joined_at: generateTimestamp(config.startDate, new Date()),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });
    }
  }
  
  // Insert activities in batches
  await batchProcess(activities, 50, async (batch) => {
    const { error } = await supabase
      .from('person_activities')
      .insert(batch);
      
    if (error) {
      logger.error('Error inserting person activities:', error);
      throw error;
    }
  });
  
  logger.success(`Successfully generated ${people.length} people with affiliations and activities`);
  return people;
} 