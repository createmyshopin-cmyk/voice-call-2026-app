import { API_BASE } from '../api';

export type ReleaseType = 'optional' | 'force' | 'maintenance';

export type NotificationTarget =
  | 'all'
  | 'users'
  | 'creators'
  | 'new_superhosts'
  | 'pro_superhosts'
  | 'legend_superhosts';

export interface AppVersionSettings {
  id: string;
  latestVersion: string;
  minimumSupportedVersion: string;
  forceUpdate: boolean;
  releaseType: ReleaseType;
  title: string;
  message: string;
  playStoreUrl: string;
  appStoreUrl: string;
  maintenanceMode: boolean;
  maintenanceTitle: string;
  maintenanceMessage: string;
  maintenanceDurationMinutes: number;
  updatedAt: string;
}

export interface AppRelease {
  id: string;
  version: string;
  buildNumber: number;
  releaseType: ReleaseType;
  title: string;
  message: string;
  changelog: string;
  playStoreUrl: string;
  appStoreUrl: string;
  isActive: boolean;
  createdBy: string | null;
  createdAt: string;
}

export interface VersionAnalytics {
  totalReported: number;
  onLatest: number;
  outdated: number;
  blocked: number;
  adoptionPercent: number;
  usersByVersion: { version: string; count: number; platform?: string }[];
  latestVersion: string;
  minimumSupportedVersion: string;
}

export const releasesApi = {
  settings: () => `${API_BASE}/admin/app-version`,
  analytics: () => `${API_BASE}/admin/app-version/analytics`,
  list: () => `${API_BASE}/admin/releases`,
  one: (id: string) => `${API_BASE}/admin/releases/${id}`,
  sendNotification: () => `${API_BASE}/admin/releases/send-notification`,
};
