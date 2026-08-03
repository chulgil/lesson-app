import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/unified_subscription_sheet.dart';

/// §2.7 (AC-5.1) — 미가입(수기) 학생은 제안을 받을 수 없다:
/// 발급 시트에서 제안 버튼·캡션 숨김, 즉시 발급만 노출.
const _teacherId = 'teacher_1';
const _studentId = 'stu_1';

Student _student({DateTime? connectedAt}) => Student(
  id: _studentId,
  name: '수기 학생',
  instrument: '바이올린',
  level: StudentLevel.beginner,
  status: StudentStatus.trial,
  monthlyFee: 0,
  connectedAt: connectedAt,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  Future<void> pumpSheet(WidgetTester tester, {DateTime? connectedAt}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTeacherTemplatesProvider(
            _teacherId,
          ).overrideWith((ref) async => const <SubscriptionTemplate>[]),
          studentsProvider.overrideWith(
            (ref) async => [_student(connectedAt: connectedAt)],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: UnifiedSubscriptionSheet(
              teacherId: _teacherId,
              studentIds: const [_studentId],
              studentName: '수기 학생',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('미가입 학생(connectedAt null): 제안 버튼·캡션 숨김, 즉시 발급만', (tester) async {
    await pumpSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.proposalSend), findsNothing);
    expect(
      find.text(AppStrings.unifiedSubscriptionProposalCaption),
      findsNothing,
    );
    expect(
      find.text(AppStrings.unifiedSubscriptionDirectIssueButton),
      findsOneWidget,
    );
  });

  testWidgets('가입 학생(connectedAt 존재): 제안 버튼 유지 (회귀)', (tester) async {
    await pumpSheet(tester, connectedAt: DateTime(2026, 6, 1));

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.proposalSend), findsOneWidget);
    expect(
      find.text(AppStrings.unifiedSubscriptionProposalCaption),
      findsOneWidget,
    );
  });
}
