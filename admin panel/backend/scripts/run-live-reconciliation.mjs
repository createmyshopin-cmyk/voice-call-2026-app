/**
 * Execute reconciliation_run(T0–T8) against live Supabase and summarize deltas.
 *
 * Usage:
 *   node scripts/run-live-reconciliation.mjs
 *   node scripts/run-live-reconciliation.mjs --tier T5
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const tiers = process.argv.includes('--tier')
  ? [process.argv[process.argv.indexOf('--tier') + 1]]
  : ['T0', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8'];

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
  process.exit(1);
}

const client = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

async function runTier(tier) {
  const started = Date.now();
  const { data, error } = await client.rpc('reconciliation_run', { p_tier: tier });
  return {
    tier,
    durationMs: Date.now() - started,
    error: error?.message ?? null,
    result: data,
  };
}

async function fetchOpenFindings() {
  const { data, error } = await client
    .from('reconciliation_findings')
    .select('check_id, severity, status, delta_coins, delta_amount, entity_type, entity_id')
    .eq('status', 'open');
  if (error) throw new Error(error.message);
  return data ?? [];
}

async function main() {
  const runs = [];
  for (const tier of tiers) {
    console.log(`Running reconciliation ${tier}...`);
    try {
      runs.push(await runTier(tier));
    } catch (e) {
      runs.push({
        tier,
        error: e instanceof Error ? e.message : String(e),
        result: null,
      });
    }
  }

  let findings = [];
  let findingsError = null;
  try {
    findings = await fetchOpenFindings();
  } catch (e) {
    findingsError = e instanceof Error ? e.message : String(e);
  }

  const bySeverity = {};
  for (const f of findings) {
    bySeverity[f.severity] = (bySeverity[f.severity] ?? 0) + 1;
  }

  const driftChecks = findings.filter((f) =>
    ['U-DRIFT', 'C-DRIFT', 'M-U', 'M-C', 'SYS-DRIFT', 'N-W', 'D-P'].some((p) =>
      f.check_id.startsWith(p),
    ),
  );

  const summary = {
    generatedAt: new Date().toISOString(),
    runs,
    openFindings: findings.length,
    bySeverity,
    driftFindings: driftChecks.length,
    financialDeltaZero: driftChecks.length === 0 && !findings.some((f) => f.severity === 'P0'),
    findingsError,
    findings: driftChecks.slice(0, 50),
  };

  const outPath = resolve(__dirname, '..', '..', '..', 'LIVE_RECONCILIATION_RESULTS.json');
  writeFileSync(outPath, JSON.stringify(summary, null, 2));
  console.log(JSON.stringify(summary, null, 2));
  console.log(`Written: ${outPath}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
