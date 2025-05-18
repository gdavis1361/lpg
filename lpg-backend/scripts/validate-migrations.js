#!/usr/bin/env node

/**
 * Supabase Migration Validation Script
 * 
 * This script performs validation checks on Supabase migrations to ensure data integrity
 * and prevent constraint violations before applying migrations to production.
 * 
 * The validation checks are extracted from the safeguard blocks in the migration plan
 * and converted to reusable functions that can be run both locally and in CI/CD.
 * 
 * Usage:
 *   node validate-migrations.js [--branch=<branch-id>] [--check=<check-name>]
 * 
 * Options:
 *   --branch=<branch-id>  Specify a Supabase branch ID to validate against
 *   --check=<check-name>  Run a specific check only (e.g., 'unmapped-relationships', 'duplicate-relationships')
 *   --help                Show help information
 * 
 * Examples:
 *   node validate-migrations.js --branch=abcdef-ghijk-12345
 *   node validate-migrations.js --check=unmapped-relationships
 */

import { createClient } from '@supabase/supabase-js';
import { parseArgs } from 'node:util';

// Parse command line arguments
const options = {
  branch: { type: 'string' },
  check: { type: 'string' },
  help: { type: 'boolean' }
};

const { values: args } = parseArgs({ options });

// Show help if requested
if (args.help) {
  console.log(`
Supabase Migration Validation Script

Usage:
  node validate-migrations.js [--branch=<branch-id>] [--check=<check-name>]

Options:
  --branch=<branch-id>  Specify a Supabase branch ID to validate against
  --check=<check-name>  Run a specific check only (e.g., 'unmapped-relationships', 'duplicate-relationships')
  --help                Show help information

Examples:
  node validate-migrations.js --branch=abcdef-ghijk-12345
  node validate-migrations.js --check=unmapped-relationships
  `);
  process.exit(0);
}

// Initialize Supabase client with environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

if (!supabaseUrl || !supabaseKey) {
  console.error('ERROR: Required environment variables not found.');
  console.error('Make sure NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set.');
  console.error('When running locally, use:');
  console.error('  doppler run --project lpg --config dev -- node scripts/validate-migrations.js');
  process.exit(1);
}

// Create Supabase client
let supabase = createClient(supabaseUrl, supabaseKey);

// If branch is specified, connect to the branch environment
if (args.branch) {
  console.log(`Connecting to Supabase branch: ${args.branch}`);
  supabase = createClient(supabaseUrl, supabaseKey, {
    db: {
      schema: 'public',
    },
    global: {
      headers: {
        'x-supabase-db-branch-id': args.branch,
      },
    },
  });
}

/**
 * Validation Checks
 * 
 * These functions are extracted from the safeguard blocks in the migration plan
 * and converted to reusable functions that can be run both locally and in CI/CD.
 */

/**
 * Check for unmapped relationship_type values
 * 
 * This check corresponds to Safeguard Block 1 in the migration plan:
 * Ensures that all relationship_type values in the relationships table
 * can be mapped to a corresponding entry in the relationship_types table.
 */
async function checkUnmappedRelationshipTypes() {
  console.log('Checking for unmapped relationship_type values...');
  
  // Replicating the SQL query from Safeguard Block 1
  const { data, error } = await supabase.rpc('check_unmapped_relationship_types', {});
  
  if (error) {
    console.error('Error checking unmapped relationship types:', error.message);
    return { success: false, error: error.message };
  }
  
  if (!data || data.length === 0) {
    console.log('✅ No unmapped relationship types found.');
    return { success: true, count: 0 };
  }
  
  const { unmapped_count, sample_types } = data[0];
  
  if (unmapped_count > 0) {
    console.error(`❌ Found ${unmapped_count} unmapped relationship_type values.`);
    console.error(`Sample problematic types: ${sample_types || 'None'}`);
    return { 
      success: false, 
      count: unmapped_count, 
      samples: sample_types 
    };
  }
  
  console.log('✅ All relationship types are properly mapped.');
  return { success: true, count: 0 };
}

/**
 * Check for duplicate active relationships
 * 
 * This check corresponds to Safeguard Block 2 in the migration plan:
 * Ensures there are no duplicate active relationships that would violate
 * the unique index on (from_person_id, to_person_id, relationship_type_id).
 */
async function checkDuplicateActiveRelationships() {
  console.log('Checking for duplicate active relationships...');
  
  // Replicating the SQL query from Safeguard Block 2
  const { data, error } = await supabase.rpc('check_duplicate_active_relationships', {});
  
  if (error) {
    console.error('Error checking duplicate active relationships:', error.message);
    return { success: false, error: error.message };
  }
  
  if (!data || data.length === 0) {
    console.log('✅ No duplicate active relationships found.');
    return { success: true, count: 0 };
  }
  
  const { duplicate_group_count } = data[0];
  
  if (duplicate_group_count > 0) {
    console.error(`❌ Found ${duplicate_group_count} groups of duplicate active relationships.`);
    console.error('These duplicates would violate the unique index.');
    return { 
      success: false, 
      count: duplicate_group_count
    };
  }
  
  console.log('✅ No duplicate active relationships found.');
  return { success: true, count: 0 };
}

/**
 * Run all validation checks or a specific check
 */
async function runValidations() {
  console.log('Running Supabase Migration Validation Checks...');
  console.log('------------------------------------------------');
  
  let allChecksSucceeded = true;
  const results = {};
  
  try {
    // Check if helper functions exist - this is just a check to ensure the DB is accessible
    const { data: functions, error: functionsError } = await supabase
      .from('pg_proc')
      .select('proname')
      .in('proname', ['check_unmapped_relationship_types', 'check_duplicate_active_relationships'])
      .limit(10);
    
    if (functionsError) {
      console.warn('Warning: Could not verify validation functions exist. Some checks may fail:', functionsError.message);
      console.log('Continuing with validations...');
    } else {
      const existingFunctions = (functions || []).map(fn => fn.proname);
      if (!existingFunctions.includes('check_unmapped_relationship_types') || 
          !existingFunctions.includes('check_duplicate_active_relationships')) {
        console.warn('Warning: One or more validation helper functions not found in database.');
        console.warn('You may need to run the migration creating these functions first.');
      }
    }
    
    // Run checks based on command line args
    if (!args.check || args.check === 'unmapped-relationships') {
      results.unmappedRelationships = await checkUnmappedRelationshipTypes();
      allChecksSucceeded = allChecksSucceeded && results.unmappedRelationships.success;
    }
    
    if (!args.check || args.check === 'duplicate-relationships') {
      results.duplicateRelationships = await checkDuplicateActiveRelationships();
      allChecksSucceeded = allChecksSucceeded && results.duplicateRelationships.success;
    }
    
    console.log('------------------------------------------------');
    if (allChecksSucceeded) {
      console.log('✅ All validation checks passed successfully!');
    } else {
      console.error('❌ One or more validation checks failed.');
      process.exit(1);
    }
  } catch (error) {
    console.error('Error running validations:', error.message);
    process.exit(1);
  }
}

// Run the validations
runValidations();
