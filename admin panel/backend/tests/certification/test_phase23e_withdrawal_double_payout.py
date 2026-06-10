"""Phase 2.3E — Withdrawal double-payout prevention contract validation."""

from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[4]


@pytest.fixture(scope="module")
def withdrawal_migration_sql() -> str:
    path = REPO / "admin panel/backend/supabase/migrations/20260610200000_creator_ledger_withdrawal_sprint6.sql"
    assert path.is_file()
    return path.read_text(encoding="utf-8")


@pytest.fixture(scope="module")
def reconciliation_sql() -> str:
    path = REPO / "admin panel/backend/supabase/migrations/20260610220000_reconciliation_observability_sprint7.sql"
    return path.read_text(encoding="utf-8")


def test_withdrawal_state_machine_rpcs(withdrawal_migration_sql):
    for rpc in [
        "request_creator_withdrawal",
        "approve_creator_withdrawal",
        "settle_creator_withdrawal",
        "fail_creator_withdrawal",
    ]:
        assert rpc in withdrawal_migration_sql


def test_withdrawal_idempotency_records(withdrawal_migration_sql):
    assert "withdrawal_idempotency_records" in withdrawal_migration_sql


def test_locked_balance_column(withdrawal_migration_sql):
    assert "locked_balance" in withdrawal_migration_sql


def test_double_payout_detection_checks(reconciliation_sql):
    for check in ["D-P-01", "D-P-02", "D-P-04", "D-P-06"]:
        assert check in reconciliation_sql


def test_jest_withdrawal_specs_exist():
    for s in [
        "admin panel/backend/src/withdrawals/withdrawal-rpc.service.spec.ts",
        "admin panel/backend/src/withdrawals/withdrawals-ledger.spec.ts",
    ]:
        assert (REPO / s).is_file()
