// src/lib/supabase-server.ts
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { cache } from 'react';
import { Database } from '../types/supabase';

/**
 * Creates a Supabase client for use in server components.
 * This function is wrapped in React's cache to avoid creating multiple clients.
 */
export const createServerSupabaseClient = cache(() => {
  const cookieStore = cookies();
  return createServerComponentClient<Database>({ cookies: () => cookieStore });
});

/**
 * Gets the session for the current user.
 * This is useful for protecting routes that require authentication.
 */
export async function getSession() {
  const supabase = createServerSupabaseClient();
  try {
    const { data: { session } } = await supabase.auth.getSession();
    return session;
  } catch (error) {
    console.error('Error getting session:', error);
    return null;
  }
}

/**
 * Gets the current user from the session.
 */
export async function getCurrentUser() {
  const session = await getSession();
  return session?.user ?? null;
} 