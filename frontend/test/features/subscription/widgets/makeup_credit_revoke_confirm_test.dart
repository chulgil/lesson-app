// R4 (audit 2026-07-10) — revoking a makeup credit is destructive and must go
// through a confirmation dialog (ux-rules HARD-GATE: all destructive actions
// confirm first). Grant already confirms; revoke must match.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_makeup_credit_repository.dart';
import 'package:lessonaza/features/subscription/presentation/providers/makeup_credit_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/teacher_makeup_credit_section.dart';

Widget _scoped(Widget child) {
  return ProviderScope(
    overrides: [
      makeupCreditRepositoryProvider.overrideWithValue(
        MockMakeupCreditRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  testWidgets('회수 버튼은 확인 다이얼로그를 먼저 띄우고, 확인 전에는 회수하지 않는다', (tester) async {
    await tester.pumpWidget(
      _scoped(const TeacherMakeupCreditSection(studentId: 'mock-student-1')),
    );
    await tester.pumpAndSettle();

    final revokeButtons = find.text(AppStrings.makeupCreditRevokeButton);
    expect(revokeButtons, findsWidgets, reason: 'mock 시드에 활성 크레딧 존재');
    final beforeCount = revokeButtons.evaluate().length;

    await tester.tap(revokeButtons.first);
    await tester.pumpAndSettle();

    // Destructive HARD-GATE: a confirmation dialog must appear, and the
    // credit must still be present until confirmed.
    expect(
      find.text(AppStrings.makeupCreditRevokeConfirmTitle),
      findsOneWidget,
      reason: '회수는 destructive — 확인 다이얼로그 필수 (R4)',
    );
    expect(
      find.text(AppStrings.makeupCreditRevokeSuccess),
      findsNothing,
      reason: '확인 전에 회수가 실행되면 안 됨',
    );

    // Cancel keeps the credit.
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(
      find.text(AppStrings.makeupCreditRevokeButton).evaluate().length,
      beforeCount,
    );
  });
}
