/// Lesson form widgets barrel file
///
/// This file re-exports all lesson form related widgets and helpers
/// for backward compatibility.
library;

// Models
export 'lesson_form/lesson_student_info.dart';
export 'lesson_form/edit_lesson_widgets.dart'
    show
        EditLessonStudentInfo,
        EditLessonStudentCard,
        LessonActionButtons,
        showCancelLessonDialog,
        showDeleteLessonDialog,
        showEditLessonExitConfirmation;

// Widgets
export 'lesson_form/lesson_student_selector.dart';
export 'lesson_form/lesson_datetime_section.dart';
export 'lesson_form/lesson_duration_selector.dart';
export 'lesson_form/lesson_recurring_section.dart';
export 'lesson_form/lesson_content_fields.dart';
export 'lesson_form/lesson_reminder_section.dart';

// Bottom sheets & dialogs
export 'lesson_form/lesson_student_picker_sheet.dart';
export 'lesson_form/lesson_exit_dialog.dart';

// Helper functions
export 'lesson_form/lesson_form_helpers.dart';
