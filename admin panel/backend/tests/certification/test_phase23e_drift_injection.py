"""Phase 2.3E — Reconciliation drift injection protocol (SQL contract validation)."""

from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[4]
MIGRATION = REPO / "admin panel/backend/supabase/migrations/20260610220000_reconciliation_observability_sprint7.sql"

DRIFT_CHECKS = [
    "U-DRIFT-01",
    "U-DRIFT-02",
    "C-DRIFT-01",
    "M-U-01",
    "M-U-02",
    "SYS-DRIFT-01",
    "N-W-LOCK",
    "D-P-01",
    "D-P-02",
    "D-P-04",
    "D-P-06",
    "ORPHAN-CT",
    "REBUILD-SAMPLE",
]

TIERS = [f"T{i}" for i in range(9)]


@pytest.fixture(scope="module")
def migration_sql() -> str:
    assert MIGRATION.is_file(), "Sprint 7 reconciliation migration not found"
    return MIGRATION.read_text(encoding="utf-8")


@pytest.mark.parametrize("check_id", DRIFT_CHECKS)
def test_drift_check_defined_in_migration(check_id, migration_sql):
    assert check_id in migration_sql, f"Drift check {check_id} not in reconciliation migration"


@pytest.mark.parametrize("tier", TIERS)
def test_reconciliation_tier_executor(tier, migration_sql):
    assert f"reconciliation_execute_{tier.lower()}" in migration_sql


def test_p0_auto_freeze_trigger(migration_sql):
    assert "trg_reconciliation_p0_freeze" in migration_sql
    assert "wallet_freeze_flags" in migration_sql


def test_severity_enum_includes_p0_p1(migration_sql):
    assert "'P0'" in migration_sql
    assert "'P1'" in migration_sql
    assert "'WARN'" in migration_sql
    assert "'INFO'" in migration_sql


def test_fingerprint_dedupe(migration_sql):
    assert "uq_reconciliation_findings_fingerprint" in migration_sql
