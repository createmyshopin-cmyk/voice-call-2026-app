/**
 * Obtain production app JWTs for Locust via Firebase custom token → ID token → /auth/firebase-login.
 *
 * Usage:
 *   node scripts/prepare-load-test-auth.mjs --write-env
 *   API_ROOT=https://api.creomine.com node scripts/prepare-load-test-auth.mjs
 */
import 'dotenv/config';
import admin from 'firebase-admin';
import { createClient } from '@supabase/supabase-js';
import { writeFileSync, readFileSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const API_ROOT = (process.env.API_ROOT || 'https://api.creomine.com').replace(/\/$/, '');
const FIREBASE_WEB_API_KEY =
  process.env.FIREBASE_WEB_API_KEY || 'AIzaSyApPlisDVZjSuHfi4CWPUIJEeHuEuJeyas';

const CALLER_USER_ID =
  process.env.LOAD_CALLER_USER_ID || '4f002dca-2813-4c26-8ed2-e02669d55e42';
const CREATOR_USER_ID =
  process.env.LOAD_CREATOR_USER_ID || '8df40697-59fd-4b7c-a709-b1389f1a89e3';

function initFirebase() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;
  if (!projectId || !clientEmail || !privateKey) {
    throw new Error('FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY required');
  }
  privateKey = privateKey.replace(/\\n/g, '\n');
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({ projectId, clientEmail, privateKey }),
    });
  }
}

async function exchangeCustomToken(customToken) {
  const res = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_WEB_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  );
  const data = await res.json();
  if (!res.ok) {
    throw new Error(`Firebase signInWithCustomToken failed: ${JSON.stringify(data)}`);
  }
  return data.idToken;
}

async function appLogin(idToken) {
  const res = await fetch(`${API_ROOT}/api/auth/firebase-login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ firebaseToken: idToken }),
  });
  const data = await res.json();
  if (!res.ok) {
    throw new Error(`firebase-login failed ${res.status}: ${JSON.stringify(data)}`);
  }
  return data.accessToken;
}

async function fetchUser(client, userId) {
  const { data, error } = await client
    .from('users')
    .select('id, firebase_uid, phone')
    .eq('id', userId)
    .single();
  if (error || !data?.firebase_uid) {
    throw new Error(`User ${userId} missing firebase_uid: ${error?.message}`);
  }
  return data;
}

async function tokenForUid(firebaseUid) {
  const custom = await admin.auth().createCustomToken(firebaseUid);
  const idToken = await exchangeCustomToken(custom);
  return appLogin(idToken);
}

async function main() {
  initFirebase();
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { persistSession: false } },
  );

  const caller = await fetchUser(supabase, CALLER_USER_ID);
  const creator = await fetchUser(supabase, CREATOR_USER_ID);

  console.log('Minting caller token via Firebase → firebase-login...');
  const callerToken = await tokenForUid(caller.firebase_uid);
  console.log('Minting creator token...');
  const creatorToken = await tokenForUid(creator.firebase_uid);

  const { data: gift } = await supabase
    .from('gifts')
    .select('id')
    .eq('is_active', true)
    .limit(1)
    .maybeSingle();

  const { data: profile } = await supabase
    .from('creator_profiles')
    .select('id')
    .eq('user_id', CREATOR_USER_ID)
    .single();

  const payload = {
    API_ROOT,
    CALLER_ID: CALLER_USER_ID,
    CREATOR_ID: CREATOR_USER_ID,
    CREATOR_PROFILE_ID: profile?.id ?? '',
    CALLER_TOKEN: callerToken,
    CREATOR_TOKEN: creatorToken,
    GIFT_ID: gift?.id ?? '',
    CALL_ID: process.env.CALL_ID || '00000000-0000-0000-0000-000000000099',
    CHANNEL_NAME: 'ch_load_test_phase23i',
  };

  console.log('Caller:', caller.id, 'Creator:', creator.id, 'Gift:', payload.GIFT_ID);

  if (process.argv.includes('--write-env')) {
    const envPath = resolve(__dirname, '..', '.env.load');
    const lines = Object.entries(payload).map(([k, v]) => `${k}=${v}`);
    writeFileSync(envPath, lines.join('\n') + '\n');
    console.log('Wrote', envPath);
  } else {
    console.log(JSON.stringify({ ...payload, CALLER_TOKEN: '[redacted]', CREATOR_TOKEN: '[redacted]' }, null, 2));
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
