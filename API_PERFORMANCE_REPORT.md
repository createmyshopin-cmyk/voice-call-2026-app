# API Performance Report

**Generated:** 2026-06-08T21:27:32Z  
**Target:** `https://api.creomine.com/api` (production)  
**Benchmark:** 25 iterations per endpoint (3 warmup discarded), admin JWT  
**Codebase audited:** `admin panel/backend` (NestJS + Supabase)

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Endpoints measured | 22 |
| Successful benchmarks | 17 |
| P95 ≤ 200ms (healthy) | 0 |
| P95 > 500ms (slow) | 17 |
| Critical (P95 > 2s) | 2 |

**Baseline finding:** Nearly all endpoints exhibit ~560–750ms floor latency (likely network + cold Supabase region). The worst offenders are **admin analytics** endpoints that fire **8–10 sequential DB queries** and **call history** with **N+1 user lookups**.

**Optimizations applied** (safe, no schema changes): batch user fetches, joined call history query, parallelized analytics queries, targeted creator lookup, removed expensive PostgREST joins in top-creators.

---

## Response Time Measurements

### Calls

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /calls/active` (admin) | 716ms | **1313ms** | 1348ms | 200 |
| `GET /calls` (admin history) | 1370ms | **1804ms** | 2133ms | 200 |
| `GET /calls/history` (user) | 708ms | 761ms | 854ms | 200 |
| `GET /calls/active/me` | — | — | — | 404 (admin token, no active call) |

### Wallet

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /wallet` | — | — | — | 404 (route may be `/wallets` on prod) |
| `GET /wallets/transactions` (admin) | 709ms | 735ms | 881ms | 200 |

### Gift

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /gifts` | 717ms | 728ms | 732ms | 200 |
| `GET /gifts/history` | — | — | — | 500 (admin has no sender history) |
| `GET /listener/gifts/stats` | — | — | — | 403 (requires creator role) |
| `GET /admin/gifts/analytics` | 587ms | 733ms | 738ms | 200 |

### Recharge

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /payments/packages` | 712ms | 728ms | 729ms | 200 |
| `GET /payments/history` (admin) | 705ms | 748ms | 748ms | 200 |

