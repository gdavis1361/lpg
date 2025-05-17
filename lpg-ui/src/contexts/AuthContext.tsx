// src/contexts/AuthContext.tsx
"use client";

import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { createClientComponentClient, User } from '@supabase/auth-helpers-nextjs';
import { Database } from '@/supabase-types'; // Your generated Supabase types
import logger from '@/lib/logger'; // Import the logger

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signInWithOtp: (email: string) => Promise<any>; // Adjust return type as needed
  signOut: () => Promise<any>; // Adjust return type as needed
  // Add other auth methods as needed (e.g., signInWithPassword, signInWithOAuth)
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const supabase = createClientComponentClient<Database>();
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const getSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      setUser(session?.user ?? null);
      setLoading(false);
    };

    getSession();

    const { data: authListener } = supabase.auth.onAuthStateChange((event, session) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => {
      authListener?.unsubscribe();
    };
  }, [supabase]);

  const signInWithOtp = async (email: string) => {
    setLoading(true);
    try {
      logger.info('Attempting OTP sign-in', { email });
      const { error, data } = await supabase.auth.signInWithOtp({
        email,
        options: {
          // emailRedirectTo: `${window.location.origin}/auth/callback`, // Or your desired callback URL
        },
      });
      setLoading(false);
      if (error) {
        logger.error('OTP sign-in failed', { email }, error);
        throw error;
      }
      logger.info('OTP sign-in successful', { email, data });
      return { error, data };
    } catch (err) {
      setLoading(false);
      const castedError = err as Error;
      logger.error('Exception during OTP sign-in', { email }, castedError);
      throw castedError;
    }
  };

  const signOut = async () => {
    setLoading(true);
    try {
      logger.info('Attempting sign-out');
      const { error } = await supabase.auth.signOut();
      setLoading(false);
      if (error) {
        logger.error('Sign-out failed', {}, error);
        throw error;
      }
      logger.info('Sign-out successful');
      setUser(null); // Explicitly set user to null on sign out
      return { error };
    } catch (err) {
      setLoading(false);
      const castedError = err as Error;
      logger.error('Exception during sign-out', {}, castedError);
      throw castedError;
    }
  };

  const value = {
    user,
    loading,
    signInWithOtp,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};