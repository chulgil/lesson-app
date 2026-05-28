"""Regression guard for issue #410 — environment alias normalization.

Threat model:
  Production-like guards (JWT secret strength, IAP default-deny, dev login
  endpoint) test `settings.ENVIRONMENT in {"production", "beta"}`. A typo or
  alias such as ENVIRONMENT=prod, PROD, Production, stg, stage silently
  bypasses every guard because the set membership check is case-sensitive
  and unaware of common synonyms.

Contract:
  Pydantic settings normalizes ENVIRONMENT at load time:
    - case-insensitive: "Production" -> "production"
    - alias map: "prod" -> "production", "stg"/"stage" -> "staging",
                 "dev" -> "development"
  Unknown values are left lower-cased (fail-closed for guards that look
  for whitelisted names).
"""

from __future__ import annotations

import pytest

from app.core.config import (
    PRODUCTION_LIKE_ENVIRONMENTS,
    Settings,
    validate_runtime_configuration,
)


def _make_settings(env: str, **overrides: object) -> Settings:
    """Build a Settings instance with a specific ENVIRONMENT value."""
    return Settings(ENVIRONMENT=env, **overrides)  # type: ignore[call-arg]


@pytest.mark.parametrize(
    "raw,canonical",
    [
        ("prod", "production"),
        ("PROD", "production"),
        ("Production", "production"),
        ("PRODUCTION", "production"),
        ("Beta", "beta"),
        ("BETA", "beta"),
        ("stg", "staging"),
        ("stage", "staging"),
        ("Staging", "staging"),
        ("dev", "development"),
        ("DEV", "development"),
        ("Development", "development"),
    ],
)
def test_environment_aliases_normalize_to_canonical(raw: str, canonical: str) -> None:
    s = _make_settings(raw)
    assert s.ENVIRONMENT == canonical, f"ENVIRONMENT={raw!r} should normalize to {canonical!r}, got {s.ENVIRONMENT!r}"


def test_unknown_environment_is_lowercased_but_not_invented() -> None:
    s = _make_settings("CustomQA")
    assert s.ENVIRONMENT == "customqa"
    assert s.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS


def test_alias_prod_triggers_jwt_strong_secret_guard(monkeypatch: pytest.MonkeyPatch) -> None:
    """ENVIRONMENT=prod must be treated as production by runtime validators.

    Before normalization: 'prod' bypassed PRODUCTION_LIKE_ENVIRONMENTS,
    so validate_runtime_configuration() returned silently with a weak secret.
    After normalization: the guard rejects the weak default secret.
    """
    from app.core import config as config_module

    test_settings = Settings(
        ENVIRONMENT="prod",
        JWT_SECRET_KEY="dev-only-insecure-jwt-secret-change-before-production",
        INTERNAL_API_KEY="x" * 32,
    )
    monkeypatch.setattr(config_module, "settings", test_settings)
    with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
        validate_runtime_configuration()


def test_alias_beta_uppercase_triggers_internal_key_guard(monkeypatch: pytest.MonkeyPatch) -> None:
    """ENVIRONMENT=BETA must still be treated as beta (case-insensitive)."""
    from app.core import config as config_module

    test_settings = Settings(
        ENVIRONMENT="BETA",
        JWT_SECRET_KEY="x" * 64,
        INTERNAL_API_KEY="weak",
    )
    monkeypatch.setattr(config_module, "settings", test_settings)
    with pytest.raises(RuntimeError, match="INTERNAL_API_KEY"):
        validate_runtime_configuration()
