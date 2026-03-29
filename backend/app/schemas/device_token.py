"""Device token schemas."""

from pydantic import BaseModel, ConfigDict


class DeviceTokenCreate(BaseModel):
    """Register a new device token."""

    token: str
    platform: str  # "ios" or "android"


class DeviceTokenResponse(BaseModel):
    """Device token representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    token: str
    platform: str
