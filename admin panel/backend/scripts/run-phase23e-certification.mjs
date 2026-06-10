/**
 * Phase 2.3E certification orchestrator — aggregates automated validation results.
 *
 * Usage:
 *   node scripts/run-phase23e-certification.mjs
 *   API_BASE=http://127.0.0.1:5000/api node scripts/run-phase23e-certification.mjs
 */
import { spawnSync } from 'child_process';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO = resolve(__dirname, '..', '..', '..');
const BACKEND = resolve(__dirname, '..');
const OUT = resolve(REPO, 'PHASE23E_CERTIFICATION_RESULTS.json');

function run(cmd, args, cwd, label) {
  const started = Date.now();
  const r = spawnSync(cmd, args, { cwd, encoding: 'utf-8', shell: true });
  return {
    label,
    cmd: `${cmd} ${args.join(' ')}`,
    exitCode: r.status ?? 1,
    durationMs: Date.now() - started,
    stdout: (r.stdout || '').slice(-4000),
    stderr: (r.stderr || '').slice(-2000),
    pass: r.status === 0,
  };
}

function percentile(sorted, p) {
  if (!sorted.length) return null;
  const idx = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(idx, sorted.length - 1))];
}

async function microLatencyProbe() {
  const base = (process.env.API_ROOT || 'http://127.0.0.1:5000').replace(/\/$/, '');
  const endpoints = ['/health', '/health/ready'];
  const results = [];

  for (const path of endpoints) {
    const samples = [];
    for (let i = 0; i < 10; i++) {
      const t0 = performance.now();
      try {
        const res = await fetch(`${base}${path}`);
        await res.text();
        if (res.ok) samples.push(performance.now() - t0);
      } catch {
        /* server down */
      }
    }
    samples.sort((a, b) => a - b);
    results.push({
      endpoint: path,
      samples: samples.length,
      p50: samples.length ? Math.round(percentile(samples, 50)) : null,
      p95: samples.length ? Math.round(percentile(samples, 95)) : null,
      p99: samples.length ? Math.round(percentile(samples, 99)) : null,
      pass: samples.length >= 5,
    });
  }
  return results;
}

async function tryLocustMini() {
  const host = process.env.API_ROOT || 'http://127.0.0.1:5000';
  const auditDir = resolve(BACKEND, 'tests', 'audit');
  const r = spawnSync(
    'locust',
    [
      '-f',
      'locustfile.py',
      `--host=${host}`,
      '--users',
      '10',
      '--spawn-rate',
      '2',
      '--headless',
      '--run-time',
      '30s',
    ],
    { cwd: auditDir, encoding: 'utf-8', shell: true, timeout: 60_000 },
  );
  const out = (r.stdout || '') + (r.stderr || '');
  const failMatch = out.match(/failures=(\d+)/);
  const reqMatch = out.match(/requests=(\d+)/);
  return {
    label: 'locust_mini_10_users_30s',
    pass: r.status === 0 && (!failMatch || failMatch[1] === '0'),
    exitCode: r.status,
    requests: reqMatch ? Number(reqMatch[1]) : null,
    failures: failMatch ? Number(failMatch[1]) : null,
    snippet: out.slice(-1500),
  };
}

async function main() {
  const results = {
    generatedAt: new Date().toISOString(),
    phase: '2.3E',
    suites: [],
    latency: [],
    locust: null,
  };

  results.suites.push(run('npm', ['test'], BACKEND, 'jest_backend_176'));
  results.suites.push(
    run('python', ['-m', 'pytest', '-q', 'tests/hotfix'], REPO, 'pytest_hotfix_38'),
  );
  results.suites.push(
    run(
      'python',
      ['-m', 'pytest', '-q', 'tests/certification'],
      BACKEND,
      'pytest_phase23e_certification',
    ),
  );
  results.suites.push(
    run('python', ['-m', 'pytest', '-q', 'tests/audit'], BACKEND, 'pytest_audit'),
  );
  results.suites.push(
    run('flutter', ['test', '--exclude-tags', 'broken'], REPO, 'flutter_unit'),
  );

  results.latency = await microLatencyProbe();
  try {
    results.locust = await tryLocustMini();
  } catch (e) {
    results.locust = { label: 'locust_mini', pass: false, error: String(e) };
  }

  const passCount = results.suites.filter((s) => s.pass).length;
  results.summary = {
    suitesPass: passCount,
    suitesTotal: results.suites.length,
    overallPass: passCount === results.suites.length && results.latency.every((l) => l.pass || l.samples === 0),
  };

  writeFileSync(OUT, JSON.stringify(results, null, 2));
  console.log(JSON.stringify(results.summary, null, 2));
  console.log(`Results: ${OUT}`);
  process.exit(results.summary.overallPass ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
