"""
Creomine load test — profiles: 100 / 250 / 500 / 1000 users

Auth (Phase 2.3I):
  1. Production admin (default): POST /api/auth/login on_start — no local JWT_SECRET needed
  2. App-user flows: node scripts/prepare-load-test-auth.mjs --write-env (requires FIREBASE_* in .env)

Run:
  python -m locust -f tests/audit/locustfile.py --host=https://api.creomine.com \\
    --users 100 --spawn-rate 20 --headless --run-time 3m
"""

import os
import uuid

import jwt
from locust import HttpUser, between, task

ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "admin@coincalling.com")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "password123")
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "")

JWT_SECRET = os.getenv("JWT_SECRET", "")
CALLER_ID = os.getenv("CALLER_ID", "00000000-0000-0000-0000-000000000001")
CREATOR_ID = os.getenv("CREATOR_ID", "00000000-0000-0000-0000-000000000002")
CALLER_TOKEN = os.getenv("CALLER_TOKEN", "")
CREATOR_TOKEN = os.getenv("CREATOR_TOKEN", "")
CALL_ID = os.getenv("CALL_ID", "00000000-0000-0000-0000-000000000003")
GIFT_ID = os.getenv("GIFT_ID", "00000000-0000-0000-0000-000000000004")
CHANNEL = os.getenv("CHANNEL_NAME", "ch_load_test")
HAS_APP_TOKEN = bool(CALLER_TOKEN and CREATOR_TOKEN)


def mint_token(user_id: str) -> str:
    if not JWT_SECRET:
        raise RuntimeError("JWT_SECRET unset for local mint")
    return jwt.encode({"userId": user_id, "sub": user_id}, JWT_SECRET, algorithm="HS256")


class CreomineUser(HttpUser):
    wait_time = between(0.2, 1.0)

    def on_start(self):
        if ADMIN_TOKEN:
            self.admin_token = ADMIN_TOKEN
        else:
            with self.client.post(
                "/api/auth/login",
                json={"email": ADMIN_EMAIL, "password": ADMIN_PASSWORD},
                name="/api/auth/login",
                catch_response=True,
            ) as resp:
                if not resp.ok:
                    resp.failure(f"admin login {resp.status_code}")
                    self.admin_token = None
                    return
                self.admin_token = resp.json().get("accessToken")
                if not self.admin_token:
                    resp.failure("missing accessToken")

        if CALLER_TOKEN:
            self.caller_token = CALLER_TOKEN
        elif self.admin_token:
            self.caller_token = self.admin_token
        else:
            self.caller_token = mint_token(CALLER_ID) if JWT_SECRET else ""

        if CREATOR_TOKEN:
            self.creator_token = CREATOR_TOKEN
        elif self.admin_token:
            self.creator_token = self.admin_token
        else:
            self.creator_token = mint_token(CREATOR_ID) if JWT_SECRET else ""

        self.headers = {"Authorization": f"Bearer {self.caller_token}"}
        self.admin_headers = {"Authorization": f"Bearer {self.admin_token}"} if self.admin_token else self.headers

    @task(2)
    def list_gifts(self):
        self.client.get("/api/gifts", headers=self.headers, name="/api/gifts")

    @task(3)
    def admin_dashboard(self):
        if not self.admin_token:
            return
        self.client.get("/api/admin/dashboard", headers=self.admin_headers, name="/api/admin/dashboard")

    @task(2)
    def admin_finance_overview(self):
        if not self.admin_token:
            return
        self.client.get(
            "/api/admin/finance/overview",
            headers=self.admin_headers,
            name="/api/admin/finance/overview",
        )

    @task(2)
    def admin_calls(self):
        if not self.admin_token:
            return
        self.client.get("/api/calls", headers=self.admin_headers, name="/api/calls")

    @task(2)
    def active_call_me(self):
        self.client.get("/api/calls/active/me", headers=self.headers, name="/api/calls/active/me")

    @task(1)
    def wallet_balance(self):
        if not HAS_APP_TOKEN:
            return
        self.client.get("/api/wallet", headers=self.headers, name="/api/wallet")

    @task(1)
    def send_gift(self):
        if not HAS_APP_TOKEN or not GIFT_ID:
            return
        self.client.post(
            "/api/gifts/send",
            headers=self.headers,
            json={
                "giftId": GIFT_ID,
                "creatorId": CREATOR_ID,
                "callId": CALL_ID,
                "idempotencyKey": str(uuid.uuid4()),
            },
            name="/api/gifts/send",
        )

    @task(1)
    def gift_history(self):
        if not HAS_APP_TOKEN:
            return
        self.client.get("/api/gifts/history", headers=self.headers, name="/api/gifts/history")

    @task(1)
    def agora_token(self):
        if not HAS_APP_TOKEN:
            return
        self.client.post(
            "/api/calls/agora-token",
            headers=self.headers,
            json={"channelName": CHANNEL},
            name="/api/calls/agora-token",
        )

    @task(1)
    def creator_stats(self):
        if not HAS_APP_TOKEN:
            return
        self.client.get(
            "/api/listener/gifts/stats",
            headers={"Authorization": f"Bearer {self.creator_token}"},
            name="/api/listener/gifts/stats",
        )

    @task(1)
    def packages(self):
        self.client.get("/api/payments/packages", headers=self.headers, name="/api/payments/packages")
