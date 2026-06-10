"""Phase 2.3E — Payment replay / idempotency contract validation."""

from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[4]


@pytest.fixture(scope="module")
def payment_migration_sql() -> str:
    path = REPO / "admin panel/backend/supabase/migrations/20260610160000_payment_verify_sprint4.sql"
    assert path.is_file()
    return path.read_text(encoding="utf-8")


def test_verify_razorpay_payment_atomic_rpc(payment_migration_sql):
    assert "verify_razorpay_payment_atomic" in payment_migration_sql


def test_payment_idempotency_table(payment_migration_sql):
    assert "payment_verify_idempotency_records" in payment_migration_sql


def test_refund_atomic_rpc(payment_migration_sql):
    assert "refund_payment_atomic" in payment_migration_sql


def test_jest_payment_replay_specs_exist():
    specs = [
        "admin panel/backend/src/payments/payment-rpc.service.spec.ts",
        "admin panel/backend/src/payments/payments-verify.spec.ts",
        "admin panel/backend/src/payments/razorpay-webhook.service.spec.ts",
    ]
    for s in specs:
        assert (REPO / s).is_file(), f"Missing payment test: {s}"


def test_webhook_duplicate_dedup_in_spec():
    spec = (REPO / "admin panel/backend/src/payments/razorpay-webhook.service.spec.ts").read_text(
        encoding="utf-8"
    )
    assert "Duplicate webhook" in spec or "duplicate" in spec.lower()
