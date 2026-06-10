/**
 * API performance benchmark — measures P50/P95/P99 response times.
 *
 * Usage:
 *   node scripts/api-performance-benchmark.mjs
 *   API_BASE=https://api.creomine.com/api ITERATIONS=30 node scripts/api-performance-benchmark.mjs
 */
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const API_ROOT = (process.env.API_ROOT || 'https://api.creomine.com').replace(/\/$/, '');
const BASE = (process.env.API_BASE || `${API_ROOT}/api`).replace(/\/$/, '');
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@coincalling.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'password123';
const ITERATIONS = Number(process.env.ITERATIONS || 25);
const WARMUP = Number(process.env.WARMUP || 3);

function percentile(sorted, p) {
  if (!sorted.length) return 0;
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(idx, sorted.length - 1))];
}

async function timedFetch(url, options = {}) {
  const start = performance.now();
  const res = await fetch(url, options);
  const ms = performance.now() - start;
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { res, data, ms };
}

async function api(method, path, token, body) {
  return timedFetch(`${BASE}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
}

async function benchmarkEndpoint(name, category, fn) {
  const samples = [];
  let lastStatus = 0;
  let lastError = '';

  for (let i = 0; i < WARMUP + ITERATIONS; i++) {
    try {
      const { res, ms } = await fn();
      lastStatus = res.status;
      if (i >= WARMUP && res.ok) samples.push(ms);
      if (!res.ok) lastError = `HTTP ${res.status}`;
    } catch (e) {
      lastError = e instanceof Error ? e.message : String(e);
    }
  }

  samples.sort((a, b) => a - b);
  return {
    name,
    category,
    samples: samples.length,
    p50: Math.round(percentile(samples, 50)),
    p95: Math.round(percentile(samples, 95)),
    p99: Math.round(percentile(samples, 99)),
    min: samples.length ? Math.round(samples[0]) : null,
    max: samples.length ? Math.round(samples[samples.length - 1]) : null,
    status: lastStatus,
    error: samples.length ? null : lastError || 'no successful samples',
  };
}

const ENDPOINTS = (token) => [
  // Calls
  { category: 'Calls', name: 'GET /calls/active (admin)', fn: () => api('GET', '/calls/active', token) },
  { category: 'Calls', name: 'GET /calls (admin history)', fn: () => api('GET', '/calls', token) },
  { category: 'Calls', name: 'GET /calls/history (user)', fn: () => api('GET', '/calls/history', token) },
  { category: 'Calls', name: 'GET /calls/active/me', fn: () => api('GET', '/calls/active/me', token) },

  // Wallet
  { category: 'Wallet', name: 'GET /wallet', fn: () => api('GET', '/wallet', token) },
  { category: 'Wallet', name: 'GET /wallets/transactions (admin)', fn: () => api('GET', '/wallets/transactions', token) },

  // Gift
  { category: 'Gift', name: 'GET /gifts', fn: () => api('GET', '/gifts', token) },
  // gifts/history requires app-user JWT — admin token correctly returns 403
  { category: 'Gift', name: 'GET /listener/gifts/stats', fn: () => api('GET', '/listener/gifts/stats', token) },
  { category: 'Gift', name: 'GET /admin/gifts/analytics', fn: () => api('GET', '/admin/gifts/analytics', token) },

  // Recharge
  { category: 'Recharge', name: 'GET /payments/packages', fn: () => api('GET', '/payments/packages', token) },
  { category: 'Recharge', name: 'GET /payments/history (admin)', fn: () => api('GET', '/payments/history', token) },

  // Creator Dashboard
  { category: 'Creator Dashboard', name: 'GET /creators', fn: () => api('GET', '/creators', token) },
  { category: 'Creator Dashboard', name: 'GET /creators/earnings-history', fn: () => api('GET', '/creators/earnings-history', token) },
  { category: 'Creator Dashboard', name: 'GET /creators/wallet/balance', fn: () => api('GET', '/creators/wallet/balance', token) },
  { category: 'Creator Dashboard', name: 'GET /listener/gifts/recent', fn: () => api('GET', '/listener/gifts/recent', token) },

  // Admin Analytics
  { category: 'Admin Analytics', name: 'GET /admin/dashboard', fn: () => api('GET', '/admin/dashboard', token) },
  { category: 'Admin Analytics', name: 'GET /admin/finance/overview', fn: () => api('GET', '/admin/finance/overview', token) },
  { category: 'Admin Analytics', name: 'GET /admin/finance/revenue-chart?days=7', fn: () => api('GET', '/admin/finance/revenue-chart?days=7', token) },
  { category: 'Admin Analytics', name: 'GET /admin/finance/top-creators', fn: () => api('GET', '/admin/finance/top-creators', token) },
  { category: 'Admin Analytics', name: 'GET /admin/finance/call-analytics', fn: () => api('GET', '/admin/finance/call-analytics', token) },
  { category: 'Admin Analytics', name: 'GET /admin/finance/withdrawal-analytics', fn: () => api('GET', '/admin/finance/withdrawal-analytics', token) },
];

async function main() {
  console.log('=== API Performance Benchmark ===\n');
  console.log(`Target:    ${BASE}`);
  console.log(`Iterations: ${ITERATIONS} (+${WARMUP} warmup)\n`);

  const { res: loginRes, data: loginData } = await api('POST', '/auth/login', null, {
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
  });

  const token = loginData?.accessToken;
  if (!token) {
    console.error('Login failed:', loginRes.status, loginData);
    process.exit(1);
  }

  const results = [];
  for (const ep of ENDPOINTS(token)) {
    process.stdout.write(`Benchmarking ${ep.name}...`);
    const r = await benchmarkEndpoint(ep.name, ep.category, ep.fn);
    results.push(r);
    console.log(` P50=${r.p50 ?? '—'}ms P95=${r.p95 ?? '—'}ms`);
  }

  const reportPath = resolve(__dirname, '..', '..', '..', 'API_PERFORMANCE_REPORT.md');
  const now = new Date().toISOString();
  const categories = [...new Set(results.map((r) => r.category))];

  let md = `# API Performance Report\n\n`;
  md += `**Generated:** ${now}  \n`;
  md += `**Target:** \`${BASE}\`  \n`;
  md += `**Method:** ${ITERATIONS} iterations per endpoint (${WARMUP} warmup discarded)  \n`;
  md += `**Auth:** Admin JWT (read-only GET endpoints)\n\n`;
  md += `---\n\n`;

  md += `## Executive Summary\n\n`;
  const slow = results.filter((r) => r.p95 && r.p95 > 500).sort((a, b) => (b.p95 ?? 0) - (a.p95 ?? 0));
  const healthy = results.filter((r) => r.p95 && r.p95 <= 200);
  md += `- **Endpoints measured:** ${results.length}\n`;
  md += `- **Healthy (P95 ≤ 200ms):** ${healthy.length}\n`;
  md += `- **Slow (P95 > 500ms):** ${slow.length}\n\n`;

  if (slow.length) {
    md += `### Slowest Endpoints (P95 > 500ms)\n\n`;
    md += `| Endpoint | P50 | P95 | P99 |\n`;
    md += `|----------|-----|-----|-----|\n`;
    for (const r of slow) {
      md += `| ${r.name} | ${r.p50 ?? '—'}ms | ${r.p95 ?? '—'}ms | ${r.p99 ?? '—'}ms |\n`;
    }
    md += `\n`;
  }

  for (const cat of categories) {
    md += `## ${cat}\n\n`;
    md += `| Endpoint | P50 | P95 | P99 | Min | Max | Status |\n`;
    md += `|----------|-----|-----|-----|-----|-----|--------|\n`;
    for (const r of results.filter((x) => x.category === cat)) {
      const status = r.error ? `⚠️ ${r.error}` : `✅ ${r.status}`;
      md += `| ${r.name} | ${r.p50 ?? '—'}ms | ${r.p95 ?? '—'}ms | ${r.p99 ?? '—'}ms | ${r.min ?? '—'}ms | ${r.max ?? '—'}ms | ${status} |\n`;
    }
    md += `\n`;
  }

  md += `## Code-Level Findings\n\n`;
  md += `See **Database & Query Issues** and **Applied Optimizations** sections below.\n\n`;

  writeFileSync(reportPath, md);
  console.log(`\nReport written to: ${reportPath}`);

  // Output JSON for agent consumption
  console.log('\n--- JSON ---');
  console.log(JSON.stringify({ generatedAt: now, base: BASE, results }, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
