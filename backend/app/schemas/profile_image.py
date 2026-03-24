"""Profile image upload schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


class ProfileImageUploadResponse(BaseModel):
    """Response after successful image upload."""

    model_config = ConfigDict(from_attributes=True)

    image_url: str
    image_type: str  # "profile" | "background"
    file_key: str
    uploaded_at: _dt.datetime


class ProfileImageDeleteResponse(BaseModel):
    """Response after image deletion."""

    message: str = "Image deleted successfully"
