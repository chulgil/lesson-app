import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/routes/subscription_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/auth/presentation/providers/user_role_provider.dart';
import 'package:lessonaza/features/lessons/data/repositories/mock_lesson_repository.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart'
    show lessonRepositoryProvider;
import 'package:lessonaza/features/relationship/data/repositories/mock_teacher_student_relation_repository.dart';
import 'package:lessonaza/features/relationship/presentation/providers/relationship_providers.dart';
import 'package:lessonaza/features/students/domain/entities/class_membership.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_class.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/lesson_class_providers.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/data/repositories/proposal_draft_storage.dart';
import 'package:lessonaza/features/subscription/presentation/providers/proposal_draft_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_issue_flow_provider.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

/// §2.6.3 known edge ① — preview lesson orphan cleanup.
///
/// The add-lesson renewal flow saves a preview lesson, then pushReplacement's
/// into this screen; the caller is gone, so THIS screen owns the preview until
/// a subscription is issued. Leaving without issuing must delete the preview
/// (no proposal was ever created, so `_cancel_preview_lessons` never covers
/// this path on the BE).
class _NoopDraftStorage extends ProposalDraftStorage {
  @override
  Future<ProposalDraftLoadResult> load(String userId, String studentId) async =>
      const ProposalDraftLoadResult(draft: null);

  @override
  Future<void> save({
    required String userId,
    required String studentId,
    required String? templateId,
    required int amount,
    required int totalLessons,
    required int validityDays,
    required String? membershipId,
  }) async {}

  @override
  Future<void> delete(String userId, String studentId) async {}
}

class _SpyLessonRepository extends MockLessonRepository {
  final List<String> deletedIds = [];

  @override
  Future<void> deleteLesson(String id) async {
    deletedIds.add(id);
  }
}

Student _student() => Student(
  id: 'student-1',
  name: 'Test Student',
  instrument: 'piano',
  createdAt: DateTime(2026, 1, 1),
);

ClassMembership _membership() => ClassMembership(
  id: 'membership-1',
  lessonClassId: 'class-1',
  studentId: 'student-1',
  instrument: 'piano',
  status: MembershipStatus.active,
  monthlyFee: 100000,
  createdAt: DateTime(2026, 1, 1),
);

LessonClass _lessonClass() => LessonClass(
  id: 'class-1',
  teacherId: 'teacher-1',
  name: 'Private',
  type: LessonClassType.private,
  paymentType: PaymentType.parent,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pumpBounded(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late _SpyLessonRepository lessonRepo;

  List<Override> overrides() => [
    currentUserRoleProvider.overrideWithValue(UserRole.teacher),
    lessonRepositoryProvider.overrideWithValue(lessonRepo),
    subscriptionRepositoryProvider.overrideWithValue(
      MockSubscriptionRepository(),
    ),
    proposalDraftStorageProvider.overrideWithValue(_NoopDraftStorage()),
    teacherStudentRelationRepositoryProvider.overrideWithValue(
      MockTeacherStudentRelationRepository(),
    ),
    subscriptionIssueStudentProvider(
      'student-1',
    ).overrideWith((ref) async => _student()),
    subscriptionIssueMembershipsProvider(
      'student-1',
    ).overrideWith((ref) async => [_membership()]),
    lessonClassProvider('class-1').overrideWith((ref) async => _lessonClass()),
  ];

  Future<GoRouter> pumpIssueRoute(
    WidgetTester tester, {
    required String location,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        ...subscriptionRoutes,
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    router.push(location);
    await _pumpBounded(tester);
    return router;
  }

  setUp(() {
    lessonRepo = _SpyLessonRepository();
  });

  testWidgets('라우트 쿼리 previewLessonId 가 화면까지 배선된다', (tester) async {
    await pumpIssueRoute(
      tester,
      location: '/subscriptions/issue?studentId=student-1&previewLessonId=L1',
    );

    final screen = tester.widget<IssueSubscriptionScreen>(
      find.byType(IssueSubscriptionScreen),
    );
    expect(screen.previewLessonId, 'L1');
  });

  testWidgets('발급 없이 이탈: preview 레슨 삭제 (고아 정리)', (tester) async {
    final router = await pumpIssueRoute(
      tester,
      location: '/subscriptions/issue?studentId=student-1&previewLessonId=L1',
    );

    router.pop();
    await _pumpBounded(tester);

    expect(tester.takeException(), isNull);
    expect(lessonRepo.deletedIds, ['L1']);
  });

  testWidgets('previewLessonId 없는 일반 진입: 이탈해도 삭제 없음 (회귀)', (tester) async {
    final router = await pumpIssueRoute(
      tester,
      location: '/subscriptions/issue?studentId=student-1',
    );

    router.pop();
    await _pumpBounded(tester);

    expect(lessonRepo.deletedIds, isEmpty);
  });

  testWidgets('발급 성공 후 복귀: preview 는 발급 라이프사이클로 이관, 삭제 없음', (tester) async {
    final router = await pumpIssueRoute(
      tester,
      location:
          '/subscriptions/issue?studentId=student-1&previewLessonId=L1'
          '&returnTo=addLesson',
    );

    // Fill the required amount field and submit (issue succeeds via mocks).
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await _pumpBounded(tester, 10);
    final amountField = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.hintText == AppStrings.issueFormAmountHint,
    );
    expect(amountField, findsOneWidget);
    await tester.enterText(amountField, '100000');
    await tester.pump();

    await tester.tap(find.byType(FilledButton));
    await _pumpBounded(tester, 30);

    // returnTo=addLesson success path pops back — the pop must NOT delete.
    expect(router.state.uri.path, '/');
    expect(lessonRepo.deletedIds, isEmpty);
  });
}
