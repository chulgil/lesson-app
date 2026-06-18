// 레슨 기능의 공개 조회 및 액션 provider 진입점입니다.
library;

export 'domain/entities/lesson.dart';
export 'domain/entities/teaching_resource.dart'
    show TeachingResource, TeachingResourceType;
export 'presentation/providers/booking_providers.dart';
export 'presentation/providers/feedback_template_providers.dart'
    show
        FeedbackTemplatesNotifier,
        feedbackTemplatesByCategoryProvider,
        feedbackTemplatesNotifierProvider,
        feedbackTemplatesProvider;
export 'presentation/providers/lesson_confirmation_provider.dart';
export 'presentation/widgets/lesson_detail/attendance_actions.dart'
    show confirmAttendance;
export 'presentation/providers/lesson_crud_provider.dart';
export 'presentation/providers/lesson_note_providers.dart'
    show studentLessonNotesProvider;
export 'presentation/providers/lesson_repository_provider.dart'
    show lessonRepositoryProvider;
export 'presentation/providers/lesson_stats_provider.dart'
    show lessonStatsProvider;
export 'presentation/providers/teaching_resource_providers.dart'
    show resourcesByIdsProvider;
export 'presentation/providers/tip_template_providers.dart'
    show
        TipTemplatesNotifier,
        currentTeacherIdProvider,
        tipTemplatesByCategoryProvider,
        tipTemplatesNotifierProvider,
        tipTemplatesProvider;
export 'presentation/widgets/lesson_export_sheet.dart';
