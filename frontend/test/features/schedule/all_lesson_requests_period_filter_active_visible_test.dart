import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/providers/unified_lesson_request_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/all_lesson_requests_screen.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/request_list_item.dart';

/// P1 — 학생/교사가 AllLessonRequestsScreen 에서 기간 프리셋(1주/1달/3개월)을
/// 적용해도, 아직 진행 중(active/non-terminal)인 요청은 생성일이 창 밖이어도
/// 계속 보여야 한다. 반면 종료(terminal) 요청은 여전히 창 밖이면 숨겨진다.
/// (all_lesson_requests_screen.dart 의 기간 chip 이 만드는 hidden-pending trap
/// 회귀 — request_filter.dart 의 date-range 예외 처리로 수정.)
void main() {
  testWidgets('1주 필터 적용 후에도 오래된 active 요청은 남고 terminal 요청은 사라짐', (
    tester,
  ) async {
    final now = DateTime.now();
    final oldActive = UnifiedLessonRequest(
      id: 'r_active_old',
      studentId: 's1',
      teacherId: 't1',
      type: LessonRequestType.regular,
      instrument: '바이올린',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      status: UnifiedRequestStatus.pending,
      createdAt: now.subtract(const Duration(days: 40)),
    );
    final oldTerminal = UnifiedLessonRequest(
      id: 'r_terminal_old',
      studentId: 's2',
      teacherId: 't1',
      type: LessonRequestType.regular,
      instrument: '피아노',
      goal: UnifiedLessonGoal.hobby,
      experience: UnifiedExperienceLevel.beginner,
      status: UnifiedRequestStatus.cancelled,
      createdAt: now.subtract(const Duration(days: 40)),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherUnifiedRequestsProvider(
            't1',
          ).overrideWith((ref) async => [oldActive, oldTerminal]),
          studentNameMapProvider.overrideWithValue(const {}),
          teacherNameMapProvider.overrideWithValue(const {}),
          academyNameMapProvider.overrideWithValue(const {}),
        ],
        child: const MaterialApp(
          home: AllLessonRequestsScreen(subjectId: 't1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both requests visible before any period preset is applied.
    expect(find.byType(RequestListItem), findsNWidgets(2));

    // Apply the "1주" period preset.
    await tester.tap(find.text(AppStrings.periodOneWeek));
    await tester.pumpAndSettle();

    // Only the active request remains — the terminal one drops as expected,
    // but the active one must not silently vanish just because it is old.
    expect(find.byType(RequestListItem), findsOneWidget);
    expect(find.textContaining('바이올린'), findsWidgets);
    expect(find.textContaining('피아노'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
