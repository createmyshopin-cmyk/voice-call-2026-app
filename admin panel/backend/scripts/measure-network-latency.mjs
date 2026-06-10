/**
 * Measure round-trip latency to API, Supabase, and health endpoints.
 * Usage: node scripts/measure-network-latency.mjs
 */
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));

const API_ROOT = (process.env.API_ROOT || 'https://api.creomine.com').replace(/\/$/, '');
const API_BASE = (process.env.API_BASE || `${API_ROOT}/api`).replace(/\/$/, '');
const SUPABASE_URL = (process.env.SUPABASE_URL || 'https://rxlvgfgksahgiiccorzx.supabase.co').replace(/\/$/, '');
const ITERATIONS = Number(process.env.ITERATIONS || 20);

function percentile(sorted, p) {
  if (!sorted.length) return 0;
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(idx, sorted.length - 1))];
}

function stats(samples) {
  const s = [...samples].sort((a, b) => a - b);
  return {
    n: s.length,
    min: s.length ? Math.round(s[0]) : null,
    p50: Math.round(percentile(s, 50)),
    p95: Math.round(percentile(s, 95)),
    p99: Math.round(percentile(s, 99)),
    max: s.length ? Math.round(s[s.length - 1]) : null,
    avg: s.length ? Math.round(s.reduce((a, b) => a + b, 0) / s.length) : null,
  };
}

async function timedFetch(url, options = {}) {
  const start = performance.now();
  let res;
  let error = null;
  try {
    res = await fetch(url, { ...options, signal: AbortSignal.timeout(15000) });
  } catch (e) {
    error = e instanceof Error ? e.message : String(e);
    return { ms: performance.now() - start, res: null, error };
  }
  const ms = performance.now() - start;
  return { ms, res, error: null };
}

async function benchmark(name, url, options, warmup = 3) {
  const samples = [];
  let lastStatus = null;
  let lastHeaders = {};
  let lastError = null;

  for (let i = 0; i < warmup + ITERATIONS; i++) {
    const { ms, res, error } = await timedFetch(url, options);
    if (res) {
      lastStatus = res.status;
      res.headers.forEach((v, k) => { lastHeaders[k.toLowerCase()] = v; });
      if (i >= warmup && res.ok) samples.push(ms);
    } else {
      lastError = error;
    }
  }

  return { name, url, ...stats(samples), status: lastStatus, headers: lastHeaders, error: lastError };
}

function resolveHost(url) {
  try {
    return new URL(url).hostname;
  } catch {
    return url;
  }
}

function nslookup(hostname) {
  try {
    const out = execSync(`nslookup ${hostname}`, { encoding: 'utf8', timeout: 10000 });
    const allIps = [...out.matchAll(/Address(?:es)?:\s+(\d+\.\d+\.\d+\.\d+)/g)].map((m) => m[1]);
    // Skip DNS resolver lines — keep only answer-section IPs (typically Cloudflare 104.x / 172.x)
    const ips = [...new Set(allIps)].filter(
      (ip) => ip.startsWith('104.') || ip.startsWith('172.') || ip.startsWith('13.') || ip.startsWith('52.'),
    );
    return { hostname, ips: ips.length ? ips : [...new Set(allIps)], raw: out };
  } catch (e) {
    return { hostname, ips: [], error: (e instanceof Error ? e.message : String(e)) };
  }
}

async function ipGeo(ip) {
  try {
    const res = await fetch(`http://ip-api.com/json/${ip}?fields=status,country,regionName,city,lat,lon,isp,org,as,query`, {
      signal: AbortSignal.timeout(8000),
    });
    const data = await res.json();
    return data.status === 'success' ? data : { error: data.status };
  } catch (e) {
    return { error: e instanceof Error ? e.message : String(e) };
  }
}

