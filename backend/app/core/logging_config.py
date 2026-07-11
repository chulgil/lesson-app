"""Application logging visibility under uvicorn — #1180.

Uvicorn's default log config only wires its own loggers ("uvicorn",
"uvicorn.access"); the root logger keeps no handlers at WARNING, so every
``logging.getLogger(__name__).info(...)`` in the ``app`` namespace is dropped
in deployed containers. Attach one INFO stderr handler to the ``app``
namespace logger instead of the root so the uvicorn/alembic logger trees stay
untouched (#1177).
"""

import logging

_APP_LOGGER_NAME = "app"
_HANDLER_MARKER = "_lessonaza_app_log_handler"


def configure_app_logging() -> None:
    """Make ``app.*`` INFO logs visible. Idempotent; root/uvicorn untouched."""
    app_logger = logging.getLogger(_APP_LOGGER_NAME)

    # Respect an explicit level if one was set (tests, ops overrides).
    if app_logger.level == logging.NOTSET:
        app_logger.setLevel(logging.INFO)

    if any(getattr(handler, _HANDLER_MARKER, False) for handler in app_logger.handlers):
        return

    handler = logging.StreamHandler()
    handler.setFormatter(logging.Formatter("%(levelname)s:     %(name)s - %(message)s"))
    setattr(handler, _HANDLER_MARKER, True)
    app_logger.addHandler(handler)
