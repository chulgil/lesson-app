"""Post schemas."""

import datetime as _dt

from pydantic import BaseModel, ConfigDict


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
    author_name: str = ""
    post_type: str = "notice"
    title: str
    content: str
