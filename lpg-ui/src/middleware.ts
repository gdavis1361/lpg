// src/middleware.ts
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import type { Database } from './types/supabase';

// Define public routes that don't require authentication
const PUBLIC_ROUTES = [
  '/',
  '/login',
  '/signup',
  '/api/auth/callback',
];

export async function middleware(request: NextRequest) {
  // Create a Supabase client for the middleware
  const response = NextResponse.next();
  const supabase = createMiddlewareClient<Database>({ req: request, res: response });

  // Refresh the session if it exists
  const { data: { session } } = await supabase.auth.getSession();

  // Check if the route is public or if the user is authenticated
  const pathname = request.nextUrl.pathname;
  const isPublicRoute = PUBLIC_ROUTES.some(route => pathname === route || pathname.startsWith(route));

  // If it's a non-public route and user isn't authenticated, redirect to login
  if (!isPublicRoute && !session) {
    const redirectUrl = new URL('/login', request.url);
    // Store the original URL to redirect back after login
    redirectUrl.searchParams.set('redirectUrl', pathname);
    return NextResponse.redirect(redirectUrl);
  }

  // If it's the login page and user is authenticated, redirect to dashboard
  if ((pathname === '/login' || pathname === '/signup') && session) {
    const redirectUrl = new URL('/dashboard', request.url);
    return NextResponse.redirect(redirectUrl);
  }

  return response;
}

// Define which routes the middleware should run on
export const config = {
  matcher: [
    // Run on all routes except for static assets, API routes that don't need auth, and _next
    '/((?!_next/static|_next/image|favicon.ico|images/|fonts/|public/).*)',
  ],
}; 