### Creator Dashboard

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /creators` | 711ms | 765ms | 824ms | 200 |
| `GET /creators/earnings-history` | 710ms | 735ms | 735ms | 200 |
| `GET /creators/wallet/balance` | 955ms | **993ms** | 997ms | 200 |
| `GET /listener/gifts/recent` | — | — | — | 403 (requires creator role) |

### Admin Analytics

| Endpoint | P50 | P95 | P99 | Status |
|----------|-----|-----|-----|--------|
| `GET /admin/dashboard` | **2817ms** | **2987ms** | 3035ms | 200 |
| `GET /admin/finance/overview` | **2950ms** | **2980ms** | 3111ms | 200 |
| `GET /admin/finance/revenue-chart?days=7` | 1451ms | 1481ms | 1494ms | 200 |
| `GET /admin/finance/top-creators` | 694ms | 737ms | 767ms | 200 |
| `GET /admin/finance/call-analytics` | 962ms | 986ms | 1000ms | 200 |
| `GET /admin/finance/withdrawal-analytics` | 704ms | 724ms | 735ms | 200 |

---

## Database & Query Issues Found

### 1. N+1 Queries — Calls (`calls.service.ts`)

| Location | Issue | Impact |
|----------|-------|--------|
| `enrichSessions()` | Up to **2 × N** `usersService.findOne()` per history row | `GET /calls` P95 **1804ms** with 100 rows |
| `getPendingRequestsForCreator()` | One `findOne()` per pending request | Scales with ring queue depth |
| `findCallRequest()` | Separate lookups for caller + creator names | Every poll/accept path |

### 2. Full-Table Fetch — Creators (`creators.service.ts`)

| Location | Issue | Impact |
|----------|-------|--------|
| `findOne(id)` | Called `fetchActiveFromSupabase()` → loads **all** active creators, then `.find()` | Every `requestCall`, `acceptCall`, `endCall` paid full list cost |

### 3. Sequential Query Waterfalls — Admin Analytics

| Service | Method | Queries (before) | Issue |
|---------|--------|------------------|-------|
| `FinanceService` | `getOverview()` | **10 sequential** | Revenue, activity, withdrawals each awaited in series |
| `FinanceService` | `getRevenueChart()` | **4 sequential** | Payments, earnings, calls, withdrawals |
| `AdminService` | `getDashboardStats()` | **9 sequential** | Count + sum queries in series |

**Measured impact:** `GET /admin/finance/overview` P50 **2950ms**, `GET /admin/dashboard` P50 **2817ms**.

### 4. Expensive Joins — Finance (`finance.service.ts`)

| Location | Issue | Impact |
|----------|-------|--------|
| `getTopCreators()` | PostgREST nested join `creator_earnings → users → calls` on **full earnings table** | Repeated join per row; PostgREST fan-out |

### 5. Full Table Scans — Analytics

| Location | Issue |
|----------|-------|
| `getCallAnalytics()` | `SELECT status, duration_seconds, coins_spent` from entire `calls` table |
| `getDashboardStats()` | `SELECT coins_spent, coins_deducted` from entire `calls` table |
| `getOverview()` | Multiple unbounded `SELECT` without aggregation RPCs |

### 6. Duplicate DB Calls

| Location | Issue |
|----------|-------|
| `UsersService.updateCoins()` | RPC `adjust_user_coins` returns new balance, then **re-fetches** full user row |
| `assembleCallEndSummary()` | `fetchGiftTotalsForCall` + `fetchCreatorCallEarnings` were sequential (now parallel) |
| `CreatorsService.getWalletBalance()` | Profile lookup → wallet lookup (2 round trips; unavoidable without view) |
| `GiftService.getCreatorGiftStats()` | `getCreatorProfileByUserId` duplicated across stats + recent endpoints |

### 7. Repeated Joins — Wallet (`wallets.service.ts`)

`getTransactions()` correctly uses `select('*, users(name, full_name)')` — **no N+1**. Join is appropriate here.

### 8. Gift Module — Generally Healthy

- `sendGift` uses atomic `send_gift` RPC (single round trip)
- `getAdminAnalytics` uses `gift_analytics_summary` RPC
- `listSenderHistory` / `listRecentForCreatorProfile` use embedded joins (efficient)

---

## Applied Optimizations (Safe)

### Calls — `calls.service.ts`

1. **Joined history query** — `fetchHistoryRows` now embeds caller/creator names via FK hints (`users!calls_caller_id_fkey`, `users!calls_creator_id_fkey`), eliminating N+1 for history.
2. **Batch user enrichment** — `enrichSessions` uses `findManyByIds()` when names still missing.
3. **Batch pending requests** — single `findManyByIds` for all callers.
4. **Parallel summary assembly** — gift totals + creator earnings fetched with `Promise.all`.
5. **findCallRequest** — batch user lookup before optional creator fallback.

### Users — `users.service.ts`

6. **Added `findManyByIds()`** — single `IN (...)` query for batch name resolution.
7. **`updateCoins`** — uses RPC return value for balance when available.

### Creators — `creators.service.ts`

8. **Added `fetchOneFromSupabase(userId)`** — targeted single-row query with `creator_profiles!inner` join.
9. **`findOne`** — no longer loads entire active creator list.

### Finance — `finance.service.ts`

10. **`getOverview`** — 10 independent queries parallelized with `Promise.all`.
11. **`getRevenueChart`** — 4 queries parallelized.
12. **`getCallAnalytics`** — calls + payments queries parallelized.
13. **`getTopCreators`** — removed nested PostgREST joins; aggregate in memory, then batch-fetch top-10 names + call durations.

### Admin — `admin.service.ts`

14. **`getDashboardStats`** — 9 count/sum queries parallelized with `Promise.all`.

---

## Expected Impact After Deploy

| Endpoint | Before P95 | Expected After | Mechanism |
|----------|-----------|----------------|-----------|
| `GET /calls` (admin) | 1804ms | ~700–900ms | Join eliminates 200 user queries |
| `GET /calls/history` | 761ms | ~600–700ms | Same join |
| `GET /admin/finance/overview` | 2980ms | ~800–1200ms | 10 → 1 parallel wave |
| `GET /admin/dashboard` | 2987ms | ~900–1400ms | 9 → 1 parallel wave |
| `GET /admin/finance/top-creators` | 737ms | ~600–700ms | No nested join fan-out |
| `findOne(creator)` paths | hidden | ~50–100ms saved/call | Single-row vs full list |

*Estimates assume ~560ms network floor to Supabase. Re-benchmark after deploy with:*
```bash
cd "admin panel/backend"
node scripts/api-performance-benchmark.mjs
```

---

## Recommended Follow-Ups (Not Applied — Require Migrations)

| Priority | Item | Rationale |
|----------|------|-----------|
| P1 | Postgres aggregation RPCs for `getOverview`, `getCallAnalytics`, `getDashboardStats` | Replace full-table scans with `SUM/COUNT` in DB |
| P1 | Materialized view `creator_earnings_daily` | Speed up revenue chart + top creators |
| P2 | Index `calls(status, started_at DESC)` | History query filter + sort |
| P2 | Index `payments(status, created_at)` | Finance date-range queries |
| P3 | Redis cache for `GET /creators` (60s TTL) | High read frequency, tolerates staleness |
| P3 | Supabase region co-location with Railway API | ~560ms floor suggests cross-region latency |

---

## Benchmark Tooling

Script: `admin panel/backend/scripts/api-performance-benchmark.mjs`

```bash
# Production
API_BASE=https://api.creomine.com/api \
ADMIN_EMAIL=admin@coincalling.com \
ADMIN_PASSWORD=... \
ITERATIONS=25 \
node scripts/api-performance-benchmark.mjs

# Local (after npm run start:dev)
API_BASE=http://127.0.0.1:5000/api node scripts/api-performance-benchmark.mjs
```

---

## Files Modified

| File | Changes |
|------|---------|
| `admin panel/backend/src/users/users.service.ts` | `findManyByIds`, RPC balance reuse |
| `admin panel/backend/src/calls/calls.service.ts` | Joined history, batch enrichment, parallel summary |
| `admin panel/backend/src/creators/creators.service.ts` | Targeted `findOne`, wallet cleanup |
| `admin panel/backend/src/admin/finance/finance.service.ts` | Parallel queries, top-creators refactor |
| `admin panel/backend/src/admin/admin.service.ts` | Parallel dashboard stats |
| `admin panel/backend/scripts/api-performance-benchmark.mjs` | New benchmark script |
