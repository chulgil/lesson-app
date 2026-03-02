from fastapi import Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from app.core.config import settings


class LocaleMiddleware(BaseHTTPMiddleware):
    """Middleware that extracts locale from Accept-Language header."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        accept_lang = request.headers.get("Accept-Language", settings.DEFAULT_LOCALE)
        locale = parse_accept_language(accept_lang)

        if locale not in settings.SUPPORTED_LOCALES:
            locale = settings.DEFAULT_LOCALE

        request.state.locale = locale
        response = await call_next(request)
        response.headers["Content-Language"] = locale
        return response


def parse_accept_language(header: str) -> str:
    """Parse Accept-Language header and return the best matching locale.

    Example: 'ko-KR,ko;q=0.9,en;q=0.8' -> 'ko'
    """
    for part in header.split(","):
        lang = part.split(";")[0].strip().split("-")[0].lower()
        if lang in settings.SUPPORTED_LOCALES:
            return lang
    return settings.DEFAULT_LOCALE


def get_locale(request: Request) -> str:
    """Extract locale from request state (set by LocaleMiddleware)."""
    return getattr(request.state, "locale", settings.DEFAULT_LOCALE)


class TranslationService:
    """Server-side translation service that loads strings from DB with fallback."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self._cache: dict[str, dict[str, str]] = {}  # locale -> {key: value}

    async def get(self, key: str, locale: str, **kwargs: str) -> str:
        """Return translated string for the given key and locale.

        Falls back to default locale, then to the key itself.
        Template variables can be passed as kwargs.
        """
        translation = await self._get_from_cache_or_db(key, locale)
        if not translation:
            translation = await self._get_from_cache_or_db(key, settings.DEFAULT_LOCALE)
        if not translation:
            return key
        return translation.format(**kwargs) if kwargs else translation

    async def _get_from_cache_or_db(self, key: str, locale: str) -> str | None:
        """Look up translation in cache first, then DB."""
        # Check cache
        if locale in self._cache and key in self._cache[locale]:
            return self._cache[locale][key]

        # Query DB (lazy import to avoid circular dependency)
        from app.models.i18n import I18nTranslation

        result = await self.db.scalar(
            select(I18nTranslation.value).where(
                I18nTranslation.key == key,
                I18nTranslation.locale == locale,
            )
        )
        if result:
            self._cache.setdefault(locale, {})[key] = result
        return result
