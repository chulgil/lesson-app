"""Regression: Enum columns must read camelCase DB values (beta /lessons 500).

Root cause (2026-06-18): the Alembic migrations create the Postgres enum types
with the enum *.value* strings (camelCase, e.g. ``academyFull``), but the model
columns declared ``Enum(X, native_enum=True)`` *without* ``values_callable``.
SQLAlchemy therefore expected the member *names* (snake_case, ``academy_full``).
Reading a real row failed with::

    LookupError: 'academyFull' is not among the defined enum values.
        Enum name: lessonvisibility. Possible values: academy_ful.., academy_bus..

which surfaced as ``GET /api/v1/lessons -> 500`` for any teacher with lessons.

Each case below uses a member whose *name differs from its value* (the only ones
that break) and exercises the exact failing call from the production traceback,
``Enum._object_value_for_elem`` — independent of DB dialect.
"""

import pytest

from app.models.lesson import Lesson, LessonSource, LessonVisibility
from app.models.request_event import RequestEvent, RequestEventType
from app.models.teacher_announcement import (
    TeacherAnnouncement,
    TeacherAnnouncementType,
)

# (model, column_name, raw value as stored by the migration, expected member).
# Only members where name != value are listed — those are the ones that 500.
CAMELCASE_ENUM_COLUMNS = [
    (Lesson, "visibility", "academyFull", LessonVisibility.academy_full),
    (
        Lesson,
        "lesson_source",
        "subscriptionGenerated",
        LessonSource.subscription_generated,
    ),
    (
        RequestEvent,
        "event_type",
        "lessonCancelledByTeacher",
        RequestEventType.lesson_cancelled_by_teacher,
    ),
    (
        TeacherAnnouncement,
        "type",
        "dayOff",
        TeacherAnnouncementType.day_off,
    ),
]


@pytest.mark.parametrize(
    "model, column, db_value, expected",
    CAMELCASE_ENUM_COLUMNS,
    ids=lambda v: v if isinstance(v, str) else "",
)
def test_enum_column_maps_camelcase_db_value(model, column, db_value, expected):
    """The Enum column maps the camelCase value stored in the DB to its member."""
    col_type = model.__table__.c[column].type
    assert col_type._object_value_for_elem(db_value) == expected
