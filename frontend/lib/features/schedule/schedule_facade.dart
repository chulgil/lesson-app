// Schedule feature public boundary.
library;

export 'domain/entities/cancel_reason.dart' show CancelReason, CancelReasonX;
export 'domain/entities/schedule_confirmation_card.dart' show ScheduleCardType;
export 'domain/entities/unified_lesson_request.dart'
    show ProposerRole, UnifiedLessonRequest, UnifiedRequestStatus;
export 'domain/services/cancellation_credit_policy.dart'
    show CancellationCreditPolicy, CancellationCreditOutcome;
export 'presentation/providers/schedule_confirmation_card_providers.dart'
    show
        pendingScheduleConfirmationCardsProvider,
        scheduleConfirmationCardNotifierProvider;
export 'presentation/providers/unified_lesson_request_providers.dart'
    show
        academyNameMapProvider,
        unifiedRequestByIdProvider,
        studentNameMapProvider,
        studentTodayRequestsProvider,
        teacherNameMapProvider,
        teacherUnifiedRequestsProvider,
        todayRequestsProvider,
        UnifiedLessonRequestActions,
        unifiedLessonRequestRepositoryProvider;
