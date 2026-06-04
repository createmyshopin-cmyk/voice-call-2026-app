// lib/api.ts

export const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'https://backend-api-production-140f.up.railway.app/api';

import { getToken } from './auth';

export function getHeaders(): Record<string, string> {
  if (typeof window === 'undefined') {
    return {
      'Content-Type': 'application/json',
    };
  }
  const token = getToken();
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

export async function fetchWithAuth(url: string, options: RequestInit = {}) {
  const headers = { ...getHeaders(), ...options.headers };
  const response = await fetch(url, { ...options, headers });
  if (response.status === 401) {
    console.warn('Unauthorized request, token may be expired');
  }
  return response;
}
