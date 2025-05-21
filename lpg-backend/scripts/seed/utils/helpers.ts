import { faker } from '@faker-js/faker';
import { v4 as uuidv4 } from 'uuid';

/**
 * Generate a unique ID (UUID)
 */
export function generateId(): string {
  return uuidv4();
}

/**
 * Generate a timestamp within a range
 * @param startDate The earliest possible date
 * @param endDate The latest possible date (defaults to now)
 */
export function generateTimestamp(startDate: Date, endDate: Date = new Date()): string {
  return faker.date.between({ from: startDate, to: endDate }).toISOString();
}

/**
 * Generate a date within a range
 * @param startDate The earliest possible date
 * @param endDate The latest possible date (defaults to now)
 */
export function generateDate(startDate: Date, endDate: Date = new Date()): string {
  return faker.date.between({ from: startDate, to: endDate }).toISOString().split('T')[0];
}

/**
 * Generate a random boolean with weighted probability
 * @param probability Probability of true (0-1)
 */
export function generateBoolean(probability: number = 0.5): boolean {
  return Math.random() < probability;
}

/**
 * Generate a random number within a range
 * @param min Minimum value (inclusive)
 * @param max Maximum value (inclusive)
 */
export function generateNumber(min: number, max: number): number {
  return faker.number.int({ min, max });
}

/**
 * Pick a random item from an array
 * @param array The array to pick from
 */
export function pickRandom<T>(array: T[]): T {
  return faker.helpers.arrayElement(array);
}

/**
 * Pick multiple random items from an array
 * @param array The array to pick from
 * @param count Number of items to pick
 */
export function pickRandomMultiple<T>(array: T[], count: number): T[] {
  return faker.helpers.arrayElements(array, count);
}

/**
 * Pick a random item from an array with weighted probability
 * @param items Array of items with weights
 */
export function pickWeighted<T>(items: { item: T; weight: number }[]): T {
  const totalWeight = items.reduce((sum, { weight }) => sum + weight, 0);
  let random = Math.random() * totalWeight;
  
  for (const { item, weight } of items) {
    random -= weight;
    if (random <= 0) {
      return item;
    }
  }
  
  // Fallback
  return items[0].item;
}

/**
 * Generate a random color in hex format
 */
export function generateColor(): string {
  return faker.internet.color();
}

/**
 * Batch inserts to avoid request size limits
 * @param items Array of items to insert
 * @param batchSize Maximum items per batch
 * @param insertFn Function to execute for each batch
 */
export async function batchProcess<T>(
  items: T[],
  batchSize: number,
  processFn: (batch: T[]) => Promise<any>
): Promise<any[]> {
  const results = [];
  
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const result = await processFn(batch);
    results.push(result);
  }
  
  return results;
}

/**
 * Create a deterministic UUID based on a string
 * Useful for creating special test cases with known IDs
 * @param key A string key to derive the UUID from
 */
export function deterministicUuid(key: string): string {
  // Simple implementation - not cryptographically secure
  // but good enough for test data generation
  const hash = Array.from(key)
    .reduce((acc, char) => acc + char.charCodeAt(0), 0)
    .toString(16)
    .padStart(8, '0');
  
  return `${hash.slice(0, 8)}-${hash.slice(0, 4)}-4${hash.slice(1, 4)}-${
    '89ab'[Math.floor(Math.random() * 4)]
  }${hash.slice(0, 3)}-${hash.slice(0, 12)}`;
} 