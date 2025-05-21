#!/bin/bash

# Script to handle database seeding operations for LPG project
# This script provides an easy way to seed, reset, or check the database

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_heading() {
  echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}! $1${NC}"
}

print_help() {
  echo -e "Database Seeding Script for LPG Project"
  echo -e "---------------------------------------"
  echo -e "Usage: ./seed-database.sh [command]"
  echo -e ""
  echo -e "Commands:"
  echo -e "  seed              Full seed with default dataset"
  echo -e "  seed:dev          Seed with smaller development dataset"
  echo -e "  seed:special      Seed with only special test cases"
  echo -e "  reset             Reset (clear) all data from the database"
  echo -e "  reset:tables      Reset specific tables (interactive)"
  echo -e "  status            Check database status"
  echo -e "  help              Show this help message"
  echo -e ""
}

check_dependencies() {
  print_heading "Checking dependencies"
  
  # Check if we're in the project root directory
  if [ ! -d "lpg-backend" ]; then
    print_error "This script must be run from the project root directory"
    exit 1
  fi
  
  # Check if Node.js is installed
  if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed"
    exit 1
  fi
  
  # Check if npm is installed
  if ! command -v npm &> /dev/null; then
    print_error "npm is not installed"
    exit 1
  fi
  
  print_success "All dependencies are available"
}

check_env() {
  print_heading "Checking environment"
  
  # Check if .env file exists
  if [ ! -f "lpg-backend/.env" ]; then
    print_warning "No .env file found in lpg-backend directory"
    
    # Create a basic .env file if it doesn't exist
    echo "Would you like to create a basic .env file? (y/n)"
    read -r create_env
    
    if [[ $create_env == "y" ]]; then
      echo "Enter your Supabase URL (e.g., https://yourproject.supabase.co):"
      read -r supabase_url
      
      echo "Enter your Supabase service role key:"
      read -r supabase_key
      
      # Create the .env file
      cat > lpg-backend/.env << EOL
NEXT_PUBLIC_SUPABASE_URL=$supabase_url
SUPABASE_SERVICE_ROLE_KEY=$supabase_key
EOL
      
      print_success "Created .env file with your credentials"
    else
      print_warning "Continuing without .env file. Seeding may fail if environment variables are not set."
    fi
  else
    print_success "Found .env file in lpg-backend directory"
  fi
}

setup_backend() {
  print_heading "Setting up backend"
  
  # Navigate to the backend directory
  cd lpg-backend || exit 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    print_warning "No node_modules found, installing dependencies..."
    npm install --no-optional
  fi
  
  # Return to the project root
  cd ..
  
  print_success "Backend setup complete"
}

seed_database() {
  print_heading "Seeding database with $1 data"
  
  # Navigate to the backend directory
  cd lpg-backend || exit 1
  
  # Run the appropriate seed command
  case $1 in
    "full")
      npm run seed
      ;;
    "dev")
      npm run seed:dev
      ;;
    "special")
      npm run seed:special
      ;;
    *)
      npm run seed
      ;;
  esac
  
  # Check if the seeding was successful
  if [ $? -eq 0 ]; then
    print_success "Database seeding completed successfully"
  else
    print_error "Database seeding failed"
  fi
  
  # Return to the project root
  cd ..
}

reset_database() {
  print_heading "Resetting database"
  
  echo "⚠️  WARNING: This will delete ALL data in the database!"
  echo "Are you sure you want to continue? (y/n)"
  read -r confirm
  
  if [[ $confirm != "y" ]]; then
    print_warning "Database reset cancelled"
    return
  fi
  
  # Create a temporary SQL file for the reset
  cat > lpg-backend/reset-all.sql << EOL
-- Reset all tables in the database
DELETE FROM interactions;
DELETE FROM interaction_participants;
DELETE FROM relationship_milestones;
DELETE FROM relationships;
DELETE FROM person_tags;
DELETE FROM person_activities;
DELETE FROM person_roles;
DELETE FROM affiliations;
DELETE FROM people;
DELETE FROM tags;
DELETE FROM roles;
DELETE FROM activity_groups;
DELETE FROM organizations;
DELETE FROM relationship_types;
DELETE FROM mentor_milestones;
EOL
  
  # Run the SQL file using Supabase CLI or psql
  if command -v supabase &> /dev/null; then
    print_heading "Using Supabase CLI to reset database"
    cd lpg-backend || exit 1
    npx supabase db execute -f reset-all.sql
    cd ..
  else
    print_heading "Using psql to reset database"
    cd lpg-backend || exit 1
    
    # Load environment variables from .env file
    if [ -f ".env" ]; then
      export $(grep -v '^#' .env | xargs)
    fi
    
    # Ask for the database connection string if not available
    if [ -z "$DATABASE_URL" ]; then
      echo "Enter your database connection string:"
      read -r db_url
      export DATABASE_URL=$db_url
    fi
    
    # Execute the SQL file
    psql "$DATABASE_URL" -f reset-all.sql
    
    cd ..
  fi
  
  # Clean up the temporary file
  rm lpg-backend/reset-all.sql
  
  print_success "Database reset completed"
}

