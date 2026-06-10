/**
 * Certification: frontend RBAC must align with backend @Roles.
 * These tests document KNOWN mismatches — failures indicate remediation needed.
 */
import { describe, it, expect } from 'vitest';
import { canAccessModule } from './rbac';
import type { AdminUser } from './auth';

const user = (role: string): AdminUser => ({
  id: '1',
  name: 'Cert',
  email: 'cert@test.com',
  role,
});

/** Backend truth for certification (from controller @Roles decorators) */
const BACKEND_TRUTH: Record<string, string[]> = {
  creator_analytics: ['super_admin', 'finance_admin', 'operations_admin', 'fraud_admin'],
  withdrawals: ['super_admin', 'finance_admin', 'support_admin'],
  gifts: ['super_admin', 'finance_admin', 'operations_admin'],
  reconciliation: ['super_admin', 'finance_admin'],
  users: ['super_admin', 'moderator', 'support_admin', 'fraud_admin'],
  calls: ['super_admin', 'operations_admin', 'moderator', 'fraud_admin', 'support_admin'],
  payments: ['super_admin', 'finance_admin', 'support_admin'],
};

describe('RBAC certification — frontend vs backend alignment', () => {
  for (const [module, backendRoles] of Object.entries(BACKEND_TRUTH)) {
    for (const role of ['super_admin', 'finance_admin', 'operations_admin', 'moderator', 'support_admin', 'fraud_admin']) {
      it(`${role} → ${module}: frontend matches backend`, () => {
        const frontendAllows = canAccessModule(user(role), module as Parameters<typeof canAccessModule>[1]);
        const backendAllows = backendRoles.includes(role);
        expect(frontendAllows).toBe(backendAllows);
      });
    }
  }
});
