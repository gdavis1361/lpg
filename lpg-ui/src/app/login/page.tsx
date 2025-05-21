'use client';

import { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/contexts/AuthContext'; // Import useAuth
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'; // Keep for password auth for now
import { Database } from '@/types/supabase';


export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  // const [loading, setLoading] = useState(false); // loading state will come from useAuth
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  
  const router = useRouter();
  const searchParams = useSearchParams();
  const redirectUrl = searchParams.get('redirectUrl') || '/dashboard';
  const { signInWithOtp, loading: authLoading } = useAuth(); // Use loading from context

  // Password sign-in still uses local Supabase client for now
  const handleSignInWithPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    // setLoading(true);
    const tempLoadingSetter = (val: boolean) => {}; // Placeholder if we need local loading for this
    tempLoadingSetter(true);
    setError(null);
    setSuccessMessage(null);
    
    const supabase = createClientComponentClient<Database>();
    
    try {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      
      if (signInError) {
        setError(signInError.message);
      } else {
        router.push(redirectUrl);
      }
    } catch (err) {
      setError('An unexpected error occurred. Please try again.');
      console.error('Login error:', err);
    } finally {
      // setLoading(false);
      tempLoadingSetter(false);
    }
  };
  
  const handleSignInWithMagicLink = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccessMessage(null);
    
    if (!email) {
      setError('Please enter your email address');
      return;
    }
        
    try {
      const { error: otpError } = await signInWithOtp(email); // Use context signInWithOtp
      
      if (otpError) {
        setError(otpError.message);
      } else {
        setSuccessMessage('Check your email for the login link!');
      }
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred. Please try again.');
      console.error('Magic link error:', err);
    }
  };
  
  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="text-2xl font-bold text-center">Sign in to your account</CardTitle>
          <CardDescription className="text-center">
            Enter your credentials or use a magic link.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {error && (
            <div className="rounded-md bg-destructive/10 p-3">
              <p className="text-sm text-destructive">{error}</p>
            </div>
          )}
          {successMessage && (
            <div className="rounded-md bg-green-500/10 p-3">
              <p className="text-sm text-green-700 dark:text-green-400">{successMessage}</p>
            </div>
          )}
          <form onSubmit={handleSignInWithPassword} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email-address">Email address</Label>
              <Input
                id="email-address"
                name="email"
                type="email"
                autoComplete="email"
                required
                placeholder="you@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={authLoading}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                disabled={authLoading}
              />
            </div>
            <Button type="submit" className="w-full" disabled={authLoading}>
              {authLoading && email && password ? 'Signing in...' : 'Sign in with password'}
            </Button>
          </form>
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-background px-2 text-muted-foreground">
                Or continue with
              </span>
            </div>
          </div>
          <Button
            type="button"
            variant="outline"
            className="w-full"
            onClick={handleSignInWithMagicLink}
            disabled={authLoading || !email}
          >
            {authLoading && email && !password ? 'Sending link...' : 'Sign in with magic link'}
          </Button>
        </CardContent>
        {/* <CardFooter>
          {/* Optional footer content, e.g., link to sign up * /}
        </CardFooter> */}
      </Card>
    </div>
  );
}
