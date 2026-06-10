"""Phase 2.3E — Recovery drill protocol (health + startup fail-closed)."""

from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[4]


def test_health_endpoints_in_controller():
    src = (REPO / "admin panel/backend/src/health.controller.ts").read_text(encoding="utf-8")
    assert "@Get('health')" in src or "@Get(\"health\")" in src
    assert "health/ready" in src
    assert "health/startup" in src


def test_main_excludes_health_from_api_prefix():
    src = (REPO / "admin panel/backend/src/main.ts").read_text(encoding="utf-8")
    assert "health/ready" in src
    assert "health/startup" in src


def test_startup_validator_fail_closed():
    src = (REPO / "admin panel/backend/src/startup/startup-validator.ts").read_text(encoding="utf-8")
    assert "startup_validation_failed" in src
    assert "emitFatalAndExit" in src or "process.exit" in src


def test_financial_guard_blocks_inmemory():
    src = (REPO / "admin panel/backend/src/startup/financial-guard.ts").read_text(encoding="utf-8")
    assert "inmemory_fallback_attempted" in src


def test_reconciliation_scheduler_disable_env():
    src = (REPO / "admin panel/backend/src/reconciliation/reconciliation.scheduler.ts").read_text(
        encoding="utf-8"
    )
    assert "DISABLE_RECONCILIATION_SCHEDULER" in src
