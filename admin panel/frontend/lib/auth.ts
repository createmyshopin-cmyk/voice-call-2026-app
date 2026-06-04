const TOKEN_KEY = 'coincall_admin_token';
const USER_KEY = 'coincall_admin_user';

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: string;
}

/** Admin console must use only the admin token — not the Flutter app `token`. */
export function getToken(): string {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem(TOKEN_KEY) || '';
}

export function setSession(accessToken: string, user: AdminUser) {
  localStorage.setItem(TOKEN_KEY, accessToken);
  localStorage.removeItem('token');
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function getAdminUser(): AdminUser | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AdminUser;
  } catch {
    return null;
  }
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem('token');
  localStorage.removeItem(USER_KEY);
}

export function isAuthenticated(): boolean {
  return Boolean(getToken() && getAdminUser());
}
