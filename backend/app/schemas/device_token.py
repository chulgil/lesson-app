"""Device token schemas."""

from pydantic import BaseModel, ConfigDict


class DeviceTokenCreate(BaseModel):
    """Register a new device token."""

    token: str
    platform: str  # "ios" or "android"


class DeviceTokenResponse(BaseModel):
    """Device token representation.

    raw token 은 응답에 노출하지 않는다 (secret/PII 보호). 클라이언트는 등록 시점에 token 을
    이미 보유하고 있으며, 응답으로 id + platform 만으로 register 성공을 확인할 수 있다.
    """

    model_config = ConfigDict(from_attributes=True)

    id: str
    platform: str
