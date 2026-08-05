import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription_template.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_template_providers.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/unified_subscription_sheet.dart';

/// 직접 발급 x 다중 템플릿 가드 — 발급 화면은 템플릿 1개만 받으므로
/// 2+ 선택 상태에서 바로 발급을 누르면 나머지가 무통보 폐기되던 문제.
/// 가드: 안내 스낵바 + 진행 중단 (silent drop 제거).
const _teacherId = 'teacher_1';
const _studentId = 'stu_1';
const _issueScreenMarker = 'issue-screen-marker';

SubscriptionTemplate _template(String id, String name) => SubscriptionTemplate(
  id: id,
  ownerId: _teacherId,
  ownerType: SubscriptionTemplateOwnerType.teacher,
  name: name,
  totalLessons: 10,
  lessonDurationMinutes: 60,
  validityDays: 90,
  price: 500000,
  createdAt: DateTime.utc(2026, 8, 1),
);

Student _student() => Student(
  id: _studentId,
  name: '수기 학생',
  instrument: '바이올린',
  level: StudentLevel.beginner,
  status: StudentStatus.trial,
  monthlyFee: 0,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync().path);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.push('/sheet'),
                    child: const Text('open-sheet'),
                  ),
                ),
              ),
        ),
        // The sheet pops itself before pushing the issue route, so it must sit
        // on a pushed route (mirrors the production modal) — direct embedding
        // at '/' would pop the last page off the stack.
        GoRoute(
          path: '/sheet',
          builder:
              (context, state) => Scaffold(
                body: UnifiedSubscriptionSheet(
                  teacherId: _teacherId,
                  studentIds: const [_studentId],
                  studentName: '수기 학생',
                ),
              ),
        ),
        GoRoute(
          path: AppRoutes.issueSubscription,
          builder:
              (context, state) =>
                  const Scaffold(body: Text(_issueScreenMarker)),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTeacherTemplatesProvider(_teacherId).overrideWith(
            (ref) async => [_template('t1', '10회권'), _template('t2', '20회권')],
          ),
          studentsProvider.overrideWith((ref) async => [_student()]),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open-sheet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('템플릿 2개 선택 + 바로 발급: 가드 스낵바, 진행 중단', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('10회권'));
    await tester.pump();
    await tester.tap(find.text('20회권'));
    await tester.pump();

    await tester.tap(
      find.text(AppStrings.unifiedSubscriptionDirectIssueButton),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.unifiedSubscriptionDirectIssueSingleTemplateOnly),
      // Stacked route + sheet scaffolds each render the snackbar.
      findsWidgets,
    );
    // No navigation happened — sheet is still on screen.
    expect(find.text(_issueScreenMarker), findsNothing);
    expect(
      find.text(AppStrings.unifiedSubscriptionDirectIssueButton),
      findsOneWidget,
    );
  });

  testWidgets('템플릿 1개 선택은 가드 미발동, 발급 화면 진입 (회귀)', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('10회권'));
    await tester.pump();

    await tester.tap(
      find.text(AppStrings.unifiedSubscriptionDirectIssueButton),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(AppStrings.unifiedSubscriptionDirectIssueSingleTemplateOnly),
      findsNothing,
    );
    expect(find.text(_issueScreenMarker), findsOneWidget);
  });
}
