import { API_BASE, fetchJsonAuth } from './api';

export type OnlineStatus = 'online' | 'offline';

export interface AdminUserListItem {
  id: string;
  avatarUrl: string | null;
  fullName: string;
  gender: string | null;
  age: number | null;
  ageLabel: string | null;
  phone: string;
  walletBalance: number;
  totalCalls: number;
  totalMinutes: number;
  onlineStatus: OnlineStatus;
  onboardingCompleted: boolean;
  accountStatus: 'active' | 'blocked' | 'suspended';
  createdAt: string;
  isCreator: boolean;
}

export interface AdminUsersListResponse {
  users: AdminUserListItem[];
  total: number;
}

export interface AdminUserDetail {
  id: string;
  fullName: string;
  gender: string | null;
  dateOfBirth: string | null;
  age: number | null;
  ageLabel: string | null;
  avatarUrl: string | null;
  phone: string;
  email: string | null;
  firebaseUid: string | null;
  language: string | null;
  walletBalance: number;
  onboardingCompleted: boolean;
  onlineStatus: OnlineStatus;
  isCreator: boolean;
  creatorStatus: 'none' | 'active';
  isVerified: boolean;
  blocked: boolean;
  status: 'active' | 'blocked' | 'suspended';
  accountCreatedAt: string;
  updatedAt: string | null;
  totalCalls: number;
  totalMinutes: number;
  totalCoinsSpent: number;
  callStatistics: {
    totalCalls: number;
    completedCalls: number;
    rejectedCalls: number;
    totalMinutes: number;
    totalCoinsSpent: number;
    averageCallDurationSeconds: number;
    averageCallDurationLabel: string;
  };
  recentTransactions: {
    id: string;
    date: string;
    type: string;
    coins: number;
    description: string;
  }[];
}

export interface ListUsersParams {
  page?: number;
  limit?: number;
  search?: string;
  gender?: 'all' | 'male' | 'female';
  status?: 'all' | 'online' | 'offline';
  onboarding?: 'all' | 'completed' | 'not_completed';
  sortBy?: 'createdAt' | 'fullName' | 'coins' | 'totalCalls';
  sortOrder?: 'asc' | 'desc';
  isCreator?: 'all' | 'listener' | 'non_listener';
}

export function buildUsersQuery(params: ListUsersParams): string {
  const q = new URLSearchParams();
  if (params.page) q.set('page', String(params.page));
  if (params.limit) q.set('limit', String(params.limit));
  if (params.search?.trim()) q.set('search', params.search.trim());
  if (params.gender && params.gender !== 'all') q.set('gender', params.gender);
  if (params.status && params.status !== 'all') q.set('status', params.status);
  if (params.onboarding && params.onboarding !== 'all') {
    q.set('onboarding', params.onboarding);
  }
  if (params.sortBy) q.set('sortBy', params.sortBy);
  if (params.sortOrder) q.set('sortOrder', params.sortOrder);
  if (params.isCreator && params.isCreator !== 'all') {
    q.set('isCreator', params.isCreator);
  }
  return q.toString();
}

export async function fetchAdminUsers(params: ListUsersParams) {
  const qs = buildUsersQuery(params);
  return fetchJsonAuth(`${API_BASE}/admin/users${qs ? `?${qs}` : ''}`);
}

export async function fetchAdminUserDetail(id: string) {
  return fetchJsonAuth(`${API_BASE}/admin/users/${id}`);
}

export async function blockUser(id: string) {
  return fetchJsonAuth(`${API_BASE}/admin/users/${id}/block`, { method: 'POST' });
}

export async function unblockUser(id: string) {
  return fetchJsonAuth(`${API_BASE}/admin/users/${id}/unblock`, { method: 'POST' });
}

export async function suspendUser(id: string) {
  return fetchJsonAuth(`${API_BASE}/admin/users/${id}/suspend`, { method: 'POST' });
}

export async function reactivateUser(id: string) {
  return fetchJsonAuth(`${API_BASE}/admin/users/${id}/reactivate`, { method: 'POST' });
}

export const DEFAULT_AVATAR =
  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&h=150&fit=crop';

export function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return iso;
  }
}

export function formatDateTime(iso: string): string {
  try {
    return new Date(iso).toLocaleString(undefined, {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return iso;
  }
}
