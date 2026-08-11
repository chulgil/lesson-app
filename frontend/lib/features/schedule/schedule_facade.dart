// Schedule feature public boundary.
library;

export 'domain/entities/cancel_reason.dart' show CancelReason, CancelReasonX;
export 'domain/entities/group_class.dart'
    show GroupClass, GroupClassType, NoShowPolicy;
export 'domain/entities/schedule_confirmation_card.dart' show ScheduleCardType;
export 'domain/entities/unified_lesson_request.dart'
    show ProposerRole, UnifiedLessonRequest, UnifiedRequestStatus;
export 'domain/services/cancellation_credit_policy.dart'
    show CancellationCreditPolicy, CancellationCreditOutcome;
export 'presentation/services/booking_notification_service.dart'
    show BookingNotificationService;
// 그룹 클래스 정의 조회 — 진입점 배선(J12)·수강권 표시(J13)가 클래스명을 읽는 경로.
// 쓰기(GroupClassFormNotifier)는 schedule feature 내부에 둔다.
export 'presentation/providers/group_class_providers.dart'
    show groupClassByIdProvider, teacherGroupClassesProvider;
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
        studentUnifiedRequestsProvider,
        teacherNameMapProvider,
        teacherUnifiedRequestsProvider,
        todayRequestsProvider,
        UnifiedLessonRequestActions,
        unifiedLessonRequestRepositoryProvider;
// 운영시간 SSOT — profile 5묶음 상태/home 게이지/settings 부팅 마이그레이션이 소비.
export 'presentation/providers/teacher_availability_providers.dart'
    show teacherAvailabilityProvider, teacherAvailabilityRepositoryProvider;
