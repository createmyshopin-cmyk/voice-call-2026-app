import { describe, it, expect } from 'vitest';
import { canAccessModule } from './rbac';
import type { AdminUser } from './auth';

const user = (role: string): AdminUser => ({
  id: '1',
  name: 'Test',
  email: 'test@test.com',
  role,
});

describe('rbac', () => {
  it('super_admin can access all modules', () => {
    expect(canAccessModule(user('super_admin'), 'reconciliation')).toBe(true);
    expect(canAccessModule(user('super_admin'), 'admins')).toBe(true);
  });

  it('finance_admin cannot access admins', () => {
    expect(canAccessModule(user('finance_admin'), 'finance')).toBe(true);
    expect(canAccessModule(user('finance_admin'), 'admins')).toBe(false);
  });

  it('support_admin can access withdrawals and payments but not reconciliation', () => {
    expect(canAccessModule(user('support_admin'), 'withdrawals')).toBe(true);
    expect(canAccessModule(user('support_admin'), 'payments')).toBe(true);
    expect(canAccessModule(user('support_admin'), 'reconciliation')).toBe(false);
  });

  it('fraud_admin cannot access withdrawals or reconciliation', () => {
    expect(canAccessModule(user('fraud_admin'), 'withdrawals')).toBe(false);
    expect(canAccessModule(user('fraud_admin'), 'reconciliation')).toBe(false);
    expect(canAccessModule(user('fraud_admin'), 'creator_analytics')).toBe(true);
  });

  it('null user cannot access anything', () => {
    expect(canAccessModule(null, 'dashboard')).toBe(false);
  });
});
