"""Post schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict, Field


class TeacherPostResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    author_id: str
    author_name: str
    post_type: str
    title: str
    content: str
    created_at: _dt.datetime


class TeacherPostCreate(BaseModel):
    author_id: str
    author_name: str = Field(default="", max_length=100)
    post_type: str = Field(default="notice", max_length=50)
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1, max_length=10000)
