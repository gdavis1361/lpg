import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Database } from '../types/supabase';

/**
 * Creates a Supabase client for use in client components.
 * This should be called within components that need to interact with Supabase.
 */
export function createClientSupabaseClient() {
  return createClientComponentClient<Database>();
}

/**
 * A helper function to run Supabase queries with error handling.
 * 
 * @example
 * const { data, error } = await withSupabase(
 *   async (supabase) => await supabase.from('people').select('*')
 * );
 */
export async function withSupabase<T>(
  callback: (supabase: ReturnType<typeof createClientSupabaseClient>) => Promise<T>
): Promise<{ data: T | null; error: Error | null }> {
  const supabase = createClientSupabaseClient();
  try {
    const result = await callback(supabase);
    return { data: result, error: null };
  } catch (error) {
    console.error('Supabase operation failed:', error);
    return { data: null, error: error as Error };
  }
} 