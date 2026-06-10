/**
 * Phase 2.3I load certification — runs L1–L4 profiles sequentially.
 * Auth: admin login via locust on_start (no JWT_SECRET required).
 */
import { spawn } from 'child_process';
import { writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..', '..', '..');
const locustDir = resolve(__dirname, '..', 'tests', 'audit');
const host = process.env.LOAD_HOST || 'https://api.creomine.com';

const PROFILES = [
  { id: 'L1', users: 100, spawn: 20, minutes: 3 },
  { id: 'L2', users: 250, spawn: 35, minutes: 3 },
  { id: 'L3', users: 500, spawn: 50, minutes: 3 },
  { id: 'L4', users: 1000, spawn: 80, minutes: 4 },
];

function runProfile(profile) {
  return new Promise((resolvePromise, reject) => {
    const outFile = resolve(root, `LOAD_${profile.id}_phase23i.txt`);
    const args = [
      '-m',
      'locust',
      '-f',
      'locustfile.py',
      `--host=${host}`,
      `--users=${profile.users}`,
      `--spawn-rate=${profile.spawn}`,
      '--headless',
      `--run-time=${profile.minutes}m`,
    ];
    console.log(`\n=== ${profile.id}: ${profile.users} users, ${profile.minutes}m ===`);
    const proc = spawn('python', args, { cwd: locustDir, shell: true });
    let buf = '';
    proc.stdout.on('data', (d) => {
      buf += d.toString();
      process.stdout.write(d);
    });
    proc.stderr.on('data', (d) => {
      buf += d.toString();
      process.stderr.write(d);
    });
    proc.on('close', (code) => {
      writeFileSync(outFile, buf);
      if (code !== 0) reject(new Error(`${profile.id} exit ${code}`));
      else resolvePromise({ profile, outFile, buf });
    });
  });
}

async function main() {
  mkdirSync(root, { recursive: true });
  const results = [];
  for (const p of PROFILES) {
    try {
      results.push(await runProfile(p));
    } catch (e) {
      results.push({ profile: p, error: e.message });
      console.error(e.message);
    }
  }
  writeFileSync(resolve(root, 'LOAD_CERTIFICATION_SUMMARY.json'), JSON.stringify(results, null, 2));
  console.log('\nWrote LOAD_CERTIFICATION_SUMMARY.json');
}

main();
