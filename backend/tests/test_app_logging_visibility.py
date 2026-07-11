"""#1180 — app.* INFO logs must be visible under uvicorn's default logging.

Uvicorn only configures its own loggers ("uvicorn", "uvicorn.access"); the
root logger keeps no handlers at WARNING, so every app logger.info() call was
dropped in beta — the #1142 mock-OTP log line never reached docker logs even
though caplog-based tests passed (caplog bypasses handlers).
"""

import inspect
import logging

import pytest

from app.core.logging_config import configure_app_logging


@pytest.fixture()
def bare_app_logger():
    """Simulate a fresh uvicorn worker: `app` logger untouched."""
    app_logger = logging.getLogger("app")
    saved_level = app_logger.level
    saved_handlers = list(app_logger.handlers)
    app_logger.handlers.clear()
    app_logger.setLevel(logging.NOTSET)
    yield app_logger
    app_logger.handlers[:] = saved_handlers
    app_logger.setLevel(saved_level)


def test_info_dropped_without_configuration(bare_app_logger):
    """Documents the failure mode: bare app logger inherits root WARNING."""
    root = logging.getLogger()
    saved_root_level = root.level
    root.setLevel(logging.WARNING)
    try:
        assert not bare_app_logger.isEnabledFor(logging.INFO)
    finally:
        root.setLevel(saved_root_level)


def test_configure_makes_app_info_visible(bare_app_logger):
    configure_app_logging()
    assert bare_app_logger.isEnabledFor(logging.INFO)
    # Root has no handlers under uvicorn, so the app logger needs its own.
    assert bare_app_logger.handlers


def test_configure_is_idempotent(bare_app_logger):
    configure_app_logging()
    configure_app_logging()
    assert len(bare_app_logger.handlers) == 1


def test_configure_respects_explicit_level(bare_app_logger):
    bare_app_logger.setLevel(logging.ERROR)
    configure_app_logging()
    assert bare_app_logger.level == logging.ERROR


def test_configure_leaves_root_and_uvicorn_untouched(bare_app_logger):
    root = logging.getLogger()
    uvicorn_logger = logging.getLogger("uvicorn")
    root_handlers_before = list(root.handlers)
    uvicorn_handlers_before = list(uvicorn_logger.handlers)
    configure_app_logging()
    assert root.handlers == root_handlers_before
    assert uvicorn_logger.handlers == uvicorn_handlers_before


def test_main_module_wires_configure_app_logging():
    """Wiring guard: uvicorn workers import app.main, so the call must live there."""
    import app.main as main_module

    assert "configure_app_logging()" in inspect.getsource(main_module)
