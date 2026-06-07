# Section 5 — FCM Validation Report
**Date:** 2026-06-08 | **PARTIAL PASS**

---

## Payload Audit

| Event | notification | data | Android priority | Dedup tag |
|-------|:------------:|:----:|:----------------:|:---------:|
| gift_received | ✅ title/body | ✅ full | high | giftTransactionId |
| gift_reply | ✅ title/body | ✅ full | high | reply_{txnId} |
| incoming_call | ✅ | ✅ | high | — |
| presence | N/A | — | — | — |

---

## State Matrix

| State | gift_received | gift_reply | incoming_call |
|-------|:-------------:|:----------:|:-------------:|
| Foreground | ✅ overlay | ✅ snackbar | ✅ IncomingCallScreen |
| Background | ✅ system notif | ✅ system notif | ✅ system notif |
| Terminated | ✅ tap→dispatch | ✅ tap→dispatch | ✅ initial message |
| Locked screen | ⚠️ device QA | ⚠️ device QA | ✅ high priority |

---

## Duplicate Prevention

| Layer | Mechanism |
|-------|-----------|
| Server | `android.notification.tag` per transaction |
| Client | `GiftFcmDispatcher._handledKeys` |
| Overlay | Sequential queue, 3s timer |
| Reply | `reply:{txnId}` dedup key |

---

## Client Fixes (Phase 2.2)

- FCM `shutdown()` on logout
- Token refresh subscription leak fixed
- Background handler logs gift events

---

## Tests

`test/fcm_gift_dispatcher_test.dart` — **2/2 PASS**

**FCM VALIDATION: PARTIAL PASS** — code complete; locked-screen physical QA pending.
