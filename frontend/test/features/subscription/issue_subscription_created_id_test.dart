import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/domain/repositories/unified_lesson_request_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

/// Reassigns a fresh id on create (mirrors mock/remote behaviour) and records
/// the ids it hands back / expires, so a test can prove the caller links the
/// *returned* id and cleans up orphans.
class _RecordingSubscriptionRepository extends MockSubscriptionRepository {
  final List<String> createdIds = [];
  final List<String> expiredIds = [];

  @override
  Future<Subscription> create(Subscription subscription) async {
    final created = await super.create(subscription);
    createdIds.add(created.id);
    return created;
  }

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) async {
    if (status == SubscriptionStatus.expired) expiredIds.add(id);
    await super.updateStatus(id, status);
  }
}

/// Lightweight in-memory lesson-request repo — only the methods the issue flow
/// touches (`getById`, `update`) are real. Avoids the heavy mock's seed data,
/// which keeps pumpAndSettle from hanging.
class _FakeLessonRequestRepository implements UnifiedLessonRequestRepository {
  _FakeLessonRequestRepository();

  final Map<String, UnifiedLessonRequest> store = {};

  void seed(UnifiedLessonRequest request) => store[request.id] = request;

  @override
  Future<UnifiedLessonRequest?> getById(String id) async => store[id];

  @override
  Future<UnifiedLessonRequest> update(UnifiedLessonRequest request) async {
    store[request.id] = request;
    return request;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}

UnifiedLessonRequest _seedRequest(String id) => UnifiedLessonRequest(
  id: id,
  studentId: 'student-1',
  teacherId: 'teacher-1',
  type: LessonRequestType.regular,
  instrument: 'piano',
  goal: UnifiedLessonGoal.hobby,
  experience: UnifiedExperienceLevel.beginner,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pumpBatchAndIssue(
  WidgetTester tester, {
  required _RecordingSubscriptionRepository subRepo,
  required _FakeLessonRequestRepository requestRepo,
  required List<String> lessonRequestIds,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(subRepo),
        unifiedLessonRequestRepositoryProvider.overrideWithValue(requestRepo),
      ],
      child: MaterialApp(
        home: IssueSubscriptionScreen(
          // 2 students with no memberships → batch mode, no per-student
          // membership lookup blocks the form.
          studentIds: const ['student-1', 'student-2'],
          lessonRequestIds: lessonRequestIds,
        ),
      ),
    ),
  );
  // Bounded pumps everywhere — pumpAndSettle can hang on persistent indicators
  // / timers in this screen.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }

  // Realize and fill the required amount field, then submit.
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  final amountField = find.byWidgetPredicate(
    (w) =>
        w is TextField &&
        w.decoration?.hintText == AppStrings.issueFormAmountHint,
  );
  expect(amountField, findsOneWidget);
  await tester.enterText(amountField, '100000');
  await tester.pump();

  await tester.tap(find.byType(FilledButton));
  // Drain the async issue chain with bounded pumps — pumpAndSettle can hang on
  // the post-success snackbar timer.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets(
    'batch issue links the lesson request to the persisted subscription id',
    (tester) async {
      final subRepo = _RecordingSubscriptionRepository();
      final requestRepo = _FakeLessonRequestRepository()
        ..seed(_seedRequest('req-1'));

      await _pumpBatchAndIssue(
        tester,
        subRepo: subRepo,
        requestRepo: requestRepo,
        lessonRequestIds: const ['req-1'],
      );

      expect(subRepo.createdIds.length, 2);

      final linked = requestRepo.store['req-1'];
      final linkedId = linked?.proposalId;
      expect(
        linkedId,
        isNotNull,
        reason: 'lesson request must be linked to a subscription',
      );

      // The link must point at a subscription that was actually persisted (one
      // of the returned create() ids), never the discarded local UUID.
      expect(
        subRepo.createdIds,
        contains(linkedId),
        reason: 'linked id must be one of the persisted create() ids',
      );
      expect(linked?.status, UnifiedRequestStatus.subscriptionIssued);
    },
  );

  testWidgets('batch issue happy path links cleanly and orphans nothing', (
    tester,
  ) async {
    final subRepo = _RecordingSubscriptionRepository();
    final requestRepo = _FakeLessonRequestRepository();

    await _pumpBatchAndIssue(
      tester,
      subRepo: subRepo,
      requestRepo: requestRepo,
      lessonRequestIds: const [],
    );

    expect(subRepo.createdIds.length, 2);
    expect(
      subRepo.expiredIds,
      isEmpty,
      reason: 'no subscription should be deactivated on success',
    );
  });
}
