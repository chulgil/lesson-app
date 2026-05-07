import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/lessons/domain/entities/entities.dart';
import 'package:lessonaza/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:lessonaza/features/notifications/domain/entities/notification.dart';
import 'package:lessonaza/features/notifications/domain/services/notification_service.dart';
import 'package:lessonaza/features/schedule/domain/entities/request_event.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/students/domain/services/bulk_teacher_action_service.dart';
import 'package:lessonaza/features/students/presentation/providers/bulk_teacher_action_providers.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:lessonaza/features/students/presentation/screens/bulk_cancel_screen.dart';
import 'package:lessonaza/features/students/presentation/widgets/bulk_message_sheet.dart';

/// §7.119 layout smoke tests — BulkCancelScreen + BulkMessageSheet.
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
  Future<Lesson> createLesson(Lesson lesson) async => lesson;

  @override
  Future<Lesson> updateLesson(Lesson lesson) async => lesson;

  @override
  Future<void> deleteLesson(String id) async {}

  @override
  Future<void> cancelLesson(String id) async {}
}

class _StubNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showNotification(AppNotification n) async {}

  @override
  Future<void> scheduleNotification(AppNotification n) async {}

  @override
  Future<void> cancelNotification(String id) async {}

  @override
  Future<void> cancelAllNotifications() async {}

  @override
  Stream<AppNotification> get onNotificationTapped => const Stream.empty();
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
  Future<List<Subscription>> getByStudentId(String studentId) async =>
      const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Override> _commonOverrides() => [
  bulkTeacherActionServiceProvider.overrideWithValue(
    BulkTeacherActionService(
      lessonRepository: _StubLessonRepository(),
      notificationService: _StubNotificationService(),
      requestRepository: _StubRequestRepository(),
      subscriptionRepository: _StubSubscriptionRepository(),
    ),
  ),
  currentUserIdProvider.overrideWithValue('teacher_1'),
];

void main() {
  testWidgets('BulkCancelScreen 은 빈 학생 리스트에서도 크래시 없이 렌더된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _commonOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BulkCancelScreen(studentIds: ['s1', 's2']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('휴강 공지'), findsOneWidget);
    expect(find.text('2명 선택됨'), findsOneWidget);
    expect(find.text('휴강 날짜 선택'), findsOneWidget);
    expect(find.text('휴강할 날짜를 먼저 선택하세요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BulkCancelScreen 의 발송 버튼은 초기 상태에서 비활성화된다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _commonOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const BulkCancelScreen(studentIds: ['s1']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 0건 휴강 공지 발송 버튼은 disabled
    final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

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
