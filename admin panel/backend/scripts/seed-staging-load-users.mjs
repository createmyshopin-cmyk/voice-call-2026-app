/**
 * Seed staging users for Locust load tests (idempotent).
 *
 * Usage:
 *   node scripts/seed-staging-load-users.mjs
 *   node scripts/seed-staging-load-users.mjs --write-env
 *
 * Creates:
 *   - 1 caller user  (load_caller_001)
 *   - 1 creator user + profile (load_creator_001)
 *   - wallets with 50_000 coins / creator balance
 * Writes CALLER_ID, CREATOR_ID, CALL_ID placeholders to .env.load if --write-env
 */
import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';
import { writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import { randomUUID } from 'crypto';

const __dirname = dirname(fileURLToPath(import.meta.url));
const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY required');
  process.exit(1);
}

const client = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const CALLER_EMAIL = 'load_caller_001@staging.creomine.test';
const CREATOR_EMAIL = 'load_creator_001@staging.creomine.test';

async function upsertUser({ email, name, isCreator }) {
  const { data: existing } = await client.from('users').select('id').eq('email', email).maybeSingle();
  if (existing?.id) return existing.id;

  const id = randomUUID();
  const { error } = await client.from('users').insert({
    id,
    email,
    name,
    full_name: name,
    is_creator: isCreator,
    status: 'active',
    coins: 50_000,
  });
  if (error) throw new Error(`users insert ${email}: ${error.message}`);

  await client.from('wallets').upsert({ user_id: id, coin_balance: 50_000 });
  return id;
}

async function ensureCreatorProfile(userId) {
  const { data: existing } = await client
    .from('creator_profiles')
    .select('id')
    .eq('user_id', userId)
    .maybeSingle();
  if (existing?.id) return existing.id;

  const id = randomUUID();
  const { error } = await client.from('creator_profiles').insert({
    id,
    user_id: userId,
    status: 'approved',
    is_online: true,
    online_status: true,
    rate_per_minute: 10,
  });
  if (error) throw new Error(`creator_profiles: ${error.message}`);

  await client.from('creator_wallets').upsert({
    creator_id: id,
    available_balance: 10_000,
    total_earned: 10_000,
    withdrawn_amount: 0,
    locked_balance: 0,
  });
  return id;
}

async function main() {
  const callerId = await upsertUser({
    email: CALLER_EMAIL,
    name: 'Load Caller 001',
    isCreator: false,
  });
  const creatorUserId = await upsertUser({
    email: CREATOR_EMAIL,
    name: 'Load Creator 001',
    isCreator: true,
  });
  const creatorProfileId = await ensureCreatorProfile(creatorUserId);

  const seed = {
    CALLER_ID: callerId,
    CREATOR_ID: creatorUserId,
    CREATOR_PROFILE_ID: creatorProfileId,
    GIFT_ID: (
      await client.from('gifts').select('id').eq('is_active', true).limit(1).maybeSingle()
    ).data?.id,
    CHANNEL_NAME: 'load_test_channel',
  };

  console.log(JSON.stringify(seed, null, 2));

  if (process.argv.includes('--write-env')) {
    const envPath = resolve(__dirname, '..', '.env.load');
    const lines = [
      `# Generated ${new Date().toISOString()}`,
      `CALLER_ID=${seed.CALLER_ID}`,
      `CREATOR_ID=${seed.CREATOR_ID}`,
      `CREATOR_PROFILE_ID=${seed.CREATOR_PROFILE_ID}`,
      `GIFT_ID=${seed.GIFT_ID ?? ''}`,
      `CHANNEL_NAME=${seed.CHANNEL_NAME}`,
      `JWT_SECRET=${process.env.JWT_SECRET ?? ''}`,
      `API_BASE=${process.env.API_BASE ?? 'https://api.creomine.com/api'}`,
    ];
    writeFileSync(envPath, lines.join('\n') + '\n');
    console.log(`Wrote ${envPath}`);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
