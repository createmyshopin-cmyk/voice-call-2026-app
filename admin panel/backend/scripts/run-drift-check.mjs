/**
 * Direct SQL drift checks when reconciliation_run migration is not yet applied.
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

async function main() {
  const findings = [];

  // User drift U-DRIFT-02
  const { data: users } = await client.from('users').select('id, coins').limit(5000);
  const { data: wallets } = await client.from('wallets').select('user_id, coin_balance');
  const walletMap = new Map((wallets ?? []).map((w) => [w.user_id, w.coin_balance]));
  for (const u of users ?? []) {
    const wb = walletMap.get(u.id);
    if (wb != null && u.coins !== wb) {
      findings.push({
        check: 'U-DRIFT-02',
        entity: u.id,
        delta: u.coins - wb,
      });
    }
  }

  // Payment M-U-01
  const { data: payments } = await client
    .from('payments')
    .select('id, user_id, coins_added')
    .eq('status', 'success')
    .limit(500);
  for (const p of payments ?? []) {
    const { count } = await client
      .from('coin_transactions')
      .select('*', { count: 'exact', head: true })
      .eq('type', 'recharge')
      .eq('reference_id', p.id);
    if (!count) {
      findings.push({ check: 'M-U-01', entity: p.id, delta: p.coins_added });
    }
  }

  // Creator C-DRIFT-01 sample
  const { data: cw } = await client.from('creator_wallets').select('*').limit(500);
  for (const w of cw ?? []) {
    const sum =
      Number(w.available_balance ?? 0) +
      Number(w.locked_balance ?? 0) +
      Number(w.withdrawn_amount ?? 0);
    if (sum !== Number(w.total_earned ?? 0)) {
      findings.push({
        check: 'C-DRIFT-01',
        entity: w.creator_id,
        delta: sum - Number(w.total_earned ?? 0),
      });
    }
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    findingsCount: findings.length,
    financialDeltaZero: findings.length === 0,
    findings: findings.slice(0, 100),
  };
  console.log(JSON.stringify(summary, null, 2));
}

main().catch(console.error);
