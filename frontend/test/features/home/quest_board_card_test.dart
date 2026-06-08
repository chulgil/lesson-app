// Regression tests for QuestBoardCard board-dismissal SSOT. (#4 / #482)
//
// The progress gauge (profileCompletionPercent) sums the 10 mandatory quests
// to 100%. Phone verification is the optional Phase C reward quest (weight 0,
// see phone_verification_policy.md §2). A previous fix added phone verification
// to the board's `allDone` condition but not to the percent, so the gauge could
// read 100% while the board lingered. These tests pin the two to the same SSOT:
// when all 10 mandatory quests are done, the gauge is 100 AND the board hides,
// regardless of phone verification.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/providers/teacher_profile_completion_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/quest_board_card.dart';
import 'package:lessonaza/features/profile/presentation/providers/quest_first_shown_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

/// Hive 미초기화 환경에서 questFirstShownProvider 가 실패하지 않도록 fake.
/// 테스트마다 `null` (미진입) 반환 — reveal 윈도우 비활성.
class _FakeQuestFirstShown extends QuestFirstShown {
  @override
  Future<DateTime?> build() async => null;

  @override
  Future<void> markShown() async {}
}

/// Overrides that complete all 10 mandatory quests. Phone verification is
/// controlled separately so each test can toggle just that flag.
List<Override> _allMandatoryDone({required bool phoneVerified}) => [
  hasAvailableSlotsProvider.overrideWithValue(true),
  hasProfileImageProvider.overrideWithValue(true),
  hasIntroductionProvider.overrideWithValue(true),
  hasPriceTableProvider.overrideWithValue(true),
  hasBankAccountProvider.overrideWithValue(true),
  hasIssuedSubscriptionProvider.overrideWithValue(true),
  hasWrittenLessonNoteProvider.overrideWithValue(true),
  hasAssignedPracticeProvider.overrideWithValue(true),
  homeHasCompletedLessonProvider.overrideWithValue(true),
  homeTeacherPhoneVerifiedProvider.overrideWithValue(phoneVerified),
  homeStudentsProvider.overrideWith(
    (ref) async => [
      Student(
        id: 's1',
        name: '학생',
        instrument: '피아노',
        createdAt: DateTime.utc(2026, 5, 1),
      ),
    ],
  ),
  questFirstShownProvider.overrideWith(_FakeQuestFirstShown.new),
];

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light,
        // QuestBoardCard 는 production 에서 SingleChildScrollView 내 사용.
        // 단독 렌더 시 3-group + items 가 viewport 보다 길어 overflow 발생 가능.
        home: const Scaffold(
          body: SingleChildScrollView(child: QuestBoardCard()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'gauge reaches 100 with all 10 mandatory quests done (phone unverified)',
    () async {
      final container = ProviderContainer(
        overrides: _allMandatoryDone(phoneVerified: false),
      );
      addTearDown(container.dispose);
      // Keep derived inputs alive.
      container.listen(profileCompletionPercentProvider, (_, __) {});
      await container.read(homeStudentsProvider.future);

      expect(container.read(profileCompletionPercentProvider), 100);
    },
  );

  testWidgets(
    'board hides at 100% even when phone verification is incomplete',
    (tester) async {
      await _pump(tester, _allMandatoryDone(phoneVerified: false));

      expect(tester.takeException(), isNull);
      // Board is collapsed — no header, no quest rows.
      expect(find.text(AppStrings.questBoardTitle), findsNothing);
      expect(find.text(AppStrings.questTitleSlots), findsNothing);
    },
  );

  testWidgets('board is still shown while a mandatory quest is incomplete', (
    tester,
  ) async {
    final overrides = _allMandatoryDone(phoneVerified: true);
    // Knock out one mandatory quest.
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questBoardTitle), findsOneWidget);
  });

  // ── §13 3-group + lock 매트릭스 신규 케이스 (Job 4) ──

  testWidgets('3-group 헤더가 모두 표시됨 — profile / operation / bonus', (
    tester,
  ) async {
    final overrides = _allMandatoryDone(phoneVerified: false);
    // 각 그룹마다 1개씩 미완료 → 모든 그룹 헤더가 표시되어야 함.
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false); // Q1
    overrides[5] = hasIssuedSubscriptionProvider.overrideWithValue(false); // Q7

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questGroupProfileLabel), findsOneWidget);
    expect(find.text(AppStrings.questGroupOperationLabel), findsOneWidget);
    expect(find.text(AppStrings.questGroupBonusLabel), findsOneWidget);
  });

  testWidgets('선택 보너스 그룹에 [선택] 태그 표시', (tester) async {
    final overrides = _allMandatoryDone(phoneVerified: false);
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questGroupBonusOptionalTag), findsOneWidget);
  });

  testWidgets('학생 없음 — Q7~Q10 lock hint 노출 (slotsBlocker 패턴 제거 확인)', (
    tester,
  ) async {
    final overrides = _allMandatoryDone(phoneVerified: true);
    // hasSlots 는 true, 다른 mandatory 만 한 개 미완료 (학생 없음).
    overrides[5] = hasIssuedSubscriptionProvider.overrideWithValue(false);
    overrides[10] = homeStudentsProvider.overrideWith((ref) async => []);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    // Lock hint 가 적어도 1번 등장 (Q7~Q10 중 하나는 reward 영역에 표시).
    expect(find.text(AppStrings.questLockedStudentRequiredHint), findsWidgets);
    // 구 slotsBlocker 의 hint 가 더 이상 나타나지 않음.
    expect(find.text(AppStrings.firstAvailabilityLockedHint), findsNothing);
  });

  testWidgets('Q1 카드만 미완료 — slotsBlocker 잠금 없음 (모든 항목 진입 가능)', (tester) async {
    // hasSlots = false 단 1개 (구 버전에선 모든 카드 lock 였음).
    final overrides = _allMandatoryDone(phoneVerified: true);
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    // 구 slotsBlocker 잠금 hint 가 없음.
    expect(find.text(AppStrings.firstAvailabilityLockedHint), findsNothing);
  });

  // ── §8.2 자동 완료 즉시 소거 (Job 5) ──

  testWidgets('일반 진입 — 완료된 quest 는 build 시점에 filter out (즉시 소거)', (
    tester,
  ) async {
    // hasSlots 만 false → Q1 visible. Q2~Q10 완료 → 화면에서 사라짐.
    final overrides = _allMandatoryDone(phoneVerified: false);
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    // Q1 (미완료) 만 visible.
    expect(find.text(AppStrings.questTitleSlots), findsOneWidget);
    // Q2 (완료) 는 화면에서 사라짐.
    expect(find.text(AppStrings.questTitlePhoto), findsNothing);
    expect(find.text(AppStrings.questTitleStudent), findsNothing);
    // 그룹 헤더의 카운터는 전체 (4/5) 유지 — profile 그룹: Q2~Q5 완료.
    expect(find.textContaining('(4/5)'), findsOneWidget);
  });

  testWidgets('가입 직후 첫 도착 윈도우 — 완료 quest 도 표시 (Reveal 윈도우)', (tester) async {
    final overrides = _allMandatoryDone(phoneVerified: false);
    overrides[0] = hasAvailableSlotsProvider.overrideWithValue(false);
    // 첫 도착 윈도우 시뮬레이션 — markShown 직후 상태.
    overrides[overrides.length - 1] = questFirstShownProvider.overrideWith(
      () => _RevealingQuestFirstShown(DateTime.now()),
    );

    await _pump(tester, overrides);

    expect(tester.takeException(), isNull);
    // Reveal 윈도우 → 완료된 Q2 도 화면에 나타남 (2초 표시).
    expect(find.text(AppStrings.questTitleSlots), findsOneWidget);
    expect(find.text(AppStrings.questTitlePhoto), findsOneWidget);
  });
}

/// 가입 직후 첫 도착 윈도우 simulation — markShown 된 상태로 시작.
class _RevealingQuestFirstShown extends QuestFirstShown {
  _RevealingQuestFirstShown(this._shownAt);
  final DateTime _shownAt;

  @override
  Future<DateTime?> build() async => _shownAt;

  @override
  Future<void> markShown() async {}
}
