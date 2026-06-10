const API_ROOT = process.env.NEXT_PUBLIC_API_URL?.replace(/\/api$/, '') || 'https://api.creomine.com';

export const operationsApi = {
  snapshot: () => `${API_ROOT}/api/admin/operations/snapshot`,
  health: () => `${API_ROOT}/health`,
  ready: () => `${API_ROOT}/health/ready`,
  startup: () => `${API_ROOT}/health/startup`,
  metrics: () => `${API_ROOT}/api/observability/metrics`,
  slos: () => `${API_ROOT}/api/observability/slos`,
};
