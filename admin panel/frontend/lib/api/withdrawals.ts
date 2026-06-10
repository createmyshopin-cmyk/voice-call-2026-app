import { API_BASE } from '../api';

export type WithdrawalStatus = 'pending' | 'approved' | 'paid' | 'rejected' | 'cancelled' | 'failed';

export interface WithdrawalListParams {
  status?: WithdrawalStatus;
  cursor?: string;
  limit?: number;
  from?: string;
  to?: string;
  creatorId?: string;
  minAmount?: number;
  maxAmount?: number;
  search?: string;
}

function qs(params: WithdrawalListParams) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== '') q.set(k, String(v));
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export interface PaginatedWithdrawals {
  items: Record<string, unknown>[];
  hasMore: boolean;
  nextCursor: string | null;
}

/** Normalize list response — always `{ items, hasMore, nextCursor }` after P0 remediation. */
export function normalizeWithdrawalList(data: unknown): PaginatedWithdrawals {
  if (data && typeof data === 'object' && 'items' in data) {
    const p = data as PaginatedWithdrawals;
    return {
      items: p.items ?? [],
      hasMore: Boolean(p.hasMore),
      nextCursor: p.nextCursor ?? null,
    };
  }
  if (Array.isArray(data)) {
    return { items: data, hasMore: false, nextCursor: null };
  }
  return { items: [], hasMore: false, nextCursor: null };
}

export const withdrawalsApi = {
  list: (params: WithdrawalListParams = {}) =>
    `${API_BASE}/admin/withdrawals${qs(params)}`,
  export: (params: WithdrawalListParams = {}) =>
    `${API_BASE}/admin/withdrawals/export${qs(params)}`,
  detail: (id: string) => `${API_BASE}/admin/withdrawals/${id}`,
};
