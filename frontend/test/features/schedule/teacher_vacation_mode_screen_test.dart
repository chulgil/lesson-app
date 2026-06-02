import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/vacation_period.dart';
import 'package:lessonaza/features/schedule/domain/repositories/vacation_repository.dart';
import 'package:lessonaza/features/schedule/presentation/providers/vacation_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/teacher_vacation_mode_screen.dart';

/// Smoke test for #431 G3 휴가 모드 진입 화면 (skeleton).
///
/// 검증:
/// 1) 화면이 BoxConstraints/RenderMetaData 류 런타임 크래시 없이 렌더링
/// 2) 핵심 라벨 (제목, 시작/종료, 휴가 등록 버튼) 가 노출
/// 3) 등록 버튼은 기간 미선택 상태에서 비활성
class _StubVacationRepository implements VacationRepository {
  @override
  Future<VacationImpactPreview> previewImpact({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return VacationImpactPreview(
      startDate: startDate,
      endDate: endDate,
      impactedLessonCount: 0,
      impactedStudentCount: 0,
    );
  }

  @override
  Future<VacationPeriod> registerVacation({
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
    required VacationDisposition defaultDisposition,
    Map<String, VacationDisposition>? perStudentDisposition,
  }) async {
    return VacationPeriod(
      id: 'stub',
      teacherId: 'stub-teacher',
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      defaultDisposition: defaultDisposition,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<VacationPeriod>> listVacations({
    bool includeCancelled = false,
  }) async => [];

  @override
  Future<VacationPeriod> cancelVacation(String periodId) async {
    throw UnimplementedError();
  }
}

void main() {
  group('TeacherVacationModeScreen', () {
    testWidgets('renders skeleton without runtime exception', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vacationRepositoryProvider.overrideWithValue(
              _StubVacationRepository(),
            ),
          ],
          child: const MaterialApp(home: TeacherVacationModeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.vacationModeTitle), findsOneWidget);
      expect(find.text(AppStrings.vacationStartDateLabel), findsOneWidget);
      expect(find.text(AppStrings.vacationEndDateLabel), findsOneWidget);
      // Scroll to the submit button — disposition section pushed it offscreen.
      await tester.scrollUntilVisible(
        find.text(AppStrings.vacationRegisterButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.vacationRegisterButton), findsOneWidget);
      // Range not picked → submit must be disabled
      final submit = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(submit.onPressed, isNull);
    });

    testWidgets(
      'renders inside narrow Row/Column constraint without overflow',
      (tester) async {
        // Regression guard for layout crashes (BoxConstraints / RenderMetaData)
        // when the screen is hosted in tight layouts (split-pane / dialog).
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              vacationRepositoryProvider.overrideWithValue(
                _StubVacationRepository(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 320,
                  height: 640,
                  child: const TeacherVacationModeScreen(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
