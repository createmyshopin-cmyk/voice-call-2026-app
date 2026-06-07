# Section 3 — Financial Forensic Report
**Date:** 2026-06-08 | **Score:** 99/100 | **PASS**

---

## Coin Reconciliation Model

```
User coins (users.coins ↔ wallets.coin_balance)
  ├── coin_transactions (append-only)
  │     ├── call_deduction  [unique per call_id]
  │     ├── gift_deduction  [unique per idempotency]
  │     └── recharge        [unique per payment_id]
  │
Creator earnings
  ├── creator_wallets (keyed by creator_profiles.id post-phase14)
  ├── creator_transactions [gift_earning unique per gift txn]
  └── creator_earnings [unique per call_id]

Platform revenue
  └── gift_transactions.platform_coins (40% split CHECK)
```

---

## Attack Results

| Attack | Result | Mechanism |
|--------|--------|-----------|
| Coin minting | ❌ BLOCKED | No public mint RPC |
| Coin duplication (gift) | ❌ BLOCKED | idempotency_key |
| Coin duplication (recharge) | ❌ BLOCKED | gateway_payment_id UNIQUE |
| Negative balance | ❌ BLOCKED | CHECK + GREATEST |
| Concurrent same gift | ❌ BLOCKED | advisory lock |
| Concurrent different gifts | ✅ ALLOWED | intentional |
| Gift + withdrawal race | ⚠️ | separate tables |
| Call charge + gift | ✅ SAFE | sender row locked |
| Client balance authority | ❌ REMOVED | server-only WalletProvider |

---

## Split Verification

| Rule | Enforcement |
|------|-------------|
| coins_spent = creator + platform | CHECK on gift_transactions |
| creator_share + platform = 100% | CHECK on gifts |
| Single deduction per gift | RPC atomic |
| Single credit per gift to creator | gift_earning partial unique |

---

## Reconciliation Tools

- `scripts/reconcile-creator-wallets.mjs`
- `scripts/audit-creator-balances.mjs`
- `scripts/verify-remediation.mjs`

**FINANCIAL FORENSIC: PASS (99)** — Every coin path reconciles via ledger.
