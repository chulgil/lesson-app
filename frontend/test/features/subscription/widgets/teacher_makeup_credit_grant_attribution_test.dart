// Manual makeup-credit grant — subscription attribution (spec §4.4).
//
// The FE now resolves which of the student's active subscriptions the grant
// should be attributed to before confirming: 0 actives → unchanged (no
// attribution), 1 → auto-attach silently, 2+ → offer a picker with an
// explicit "귀속 없음" choice (source_subscription_id stays nullable).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/teacher_makeup_credit_section.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _studentId = 'mock-student-1';

/// Spy repo — records the `sourceSubscriptionId` passed to grantCredit() so
/// tests can assert on it without depending on remote/HTTP wiring.
class _SpyMakeupCreditRepository extends MockMakeupCreditRepository {
  final List<String?> grantedSourceSubscriptionIds = [];

  @override
  Future<MakeupCredit> grantCredit({
    required String studentId,
    String? sourceSubscriptionId,
    String? reasonNote,
  }) async {
    grantedSourceSubscriptionIds.add(sourceSubscriptionId);
    return super.grantCredit(
      studentId: studentId,
      sourceSubscriptionId: sourceSubscriptionId,
      reasonNote: reasonNote,
    );
  }
}

Subscription _sub({required String id, int totalLessons = 8}) => Subscription(
  id: id,
  studentId: _studentId,
  membershipId: 'm_$id',
  type: SubscriptionType.package,
  totalLessons: totalLessons,
  usedLessons: 2,
  amount: 100000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

Future<_SpyMakeupCreditRepository> _pumpAndOpenConfirm(
  WidgetTester tester, {
  required List<Subscription> actives,
}) async {
  final repo = _SpyMakeupCreditRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        makeupCreditRepositoryProvider.overrideWithValue(repo),
        activeStudentSubscriptionsProvider(
          _studentId,
        ).overrideWith((ref) async => actives),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: const TeacherMakeupCreditSection(studentId: _studentId),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text(AppStrings.makeupCreditGrantButton).first);
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('0개: 귀속 없이 지급 — 오늘까지의 동작과 동일', (tester) async {
    final repo = await _pumpAndOpenConfirm(tester, actives: []);

    // No attribution line, no picker sheet — straight to today's dialog.
    expect(find.text(AppStrings.makeupCreditGrantConfirmTitle), findsOneWidget);
    expect(find.textContaining('귀속:'), findsNothing);

    await tester.tap(find.text(AppStrings.makeupCreditGrantButton).last);
    await tester.pumpAndSettle();

    expect(repo.grantedSourceSubscriptionIds, [null]);
  });

  testWidgets('1개: 자동 귀속 + 확인 다이얼로그에 읽기전용 귀속 라인 노출', (tester) async {
    final sub = _sub(id: 'sub-1');
    final repo = await _pumpAndOpenConfirm(tester, actives: [sub]);

    expect(find.text(AppStrings.makeupCreditGrantConfirmTitle), findsOneWidget);
    expect(
      find.text(AppStrings.makeupCreditGrantAttributionLine(sub.typeLabel)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.makeupCreditGrantButton).last);
    await tester.pumpAndSettle();

    expect(repo.grantedSourceSubscriptionIds, [sub.id]);
  });

  testWidgets('2개+: 선택 시트 노출 + 고른 수강권 id 로 지급', (tester) async {
    final sub1 = _sub(id: 'sub-1', totalLessons: 8);
    final sub2 = _sub(id: 'sub-2', totalLessons: 10);
    final repo = await _pumpAndOpenConfirm(tester, actives: [sub1, sub2]);

    // The picker sheet auto-opens (2+ actives) before the confirm dialog.
    expect(find.text(AppStrings.manualLessonPickerTitle), findsOneWidget);
    expect(
      find.text(AppStrings.makeupCreditGrantNoAttributionOption),
      findsOneWidget,
    );

    await tester.tap(find.text(sub2.typeLabel).first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.makeupCreditGrantConfirmTitle), findsOneWidget);
    expect(
      find.text(AppStrings.makeupCreditGrantAttributionLine(sub2.typeLabel)),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.makeupCreditGrantButton).last);
    await tester.pumpAndSettle();

    expect(repo.grantedSourceSubscriptionIds, [sub2.id]);
  });

  testWidgets('2개+: "귀속 없음" 선택 시 null 로 지급', (tester) async {
    final sub1 = _sub(id: 'sub-1');
    final sub2 = _sub(id: 'sub-2');
    final repo = await _pumpAndOpenConfirm(tester, actives: [sub1, sub2]);

    expect(find.text(AppStrings.manualLessonPickerTitle), findsOneWidget);

    await tester.tap(
      find.text(AppStrings.makeupCreditGrantNoAttributionOption),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.makeupCreditGrantConfirmTitle), findsOneWidget);
    expect(
      find.text(
        AppStrings.makeupCreditGrantAttributionLine(
          AppStrings.makeupCreditGrantNoAttributionOption,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.makeupCreditGrantButton).last);
    await tester.pumpAndSettle();

    expect(repo.grantedSourceSubscriptionIds, [null]);
  });
}
