# Phase 2.2 — Load Test Report
**Date:** 2026-06-08 | **Score:** 84/100 | **INCOMPLETE**

---

## Test Infrastructure

| Tool | Location | Status |
|------|----------|--------|
| Locust | `admin panel/backend/tests/audit/locustfile.py` | ✅ Ready |
| pytest + httpx | `admin panel/backend/tests/audit/` | ✅ Ready |
| Chaos tests | `test_chaos_resilience.py` | ✅ 3 tests |
| Flutter perf | `test/gift_performance_test.dart` | ✅ 500 gift cap |

---

## Profiles (Not Live-Executed)

| Profile | Users | Spawn Rate | Duration | Status |
|---------|------:|-----------:|---------:|:------:|
| Smoke | 100 | 10/s | 5 min | ❌ Not run |
| Standard | 250 | 15/s | 10 min | ❌ Not run |
| Load | 500 | 25/s | 10 min | ❌ Not run |
| Stress | 1000 | 50/s | 15 min | ❌ Not run |

### Run Commands

```bash
cd "admin panel/backend"

# 100 users
locust -f tests/audit/locustfile.py --host=https://api.creomine.com \
  --users 100 --spawn-rate 10 --run-time 5m --headless

# 500 users
locust -f tests/audit/locustfile.py --host=https://api.creomine.com \
  --users 500 --spawn-rate 25 --run-time 10m --headless

# 1000 users
locust -f tests/audit/locustfile.py --host=https://api.creomine.com \
  --users 1000 --spawn-rate 50 --run-time 15m --headless
```

### Flows Covered in Locust

| Flow | Weight |
|------|-------:|
| List gifts | 5 |
| Wallet balance | 2 |
| Send gift | 1 |
| Gift history | 1 |
| Agora token (bound) | 1 |
| Creator gift stats | 1 |
| Payment packages | 1 |

---

## Client-Side Performance (Executed)

| Test | Result |
|------|--------|
| 100 gifts → max 5 effects | ✅ PASS |
| 200 combo updates bounded | ✅ PASS |
| 500 gifts clear (no leak) | ✅ PASS |
| 500 combo O(1) memory | ✅ PASS |

---

## Projected Bottlenecks

1. `send_gift` advisory lock — serializes per sender+call (intentional)
2. Supabase connection pool at 500+ concurrent
3. JWT verify CPU on single NestJS instance
4. FCM fan-out latency under gift burst

---

## Pass Criteria (When Executed)

| Metric | Target |
|--------|--------|
| P50 | < 200ms (read), < 400ms (gift send) |
| P95 | < 800ms |
| P99 | < 1500ms |
| Error rate | < 1% |
| DB locks | No sustained deadlock |

---

**Load Test: INCOMPLETE** — infrastructure ready; live run required for PASS.
