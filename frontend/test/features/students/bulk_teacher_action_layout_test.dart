import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/lessons/domain/entities/cancellation_policy_hint.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/students/domain/services/bulk_teacher_action_service.dart';
import 'package:lessonaza/features/students/presentation/providers/bulk_teacher_action_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:lessonaza/features/students/presentation/widgets/bulk_message_sheet.dart';

/// §7.119 v3 layout smoke tests — BulkMessageSheet.
///
/// 회귀 가드: 테마 `FilledButton.minimumSize = Size(∞, h)` × 다양한 Sliver/Sheet
/// 컨테이너에서 BoxConstraints 크래시가 일어나지 않는지 확인. flutter analyze 가
/// 잡지 못하는 layout exception 을 takeException()==null 로 가드.
class _StubLessonRepository implements LessonRepository {
  @override
  Future<List<Lesson>> getLessons() async => const [];

  @override
  Future<List<Lesson>> getLessonsByStudent(String studentId) async => const [];

  @override
  Future<List<Lesson>> getLessonsByDate(DateTime date) async => const [];

  @override
  Future<List<Lesson>> getLessonsByDateRange(DateTime s, DateTime e) async =>
      const [];

  @override
  Future<List<Lesson>> getUpcomingLessons({int limit = 10}) async => const [];

  @override
  Future<List<Lesson>> getRecentLessons({int limit = 10}) async => const [];

  @override
  Future<Lesson?> getLesson(String id) async => null;

  @override
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode}) async => lesson;

  @override
  Future<Lesson> updateLesson(Lesson lesson) async => lesson;

  @override
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status) async =>
      lesson.copyWith(status: status);

  @override
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  }) async => lesson;

  @override
  Future<CancellationPolicyHint> getCancellationPolicy(String lessonId) async =>
      const CancellationPolicyHint(
        deadlineHours: 24,
        deadlineAt: null,
        isLateNow: false,
        enforced: false,
      );

  @override
  Future<void> deleteLesson(String id) async {}

  @override
  Future<void> archiveLesson(String id) async {}

  @override
  Future<void> unarchiveLesson(String id) async {}

  @override
  Future<void> cancelLesson(String id) async {}
}

class _StubRequestRepository implements UnifiedLessonRequestRepository {
  @override
  Future<List<RequestEvent>> getEventsByRequestId(String requestId) async =>
      const [];
  @override
  Future<RequestEvent> addEvent(RequestEvent event) async => event;
  @override
  Future<UnifiedLessonRequest> create(UnifiedLessonRequest request) async =>
      request;
  @override
  Future<UnifiedLessonRequest?> getById(String id) async => null;
  @override
  Future<List<UnifiedLessonRequest>> getByTeacherId(String teacherId) async =>
      const [];
  @override
  Future<List<UnifiedLessonRequest>> getByStudentId(String studentId) async =>
      const [];
  @override
  Future<List<UnifiedLessonRequest>> getPendingByTeacherId(
    String teacherId,
  ) async => const [];
  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async =>
      request;
  @override
  Future<UnifiedLessonRequest> approve(String id) async =>
      throw UnimplementedError();
  @override
  Future<UnifiedLessonRequest> withdrawApproval(String id) async =>
      throw UnimplementedError();
  @override
  Future<UnifiedLessonRequest> reject(String id, {String? reason}) async =>
      throw UnimplementedError();
  @override
  Future<UnifiedLessonRequest> proposeAlternatives(
    String id, {
    required List<TimeSlotOption> slots,
    String? message,
  }) async => throw UnimplementedError();
  @override
  Future<UnifiedLessonRequest> acceptAlternative(
    String id, {
    required int selectedSlotIndex,
    String? message,
  }) async => throw UnimplementedError();
  @override
  Future<UnifiedLessonRequest> counterPropose(
    String id, {
    required TimeSlotOption slot,
    String? message,
  }) async => throw UnimplementedError();
}

class _StubSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Subscription>> getByStudentId(String studentId) async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Override> _commonOverrides() => [
  bulkTeacherActionServiceProvider.overrideWithValue(
    BulkTeacherActionService(
      lessonRepository: _StubLessonRepository(),
      requestRepository: _StubRequestRepository(),
      subscriptionRepository: _StubSubscriptionRepository(),
    ),
  ),
  currentUserIdProvider.overrideWithValue('teacher_1'),
];

void main() {
  testWidgets('BulkMessageSheet 은 키보드 인셋·DraggableSheet 에서도 크래시 없이 렌더된다', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _commonOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder:
                (ctx) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => BulkMessageSheet.show(
                            ctx,
                            studentIds: const ['s1', 's2', 's3'],
                          ),
                      child: const Text('open'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('일괄 메시지 보내기'), findsOneWidget);
    expect(find.text('3명에게 알림으로 전송됩니다'), findsOneWidget);
    expect(find.text('메시지 보내기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BulkMessageSheet 의 보내기 버튼은 빈 입력에서 비활성화', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _commonOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder:
                (ctx) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed:
                          () => BulkMessageSheet.show(
                            ctx,
                            studentIds: const ['s1'],
                          ),
                      child: const Text('open'),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final sendBtn = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('메시지 보내기'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(sendBtn.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}
