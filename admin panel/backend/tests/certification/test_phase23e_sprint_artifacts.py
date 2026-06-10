"""Phase 2.3E — Sprint 1–7 artifact verification (static)."""

from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[4]

SPRINT_MIGRATIONS = [
    ("Sprint 2 RBAC", "admin panel/backend/supabase/migrations/20260610120000_admin_rbac_audit_sprint2.sql"),
    ("Sprint 3 Wallet", "admin panel/backend/supabase/migrations/20260610140000_user_wallet_integrity_sprint3.sql"),
    ("Sprint 4 Payment", "admin panel/backend/supabase/migrations/20260610160000_payment_verify_sprint4.sql"),
    ("Sprint 5 Call Billing", "admin panel/backend/supabase/migrations/20260610180000_call_billing_integrity_sprint5.sql"),
    ("Sprint 6 Withdrawals", "admin panel/backend/supabase/migrations/20260610200000_creator_ledger_withdrawal_sprint6.sql"),
    ("Sprint 7 Reconciliation", "admin panel/backend/supabase/migrations/20260610220000_reconciliation_observability_sprint7.sql"),
]

SPRINT_REPORTS = [
    "STARTUP_VALIDATOR_IMPLEMENTATION_REPORT.md",
    "SPRINT2_RBAC_AUDIT_IMPLEMENTATION_REPORT.md",
    "SPRINT3_USER_WALLET_IMPLEMENTATION_REPORT.md",
    "SPRINT4_PAYMENT_IMPLEMENTATION_REPORT.md",
    "SPRINT5_CALL_BILLING_IMPLEMENTATION_REPORT.md",
    "SPRINT6_CREATOR_LEDGER_WITHDRAWAL_IMPLEMENTATION_REPORT.md",
    "SPRINT7_RECONCILIATION_OBSERVABILITY_IMPLEMENTATION_REPORT.md",
]


@pytest.mark.parametrize("label,rel_path", SPRINT_MIGRATIONS)
def test_sprint_migration_exists(label, rel_path):
    path = REPO / rel_path
    assert path.is_file(), f"{label} migration missing: {rel_path}"


@pytest.mark.parametrize("report", SPRINT_REPORTS)
def test_sprint_report_exists(report):
    assert (REPO / report).is_file(), f"Implementation report missing: {report}"


def test_startup_validator_module():
    assert (REPO / "admin panel/backend/src/startup/startup-validator.ts").is_file()


def test_reconciliation_module():
    assert (REPO / "admin panel/backend/src/reconciliation/reconciliation.service.ts").is_file()


def test_observability_module():
    assert (REPO / "admin panel/backend/src/observability/metrics.service.ts").is_file()
