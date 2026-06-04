// lib/api.ts

import { getToken, clearSession } from './auth';

export const API_BASE =
  process.env.NEXT_PUBLIC_API_URL || 'https://backend-api-production-140f.up.railway.app/api';

export function getHeaders(): Record<string, string> {
  if (typeof window === 'undefined') {
    return {
      'Content-Type': 'application/json',
    };
  }
  const token = getToken();
  return {
    Authorization: token ? `Bearer ${token}` : '',
    'Content-Type': 'application/json',
  };
}

export type ApiFailureReason = 'unauthorized' | 'forbidden' | 'network' | 'server' | 'unknown';

export function classifyApiFailure(status: number): ApiFailureReason {
  if (status === 401) return 'unauthorized';
  if (status === 403) return 'forbidden';
  if (status >= 500) return 'server';
  return 'unknown';
}

export function connectionErrorMessage(reason: ApiFailureReason): string {
  switch (reason) {
    case 'unauthorized':
      return 'Session expired or invalid. Please sign in again.';
    case 'forbidden':
      return 'This browser has a non-admin token. Sign out and sign in with an admin account.';
    case 'network':
      return 'Cannot reach the API. Check NEXT_PUBLIC_API_URL and that Railway is running.';
    case 'server':
      return 'API server error. Try again in a moment.';
    default:
      return 'Could not load live data. Sign in at /login with admin@coincalling.com';
  }
}

/** Redirect to login when admin token is rejected. */
export function handleAuthFailure(status: number): void {
  if (typeof window === 'undefined') return;
  if (status === 401 || status === 403) {
    clearSession();
    const next = encodeURIComponent(window.location.pathname);
    window.location.href = `/login?reason=${status === 403 ? 'forbidden' : 'expired'}&next=${next}`;
  }
}

export async function fetchWithAuth(url: string, options: RequestInit = {}) {
  const headers = { ...getHeaders(), ...options.headers };
  const response = await fetch(url, { ...options, headers });
  if (response.status === 401 || response.status === 403) {
    handleAuthFailure(response.status);
  }
  return response;
}

export async function fetchJsonAuth(url: string, options: RequestInit = {}) {
  try {
    const response = await fetchWithAuth(url, options);
    const text = await response.text();
    let data: unknown = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }
    return { ok: response.ok, status: response.status, data };
  } catch {
    return { ok: false, status: 0, data: null };
  }
}