reset_specific_tables() {
  print_heading "Reset specific tables"
  
  tables=("interactions" "relationship_milestones" "relationships" "person_activities" "affiliations" "people" "tags" "activity_groups" "organizations")
  selected_tables=()
  
  echo "Select tables to reset (enter numbers separated by space):"
  
  for i in "${!tables[@]}"; do
    echo "$((i+1)). ${tables[$i]}"
  done
  
  read -r selections
  
  for selection in $selections; do
    index=$((selection-1))
    if [ "$index" -ge 0 ] && [ "$index" -lt "${#tables[@]}" ]; then
      selected_tables+=("${tables[$index]}")
    fi
  done
  
  if [ ${#selected_tables[@]} -eq 0 ]; then
    print_warning "No tables selected. Operation cancelled."
    return
  fi
  
  echo "You selected the following tables to reset:"
  for table in "${selected_tables[@]}"; do
    echo "- $table"
  done
  
  echo "Are you sure you want to continue? (y/n)"
  read -r confirm
  
  if [[ $confirm != "y" ]]; then
    print_warning "Reset cancelled"
    return
  fi
  
  # Create a temporary SQL file for the reset
  sql_content="-- Reset selected tables\n"
  for table in "${selected_tables[@]}"; do
    sql_content+="DELETE FROM $table;\n"
  done
  
  echo -e "$sql_content" > lpg-backend/reset-selected.sql
  
  # Run the SQL file using Supabase CLI or psql
  if command -v supabase &> /dev/null; then
    print_heading "Using Supabase CLI to reset tables"
    cd lpg-backend || exit 1
    npx supabase db execute -f reset-selected.sql
    cd ..
  else
    print_heading "Using psql to reset tables"
    cd lpg-backend || exit 1
    
    # Load environment variables from .env file
    if [ -f ".env" ]; then
      export $(grep -v '^#' .env | xargs)
    fi
    
    # Ask for the database connection string if not available
    if [ -z "$DATABASE_URL" ]; then
      echo "Enter your database connection string:"
      read -r db_url
      export DATABASE_URL=$db_url
    fi
    
    # Execute the SQL file
    psql "$DATABASE_URL" -f reset-selected.sql
    
    cd ..
  fi
  
  # Clean up the temporary file
  rm lpg-backend/reset-selected.sql
  
  print_success "Selected tables reset completed"
}

check_database_status() {
  print_heading "Checking database status"
  
  # Navigate to the backend directory
  cd lpg-backend || exit 1
  
  # Create a temporary SQL file for checking table counts
  cat > check-status.sql << EOL
SELECT 'organizations' as table_name, COUNT(*) as count FROM organizations
UNION
SELECT 'people' as table_name, COUNT(*) as count FROM people
UNION
SELECT 'relationships' as table_name, COUNT(*) as count FROM relationships
UNION
SELECT 'activity_groups' as table_name, COUNT(*) as count FROM activity_groups
UNION
SELECT 'tags' as table_name, COUNT(*) as count FROM tags
UNION
SELECT 'interactions' as table_name, COUNT(*) as count FROM interactions
ORDER BY table_name;
EOL
  
  # Run the SQL file using Supabase CLI or psql
  if command -v supabase &> /dev/null; then
    npx supabase db execute -f check-status.sql
  else
    # Load environment variables from .env file
    if [ -f ".env" ]; then
      export $(grep -v '^#' .env | xargs)
    fi
    
    # Ask for the database connection string if not available
    if [ -z "$DATABASE_URL" ]; then
      echo "Enter your database connection string:"
      read -r db_url
      export DATABASE_URL=$db_url
    fi
    
    # Execute the SQL file
    psql "$DATABASE_URL" -f check-status.sql
  fi
  
  # Clean up the temporary file
  rm check-status.sql
  
  # Return to the project root
  cd ..
}

# Main script

# Check if a command was provided
if [ $# -eq 0 ]; then
  print_help
  exit 0
fi

# Process the command
case $1 in
  "seed")
    check_dependencies
    check_env
    setup_backend
    seed_database "full"
    ;;
  "seed:dev")
    check_dependencies
    check_env
    setup_backend
    seed_database "dev"
    ;;
  "seed:special")
    check_dependencies
    check_env
    setup_backend
    seed_database "special"
    ;;
  "reset")
    check_dependencies
    check_env
    reset_database
    ;;
  "reset:tables")
    check_dependencies
    check_env
    reset_specific_tables
    ;;
  "status")
    check_dependencies
    check_env
    check_database_status
    ;;
  "help"|*)
    print_help
    ;;
esac

exit 0 