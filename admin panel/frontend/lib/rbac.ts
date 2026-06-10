import type { AdminUser } from './auth';

export type AdminRole =
  | 'super_admin'
  | 'finance_admin'
  | 'moderator'
  | 'support_admin'
  | 'fraud_admin'
  | 'operations_admin';

export type AdminModule =
  | 'dashboard'
  | 'finance'
  | 'creator_analytics'
  | 'withdrawals'
  | 'gifts'
  | 'messages'
  | 'vip'
  | 'missions'
  | 'streaks'
  | 'follows'
  | 'levels'
  | 'training'
  | 'users'
  | 'listeners'
  | 'wallet'
  | 'coins'
  | 'payments'
  | 'calls'
  | 'reconciliation'
  | 'health'
  | 'operations'
  | 'notifications'
  | 'safety'
  | 'settings'
  | 'admins';

const MODULE_ROLES: Record<AdminModule, AdminRole[]> = {
  dashboard: ['super_admin', 'finance_admin', 'operations_admin', 'moderator', 'support_admin', 'fraud_admin'],
  finance: ['super_admin', 'finance_admin', 'operations_admin', 'fraud_admin'],
  creator_analytics: ['super_admin', 'finance_admin', 'operations_admin', 'fraud_admin'],
  withdrawals: ['super_admin', 'finance_admin', 'support_admin'],
  gifts: ['super_admin', 'finance_admin', 'operations_admin'],
  messages: ['super_admin', 'finance_admin', 'operations_admin'],
  vip: ['super_admin', 'finance_admin', 'operations_admin'],
  missions: ['super_admin', 'operations_admin', 'moderator'],
  streaks: ['super_admin', 'operations_admin', 'moderator'],
  follows: ['super_admin', 'operations_admin', 'moderator'],
  levels: ['super_admin', 'operations_admin', 'moderator'],
  training: ['super_admin', 'operations_admin'],
  users: ['super_admin', 'moderator', 'support_admin', 'fraud_admin'],
  listeners: ['super_admin', 'operations_admin', 'moderator', 'support_admin', 'fraud_admin'],
  wallet: ['super_admin', 'finance_admin', 'support_admin'],
  coins: ['super_admin', 'finance_admin', 'operations_admin'],
  payments: ['super_admin', 'finance_admin', 'support_admin'],
  calls: ['super_admin', 'operations_admin', 'moderator', 'fraud_admin', 'support_admin'],
  reconciliation: ['super_admin', 'finance_admin'],
  health: ['super_admin', 'operations_admin', 'fraud_admin'],
  operations: ['super_admin', 'finance_admin', 'operations_admin', 'fraud_admin'],
  notifications: ['super_admin', 'operations_admin', 'moderator'],
  safety: ['super_admin', 'moderator', 'fraud_admin'],
  settings: ['super_admin', 'operations_admin'],
  admins: ['super_admin'],
};

export function canAccessModule(user: AdminUser | null, module: AdminModule): boolean {
  if (!user?.role) return false;
  const allowed = MODULE_ROLES[module];
  return allowed.includes(user.role as AdminRole);
}

export function filterNavByRole<T extends { id: string }>(
  items: T[],
  user: AdminUser | null,
  idToModule: (id: string) => AdminModule,
): T[] {
  return items.filter((item) => canAccessModule(user, idToModule(item.id)));
}
