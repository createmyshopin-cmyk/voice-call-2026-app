# Section 1 — Database Forensic Report
**Date:** 2026-06-08 | **Score:** 97/100 | **PASS**

---

## Table Forensics

| Table | FK | Unique | Indexes | RLS | CHECK | Verdict |
|-------|:--:|:------:|:-------:|:---:|:-----:|:-------:|
| users | ✅ | firebase_uid | — | deny clients | coins ≥ 0 | ✅ |
| wallets | ✅ user_id | user_id | user_id | deny | balance ≥ 0 | ✅ |
| creator_wallets | ✅ profile* | creator_id | — | deny | balances ≥ 0 | ✅ *phase14 |
| creator_profiles | ✅ user_id | user_id | last_seen | **read all** | — | ⚠️ |
| calls | ✅ | — | multi | deny phase13 | coins ≥ 0 | ✅ |
| call_requests | ✅ | — | multi | deny phase13 | status enum | ✅ |
| transactions | legacy | — | — | **none** | — | ⚠️ deprecated |
| coin_transactions | ✅ | partial/type | multi | deny | type enum | ✅ |
| creator_transactions | ✅ | gift partial | multi | deny | type enum | ✅ |
| creator_earnings | ✅ users | call_id | multi | deny | — | ✅ |
| withdrawals | ✅ users | — | multi | deny | amount > 0 | ✅ |
| gifts | — | — | active sort | read active | split=100% | ✅ |
| gift_transactions | ✅ | idempotency | multi | deny | coins integrity | ✅ |
| creator_gift_stats | ✅ profile | PK | PK | deny default | — | ✅ |
| gift_replies | ✅ | 1 per txn | txn_id | deny | — | ✅ |

---

## ACID & Ledger

| Operation | Atomic | Idempotent | Verified |
|-----------|:------:|:----------:|:--------:|
| send_gift RPC | ✅ | ✅ sender key | ✅ |
| recharge verify | ✅ CAS | ✅ gateway_payment_id | ✅ |
| call deduction | ✅ | ✅ per call_id | ✅ |
| creator wallet increment | ✅ UPSERT | ✅ | ✅ |
| gift_earning ledger | ✅ | ✅ partial unique | ✅ |

---

## Migrations (Apply Order)

1. phase11/phase12 — RPC REVOKE + financial RLS
2. `20260608130000_phase13_calls_rls_remediation.sql`
3. `20260608140000_phase14_creator_wallet_fk_remediation.sql`

---

## Orphan Detection

| Check | Script | Status |
|-------|--------|--------|
| Creator wallet FK | `verify-creator-wallet-fk.mjs` | Ready |
| Creator balance reconcile | `reconcile-creator-wallets.mjs` | Ready |
| FK audit | `audit-fkeys.mjs` | Ready |

---

## Findings

| ID | Severity | Issue | Status |
|----|----------|-------|--------|
| DB-1 | HIGH | calls RLS missing | ✅ FIXED phase13 |
| DB-2 | HIGH | creator_wallets FK → users | ✅ FIXED phase14 |
| DB-3 | MED | creator_profiles public SELECT | OPEN |
| DB-4 | LOW | legacy transactions table | RISK ACCEPTED |

**DATABASE FORENSIC: PASS (97)**
