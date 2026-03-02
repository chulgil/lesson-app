# Legacy re-export for backward compatibility.
# Practice recordings are now in app.models.practice
# Lesson recordings are now in app.models.lesson
from app.models.practice import PracticeRecording as Recording  # noqa: F401