async function main() {
  console.log('=== Network Latency Measurement ===\n');

  const hosts = {
    api: resolveHost(API_ROOT),
    supabase: resolveHost(SUPABASE_URL),
  };

  const dns = {
    api: nslookup(hosts.api),
    supabase: nslookup(hosts.supabase),
  };

  const geo = {};
  for (const [key, entry] of Object.entries(dns)) {
    const ip = entry.ips.find((i) => !i.startsWith('127.') && !i.startsWith('::'));
    if (ip) geo[key] = await ipGeo(ip);
  }

  const benchmarks = [];
  benchmarks.push(await benchmark('API root health GET /', `${API_ROOT}/`));
  benchmarks.push(await benchmark('API health GET /health', `${API_ROOT}/health`));
  benchmarks.push(await benchmark('API protected GET /api/payments/packages', `${API_BASE}/payments/packages`));
  benchmarks.push(await benchmark('Supabase REST GET /rest/v1/', `${SUPABASE_URL}/rest/v1/`, {
    headers: {
      apikey: process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '',
      Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY || ''}`,
    },
  }));
  benchmarks.push(await benchmark('Supabase Auth GET /auth/v1/health', `${SUPABASE_URL}/auth/v1/health`));

  // Capture Railway / Cloudflare region headers from last API response
  const apiBench = benchmarks.find((b) => b.name.includes('root health'));
  const railwayEdge = apiBench?.headers?.['x-railway-edge'] ?? null;
  const cfRay = apiBench?.headers?.['cf-ray'] ?? null;
  const cfPop = cfRay ? cfRay.split('-').pop() : null;

  const report = {
    measuredAt: new Date().toISOString(),
    clientNote: 'Measurements from developer machine (Windows) to production endpoints',
    endpoints: { apiRoot: API_ROOT, apiBase: API_BASE, supabaseUrl: SUPABASE_URL },
    regions: {
      railwayEdge,
      cloudflarePop: cfPop,
      supabasePooler: 'aws-1-ap-south-1.pooler.supabase.com (ap-south-1 Mumbai)',
    },
    dns,
    geo,
    benchmarks,
  };

  const outPath = resolve(__dirname, '..', '..', '..', 'NETWORK_LATENCY_REPORT.md');
  const md = buildMarkdown(report);
  writeFileSync(outPath, md);
  console.log(`\nReport written: ${outPath}`);
  console.log(JSON.stringify(report, null, 2));
}

function buildMarkdown(r) {
  let md = `# Network Latency Report\n\n`;
  md += `**Generated:** ${r.measuredAt}  \n`;
  md += `**Measurement origin:** Developer workstation (client-side RTT to public endpoints)  \n`;
  md += `**Note:** This measures end-to-end HTTP round-trip from your machine, not server-internal API→Supabase latency on Railway.\n\n`;
  md += `---\n\n`;

  md += `## Infrastructure Endpoints\n\n`;
  md += `| Service | URL | Hostname |\n`;
  md += `|---------|-----|----------|\n`;
  md += `| Railway API | ${r.endpoints.apiRoot} | \`${r.dns.api.hostname}\` |\n`;
  md += `| Supabase | ${r.endpoints.supabaseUrl} | \`${r.dns.supabase.hostname}\` |\n\n`;

  md += `## DNS Resolution\n\n`;
  for (const [key, d] of Object.entries(r.dns)) {
    md += `### ${key === 'api' ? 'Railway API' : 'Supabase'}\n\n`;
    md += `- **Hostname:** \`${d.hostname}\`\n`;
    md += `- **IPs:** ${d.ips.length ? d.ips.map((i) => `\`${i}\``).join(', ') : '_lookup failed_'}\n\n`;
  }

  md += `## Inferred Regions (IP Geolocation)\n\n`;
  md += `| Host | IP | City | Region | Country | Provider |\n`;
  md += `|------|-----|------|--------|---------|----------|\n`;
  for (const [key, g] of Object.entries(r.geo)) {
    if (g.error) {
      md += `| ${key} | — | — | — | — | ${g.error} |\n`;
    } else {
      md += `| ${key} | ${g.query} | ${g.city} | ${g.regionName} | ${g.country} | ${g.org || g.isp} |\n`;
    }
  }
  md += `\n`;

  md += `### Supabase Project Region\n\n`;
  const sbGeo = r.geo.supabase;
  if (sbGeo && !sbGeo.error) {
    md += `Project ref \`rxlvgfgksahgiiccorzx\` resolves to **${sbGeo.city}, ${sbGeo.regionName}, ${sbGeo.country}** (${sbGeo.org || sbGeo.isp}).\n\n`;
    md += `Supabase dashboard region for this project should match: check [Supabase Dashboard](https://supabase.com/dashboard/project/rxlvgfgksahgiiccorzx/settings/general) → **Region**.\n\n`;
  } else {
    md += `_Could not geolocate Supabase endpoint._\n\n`;
  }

  md += `### Railway API Region\n\n`;
  const apiGeo = r.geo.api;
  if (apiGeo && !apiGeo.error) {
    md += `Custom domain \`api.creomine.com\` resolves to **${apiGeo.city}, ${apiGeo.regionName}, ${apiGeo.country}** (${apiGeo.org || apiGeo.isp}).\n\n`;
    md += `If using Cloudflare or another proxy in front of Railway, this may reflect the CDN edge, not the Railway compute region. Check Railway Dashboard → Service → **Settings → Region** for the actual deployment region.\n\n`;
  } else {
    md += `_Could not geolocate API endpoint._\n\n`;
  }

  md += `---\n\n`;
  md += `## Round-Trip Latency (${ITERATIONS} samples each, ${3} warmup discarded)\n\n`;
  md += `| Target | P50 | P95 | P99 | Min | Max | Avg | HTTP |\n`;
  md += `|--------|-----|-----|-----|-----|-----|-----|------|\n`;
  for (const b of r.benchmarks) {
    const http = b.error ? `⚠️ ${b.error}` : `${b.status}`;
    md += `| ${b.name} | ${b.p50 ?? '—'}ms | ${b.p95 ?? '—'}ms | ${b.p99 ?? '—'}ms | ${b.min ?? '—'}ms | ${b.max ?? '—'}ms | ${b.avg ?? '—'}ms | ${http} |\n`;
  }
  md += `\n`;

  const apiHealth = r.benchmarks.find((b) => b.name.includes('root health'));
  const sbRest = r.benchmarks.find((b) => b.name.includes('Supabase REST'));
  const delta = apiHealth?.p50 && sbRest?.p50 ? Math.abs(apiHealth.p50 - sbRest.p50) : null;

  md += `## Analysis\n\n`;
  if (apiHealth?.p50) {
    md += `- **Client → API floor latency:** ~${apiHealth.p50}ms P50 (health endpoint, no DB)\n`;
  }
  if (sbRest?.p50) {
    md += `- **Client → Supabase REST floor:** ~${sbRest.p50}ms P50\n`;
  }
  if (delta != null) {
    md += `- **API vs Supabase RTT delta (client-side):** ${delta}ms — similar floors suggest both may be in comparable regions from this client, or both behind global CDNs\n`;
  }

  const apiGeo2 = r.geo.api;
  const sbGeo2 = r.geo.supabase;
  if (apiGeo2?.country && sbGeo2?.country && apiGeo2.country !== sbGeo2.country) {
    md += `- **⚠️ Cross-region signal:** API appears in ${apiGeo2.country}, Supabase in ${sbGeo2.country} — server-side API→DB hops add latency beyond client measurements\n`;
  } else if (apiGeo2?.regionName && sbGeo2?.regionName && apiGeo2.regionName !== sbGeo2.regionName) {
    md += `- **⚠️ Possible cross-region:** API in ${apiGeo2.regionName}, Supabase in ${sbGeo2.regionName}\n`;
  }

  md += `\n### Why API endpoints show ~560–750ms floor (from API_PERFORMANCE_REPORT)\n\n`;
  md += `Each protected API request typically incurs:\n\n`;
  md += `1. Client → Railway edge (~${apiHealth?.p50 ?? '?'}ms from this client)\n`;
  md += `2. Railway NestJS handler → Supabase query (server-internal, not measured here)\n`;
  md += `3. Response serialization + return path\n\n`;
  md += `If Railway compute and Supabase DB are in different regions, step 2 alone can add **50–200ms+** per query. Sequential analytics queries (10×) compound this into multi-second responses.\n\n`;

  md += `---\n\n`;
  md += `## Recommendations\n\n`;
  md += `| Priority | Action |\n`;
  md += `|----------|--------|\n`;
  md += `| P1 | Confirm Railway service region in dashboard; align with Supabase region |\n`;
  md += `| P1 | If cross-region confirmed, migrate Railway or Supabase to same region (e.g. both Singapore or both US-East) |\n`;
  md += `| P2 | Add server-side timing middleware to log \`supabase_query_ms\` per request |\n`;
  md += `| P2 | Run this script from Railway one-off container for true server→Supabase RTT |\n`;
  md += `| P3 | Enable connection pooling (Supabase pooler / PgBouncer) if not already |\n\n`;

  md += `## Re-run\n\n`;
  md += `\`\`\`bash\n`;
  md += `cd "admin panel/backend"\n`;
  md += `node scripts/measure-network-latency.mjs\n`;
  md += `\`\`\`\n`;

  return md;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
