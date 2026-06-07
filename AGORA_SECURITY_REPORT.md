# Section 4 — Agora Security Report
**Date:** 2026-06-08 | **PASS**

---

## Controls

| Control | Implementation |
|---------|----------------|
| Token mint auth | JwtAuthGuard required |
| Participant check | `assertChannelParticipant(userId, channelName, callId?)` |
| Active call lookup | `calls` WHERE channel + active status |
| Ringing lookup | `call_requests` WHERE status=requested |
| callId binding | Optional channel match verification |
| Arbitrary channel | **Removed** from `/api/agora/token` |
| Token in Flutter | Never embedded — backend only |

---

## Attack Results

| Attack | Pre-2.2 | Post-2.2 |
|--------|---------|----------|
| Unauthorized join | ✅ Exploitable | ❌ BLOCKED |
| Forged channel | ✅ Exploitable | ❌ BLOCKED |
| Channel enumeration | ✅ Possible | ❌ BLOCKED |
| Token replay | ⚠️ 1h expiry | ⚠️ Agora TTL |
| Call hijacking | ✅ Possible | ❌ BLOCKED |
| Reconnect bypass | ✅ Possible | ❌ Must re-assert |

---

## Tests

`admin panel/backend/src/calls/agora-security.spec.ts` — **4/4 PASS**

---

## Call Lifecycle Binding

| Stage | Token issued? |
|-------|:-------------:|
| Call request (ringing) | ✅ caller + creator via FCM |
| Call accept | ✅ both participants |
| Mid-call reconnect | ✅ via `/calls/agora-token` |
| Random channel | ❌ DENIED |

**AGORA SECURITY: PASS**
