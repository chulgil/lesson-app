import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_form/makeup_credit_toggle.dart';
import 'package:lessonaza/features/subscription/subscription_facade.dart';

const _studentId = 'st1';

MakeupCredit _credit({
  required String id,
  DateTime? usedAt,
  DateTime? expiresAt,
}) => MakeupCredit(
  id: id,
  studentId: _studentId,
  teacherId: 't1',
  reason: MakeupCreditReason.manualGrant,
  createdAt: DateTime(2026, 8, 1),
  expiresAt: expiresAt ?? DateTime(2126, 1, 1),
  usedAt: usedAt,
  usedLessonId: usedAt == null ? null : 'l1',
);

Future<void> _pump(
  WidgetTester tester, {
  required List<MakeupCredit> credits,
  bool value = false,
  ValueChanged<bool>? onChanged,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        teacherMakeupCreditsProvider(
          _studentId,
        ).overrideWith((ref) async => credits),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MakeupCreditToggle(
            studentId: _studentId,
            value: value,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('크레딧 0개: 토글 미노출 (S4 조건)', (tester) async {
    await _pump(tester, credits: []);

    expect(find.text(AppStrings.makeupToggleLabel), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('사용/만료 크레딧만 있으면 미노출', (tester) async {
    await _pump(
      tester,
      credits: [
        _credit(id: 'c1', usedAt: DateTime(2026, 8, 2)),
        _credit(id: 'c2', expiresAt: DateTime(2026, 1, 1)),
      ],
    );

    expect(find.text(AppStrings.makeupToggleLabel), findsNothing);
  });

  testWidgets('가용 크레딧 보유: 토글 노출 + 기본 OFF(D3) + 잔량 표시', (tester) async {
    await _pump(tester, credits: [_credit(id: 'c1'), _credit(id: 'c2')]);

    expect(find.text(AppStrings.makeupToggleLabel), findsOneWidget);
    expect(find.text(AppStrings.makeupToggleCredits(2)), findsOneWidget);
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.value, isFalse);
  });

  testWidgets('토글 탭 → onChanged(true)', (tester) async {
    bool? changed;
    await _pump(
      tester,
      credits: [_credit(id: 'c1')],
      onChanged: (v) => changed = v,
    );

    await tester.tap(find.byType(Switch));
    expect(changed, isTrue);
  });
}
