import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_form/manual_lesson_subscription_section.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _studentId = 'st1';

Subscription _sub({required String id, String? instrument}) => Subscription(
  id: id,
  studentId: _studentId,
  membershipId: 'm_$id',
  instrument: instrument,
  type: SubscriptionType.package,
  totalLessons: 8,
  usedLessons: 2,
  amount: 100000,
  status: SubscriptionStatus.active,
  createdAt: DateTime(2026, 1, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Subscription> actives,
  Subscription? selected,
  VoidCallback? onPick,
  VoidCallback? onIssue,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeStudentSubscriptionsProvider(
          _studentId,
        ).overrideWith((ref) async => actives),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ManualLessonSubscriptionSection(
            studentId: _studentId,
            studentInstrument: '바이올린',
            selectedSubscription: selected,
            onPickRequested: onPick ?? () {},
            onIssueRequested: onIssue,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('0개: 수강권 없음 배너 + 학생 악기 칩', (tester) async {
    await _pump(tester, actives: []);

    expect(tester.takeException(), isNull);
    // 학생 악기 칩
    expect(
      find.text(AppStrings.manualLessonInstrumentFromStudent('바이올린')),
      findsOneWidget,
    );
    // 선택 유도 배너는 없다
    expect(
      find.text(AppStrings.manualLessonSelectSubscriptionPrompt(2)),
      findsNothing,
    );
  });

  testWidgets('1개: 자동 귀속 → 수강권 악기 상속 칩 (학생값 무시)', (tester) async {
    await _pump(tester, actives: [_sub(id: 's1', instrument: '피아노')]);

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.manualLessonInstrumentInherited('피아노')),
      findsOneWidget,
    );
    // 변경 버튼은 단일이므로 없다
    expect(find.text(AppStrings.manualLessonChangeSubscription), findsNothing);
  });

  testWidgets('2+개 미선택: 선택 유도 배너 노출', (tester) async {
    await _pump(
      tester,
      actives: [
        _sub(id: 's1', instrument: '피아노'),
        _sub(id: 's2', instrument: '바이올린'),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.manualLessonSelectSubscriptionPrompt(2)),
      findsOneWidget,
    );
  });

  testWidgets('2+개 미선택: 배너 탭 시 onPickRequested 호출', (tester) async {
    var picked = false;
    await _pump(
      tester,
      actives: [
        _sub(id: 's1', instrument: '피아노'),
        _sub(id: 's2', instrument: '바이올린'),
      ],
      onPick: () => picked = true,
    );

    await tester.tap(
      find.text(AppStrings.manualLessonSelectSubscriptionPrompt(2)),
    );
    await tester.pumpAndSettle();

    expect(picked, isTrue);
  });

  testWidgets('2+개 선택됨: 상속 악기 칩 + 변경 버튼', (tester) async {
    final selected = _sub(id: 's2', instrument: '첼로');
    await _pump(
      tester,
      actives: [_sub(id: 's1', instrument: '피아노'), selected],
      selected: selected,
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.manualLessonInstrumentInherited('첼로')),
      findsOneWidget,
    );
    expect(
      find.text(AppStrings.manualLessonChangeSubscription),
      findsOneWidget,
    );
  });

  testWidgets('S5 — 0개 + 콜백 제공: [정식 수강권 먼저 발급] 버튼 노출 + 탭 (spec §2.6.1)', (
    tester,
  ) async {
    var issueRequested = false;
    await _pump(tester, actives: [], onIssue: () => issueRequested = true);

    expect(tester.takeException(), isNull);
    final button = find.text(AppStrings.manualLessonIssueFirstButton);
    expect(button, findsOneWidget);

    await tester.tap(button);
    expect(issueRequested, isTrue);
  });

  testWidgets('S1 — 수강권 있으면 발급 버튼 숨김 (콜백 있어도)', (tester) async {
    await _pump(
      tester,
      actives: [_sub(id: 's1', instrument: '피아노')],
      onIssue: () {},
    );

    expect(find.text(AppStrings.manualLessonIssueFirstButton), findsNothing);
  });

  testWidgets('S5 — 콜백 미제공(레거시 호출부)이면 버튼 없음', (tester) async {
    await _pump(tester, actives: []);

    expect(find.text(AppStrings.manualLessonIssueFirstButton), findsNothing);
  });
}
