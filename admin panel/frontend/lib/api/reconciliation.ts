import { API_BASE } from '../api';

function qs(params: Record<string, string | number | undefined>) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== '') q.set(k, String(v));
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export const reconciliationApi = {
  runs: (limit = 50) => `${API_BASE}/admin/reconciliation/runs${qs({ limit })}`,
  findings: (params: { status?: string; severity?: string; check_id?: string; limit?: number } = {}) =>
    `${API_BASE}/admin/reconciliation/findings${qs(params)}`,
  health: () => `${API_BASE}/admin/reconciliation/health`,
  acknowledge: (id: string) => `${API_BASE}/admin/reconciliation/findings/${id}/acknowledge`,
  resolve: (id: string) => `${API_BASE}/admin/reconciliation/findings/${id}/resolve`,
  runNow: () => `${API_BASE}/admin/reconciliation/run-now`,
};
