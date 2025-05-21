// Configuration for database seeding
export interface SeedConfig {
  // Entity counts
  organizations: number;
  activityGroups: number;
  people: number;
  relationshipsPerPerson: number;
  interactionsPerRelationship: number;
  milestonesPerRelationship: number;
  tagsTotal: number;
  
  // Time ranges
  startDate: Date;        // Historical start date for data
  relationshipMaxAgeDays: number;
  interactionMaxAgeDays: number;
  
  // Probabilities
  requiredMilestoneProbability: number;
  activeMentorshipProbability: number;
  healthyRelationshipProbability: number;
  recentInteractionProbability: number;
  
  // Special test cases
  createSpecialTestCases: boolean;
}

// Default configuration
export const defaultConfig: SeedConfig = {
  // Entity counts
  organizations: 5,
  activityGroups: 8,
  people: 50,
  relationshipsPerPerson: 3,
  interactionsPerRelationship: 5,
  milestonesPerRelationship: 2,
  tagsTotal: 20,
  
  // Time ranges (2 years of data)
  startDate: new Date(new Date().setFullYear(new Date().getFullYear() - 2)),
  relationshipMaxAgeDays: 730, // 2 years
  interactionMaxAgeDays: 365,  // 1 year
  
  // Probabilities
  requiredMilestoneProbability: 0.7,
  activeMentorshipProbability: 0.8,
  healthyRelationshipProbability: 0.7,
  recentInteractionProbability: 0.6,
  
  // Special test cases
  createSpecialTestCases: true,
};

// A smaller configuration for development testing
export const devConfig: SeedConfig = {
  ...defaultConfig,
  people: 20,
  relationshipsPerPerson: 2,
  interactionsPerRelationship: 3,
  milestonesPerRelationship: 1,
};

// A configuration that creates just special test cases
export const specialCasesConfig: SeedConfig = {
  ...defaultConfig,
  organizations: 2,
  activityGroups: 3,
  people: 10,
  relationshipsPerPerson: 2,
  interactionsPerRelationship: 2,
  createSpecialTestCases: true,
}; 