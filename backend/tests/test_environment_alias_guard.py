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


# --- Dead-zone tests: codex audit follow-up ---
#
# Threat model: values that *look* alias-like but aren't in the map must NOT
# silently become "production". Without these guards, a typo on the operator's
# part ("prdouction", "produc", " prod\n") could either:
#   (a) match a guard accidentally (false-positive prod), or
#   (b) be stored as-is and bypass all guards (false-negative prod).
# The current normalizer strips + lowercases + alias-lookup. These tests pin
# the boundary so future "helpful" fuzzy matching can't be added without
# breaking the contract.


@pytest.mark.parametrize(
    "padded,canonical",
    [
        ("  prod  ", "production"),
        ("\tprod\n", "production"),
        ("  PRODUCTION  ", "production"),
        ("\n\nbeta\t", "beta"),
    ],
)
def test_whitespace_padded_aliases_normalize(padded: str, canonical: str) -> None:
    """ENVIRONMENT values with leading/trailing whitespace are stripped before alias lookup."""
    s = _make_settings(padded)
    assert s.ENVIRONMENT == canonical


@pytest.mark.parametrize(
    "near_miss",
    [
        "prdouction",  # transposition typo
        "produc",  # truncation
        "production-like",  # punctuation suffix
        "prod!",  # punctuation
        "preprod",  # prefix
        "prodtest",  # concat
        "stagin",  # truncation
        "betaa",  # double letter
    ],
)
def test_near_miss_values_do_not_match_production(near_miss: str) -> None:
    """Strings that resemble an alias but aren't exact matches must stay as-is and fail closed."""
    s = _make_settings(near_miss)
    assert s.ENVIRONMENT == near_miss.lower()
    assert s.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS


@pytest.mark.parametrize(
    "empty_like",
    ["", "   ", "\t\n", None],
)
def test_empty_and_whitespace_only_values_do_not_match_production(empty_like: object) -> None:
    """Empty / whitespace-only / None values must NOT normalize to a production-like name."""
    s = _make_settings(empty_like if isinstance(empty_like, str) else "")
    assert s.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS


def test_near_miss_prod_value_does_not_bypass_jwt_guard(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """A near-miss like 'prodtest' must NOT activate production guards.

    But it also must NOT fail-OPEN — the JWT guard simply doesn't fire because
    the environment is unrecognized. That's the contract: unknown values
    behave like 'development' for guard *triggering*, never like production.
    """
    from app.core import config as config_module

    test_settings = Settings(
        ENVIRONMENT="prodtest",
        JWT_SECRET_KEY="dev-only-insecure-jwt-secret-change-before-production",
        INTERNAL_API_KEY="weak",
    )
    monkeypatch.setattr(config_module, "settings", test_settings)
    # validate_runtime_configuration must not raise — environment is unknown,
    # therefore not production-like, therefore weak secret is not checked.
    validate_runtime_configuration()
    assert test_settings.ENVIRONMENT == "prodtest"
    assert test_settings.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS
