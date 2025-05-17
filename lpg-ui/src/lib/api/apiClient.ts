// src/lib/api/apiClient.ts
import { Database } from '@/supabase-types'; // Assuming types will be generated here

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || '/api'; // Example, adjust as needed

/**
 * Fetches data from the backend API.
 * @param path The API endpoint path (e.g., '/users').
 * @param options Request options (method, headers, body, etc.).
 * @returns A promise that resolves with the JSON response.
 */
async function apiClient<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers = new Headers(options.headers);
  if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  // TODO: Add authentication token management here
  // const token = getAuthToken(); // Implement this function
  // if (token) {
  //   headers.set('Authorization', `Bearer ${token}`);
  // }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    // TODO: Implement consistent error handling
    // Consider logging errors here based on project logging strategy
    const errorData = await response.json().catch(() => ({ message: response.statusText }));
    console.error('API Error:', errorData);
    throw new Error(errorData.message || 'API request failed');
  }

  // Handle cases where response might be empty (e.g., 204 No Content)
  if (response.status === 204) {
    return null as T; // Or handle as appropriate for your application
  }

  return response.json() as Promise<T>;
}

export default apiClient;

// Example usage (you'll define more specific functions based on your API):

// type User = Database['public']['Tables']['users']['Row']; // Example if you have a users table

// export const getUsers = () => apiClient<User[]>('/users');

// export const createUser = (data: Omit<User, 'id' | 'created_at'>) => 
//   apiClient<User>('/users', { method: 'POST', body: JSON.stringify(data) });