/**
 * Applies Sprint 6/7 migrations via Supabase Management API (reads SQL from disk).
 * Usage: node scripts/apply-phase23g-migrations.mjs [sprint6|sprint7|both]
 */
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MIGRATIONS = {
  sprint6: {
    name: 'creator_ledger_withdrawal_sprint6',
    file: '20260610200000_creator_ledger_withdrawal_sprint6.sql',
  },
  sprint7: {
    name: 'reconciliation_observability_sprint7',
    file: '20260610220000_reconciliation_observability_sprint7.sql',
  },
};

async function applyViaMcp(name, sql) {
  // This script outputs migration payload for operator/MCP; actual apply uses stdin hook.
  const payload = { name, query: sql };
  process.stdout.write(JSON.stringify(payload));
}

async function main() {
  const which = process.argv[2] ?? 'both';
  const keys = which === 'both' ? ['sprint6', 'sprint7'] : [which];
  const migDir = path.join(__dirname, '..', 'supabase', 'migrations');

  for (const key of keys) {
    const { name, file } = MIGRATIONS[key];
    const sql = fs.readFileSync(path.join(migDir, file), 'utf8');
    console.error(`Prepared ${file} (${sql.length} bytes)`);
    if (keys.length === 1) {
      await applyViaMcp(name, sql);
      return;
    }
    // For 'both', write sidecar files for MCP apply
    const out = path.join(__dirname, `.migration-${key}.json`);
    fs.writeFileSync(out, JSON.stringify({ name, query: sql }));
    console.error(`Wrote ${out}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
