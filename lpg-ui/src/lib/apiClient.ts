// src/lib/apiClient.ts
import logger from './logger';

interface ApiClientOptions {
  baseUrl?: string;
  headers?: Record<string, string>;
}

// Placeholder for getting the auth token
async function getAuthToken(): Promise<string | null> {
  // In a real app, you'd get this from your auth context or local storage
  // For now, this is a placeholder
  // const { token } = useAuth(); // Or similar
  return null;
}

async function apiClient<T>(
  endpoint: string,
  method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' = 'GET',
  body?: any,
  options?: ApiClientOptions
): Promise<T> {
  const config: RequestInit = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  };

  const authToken = await getAuthToken();
  if (authToken) {
    if (config.headers) {
      (config.headers as Record<string, string>)['Authorization'] = `Bearer ${authToken}`;
    }
  }

  if (body) {
    config.body = JSON.stringify(body);
  }

  const baseUrl = options?.baseUrl || process.env.NEXT_PUBLIC_API_URL || '/api'; // Default to /api if no base URL

  try {
    const response = await fetch(`${baseUrl}${endpoint}`, config);

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ message: response.statusText }));
      logger.error(`API Error: ${method} ${endpoint}`, { status: response.status, errorData }, new Error(errorData.message || response.statusText));
      throw new Error(errorData.message || `API request failed with status ${response.status}`);
    }

    // Handle cases where response might be empty (e.g., 204 No Content)
    if (response.status === 204) {
      return undefined as T; 
    }

    const data: T = await response.json();
    logger.info(`API Success: ${method} ${endpoint}`, { status: response.status });
    return data;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'An unknown API error occurred';
    const logContext: Record<string, any> = { body };
    if (options !== undefined) {
      logContext.options = options;
    }
    logger.error(`API Request Failed: ${method} ${endpoint}`, logContext, error instanceof Error ? error : new Error(String(error)));
    throw new Error(errorMessage);
  }
}

export default apiClient;