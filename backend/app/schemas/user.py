"""User-related schemas."""


import datetime as _dt

from pydantic import BaseModel, ConfigDict


class UserResponse(BaseModel):
    """Public user representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str | None = None
    name: str | None = None
    phone: str | None = None
    role: str | None = None
    profile_image_url: str | None = None
    locale: str | None = None
    country: str | None = None
    timezone: str | None = None
    currency: str | None = None
    onboarding_completed: bool = False
    created_at: _dt.datetime | None = None


class UserUpdate(BaseModel):
    """Fields that a user can update on their own profile."""

    name: str | None = None
    phone: str | None = None
    profile_image_url: str | None = None


class RoleUpdate(BaseModel):
    """Update user role (used during onboarding)."""

    role: str


class LocaleUpdate(BaseModel):
    """Update locale / country / timezone / currency settings."""

    locale: str | None = None
    country: str | None = None
    timezone: str | None = None
    currency: str | None = None


class SupportedLocale(BaseModel):
    """Single supported locale entry."""

    locale: str
    language_name: str
    native_name: str
    default_country: str


class SupportedLocalesResponse(BaseModel):
    """List of supported locales."""

    locales: list[SupportedLocale]
