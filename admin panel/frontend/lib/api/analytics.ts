import { API_BASE, getHeaders } from '../api';

export type TimeWindow = '7d' | '30d' | 'lifetime';

function qs(params: Record<string, string | number | undefined>) {
  const q = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => {
    if (v !== undefined && v !== '') q.set(k, String(v));
  });
  const s = q.toString();
  return s ? `?${s}` : '';
}

export const analyticsApi = {
  creatorsOverview: (window: TimeWindow = '7d') =>
    `${API_BASE}/admin/analytics/creators/overview${qs({ window })}`,
  topEarners: (window: TimeWindow, cursor?: string, limit = 20) =>
    `${API_BASE}/admin/analytics/creators/top-earners${qs({ window, cursor, limit })}`,
  topGifts: (window: TimeWindow, cursor?: string, limit = 20) =>
    `${API_BASE}/admin/analytics/creators/top-gifts${qs({ window, cursor, limit })}`,
  topCalls: (window: TimeWindow, cursor?: string, limit = 20) =>
    `${API_BASE}/admin/analytics/creators/top-calls${qs({ window, cursor, limit })}`,
  topMessages: (window: TimeWindow, cursor?: string, limit = 20) =>
    `${API_BASE}/admin/analytics/creators/top-messages${qs({ window, cursor, limit })}`,
  online: (cursor?: string, limit = 20) =>
    `${API_BASE}/admin/analytics/creators/online${qs({ cursor, limit })}`,
  newCreators: (window: '7d' | '30d' = '7d', cursor?: string) =>
    `${API_BASE}/admin/analytics/creators/new${qs({ window, cursor })}`,
  inactive: (days = 30, cursor?: string) =>
    `${API_BASE}/admin/analytics/creators/inactive${qs({ days, cursor })}`,
};

export async function downloadCsv(path: string, filename: string) {
  const res = await fetch(path, { headers: getHeaders() });
  if (!res.ok) throw new Error('Export failed');
  const blob = await res.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
