import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/schedule/presentation/providers/week_lessons_provider.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/schedule_change_slot_bottom_sheet.dart';

/// Layout smoke test for ScheduleChangeSlotBottomSheet (P0-1 Phase B(b)).
///
/// 회귀 가드: BottomSheet 가 sheet 상한 (maxHeight=92%) 안에서
/// Header + ChapterGuideBox + CurrentScheduleInfo + WeekNav + Grid + BottomSection
/// 을 모두 렌더하면서 BoxConstraints 크래시 (Infinity 폭/높이) 를 일으키지 않는다.
///
/// 부모 BottomSheet 흐름과 통일된 후 풀스크린에서 sheet 상한으로 바뀌었기 때문에
/// Flexible(grid) 가 0~∞ 제약을 받을 때 안전한지 확인 필요.
void main() {
  testWidgets(
    'ScheduleChangeSlotBottomSheet (single) — sheet 상한 안에서 BoxConstraints 크래시 없이 렌더',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weekLessonsWithPreviewProvider.overrideWith(
              (ref, params) async => <Lesson>[],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed:
                            () => showScheduleChangeSlotBottomSheet(
                              context,
                              params: const ScheduleChangeSlotParams(
                                teacherId: 'teacher_1',
                                studentId: 'student_1',
                                durationMinutes: 60,
                                currentScheduleLabel: '월 14:00',
                                isBulkChange: false,
                              ),
                            ),
                        child: const Text('open'),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'sheet 상한 안에서 Flexible+Column+Grid 가 충돌 없이 렌더되어야 한다',
      );
      // 핵심 단면 확인 — 헤더 + 챕터 가이드 + 현재 일정 라벨 + 제안 버튼 모두 살아있음.
      expect(find.text('월 14:00'), findsOneWidget);
    },
  );

  testWidgets(
    'ScheduleChangeSlotBottomSheet (bulk) — bulk 배너 + 매주 라벨 시그니처 유지',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weekLessonsWithPreviewProvider.overrideWith(
              (ref, params) async => <Lesson>[],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder:
                  (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed:
                            () => showScheduleChangeSlotBottomSheet(
                              context,
                              params: const ScheduleChangeSlotParams(
                                teacherId: 'teacher_1',
                                studentId: 'student_1',
                                durationMinutes: 60,
                                currentScheduleLabel: '매주 월 14:00',
                                isBulkChange: true,
                              ),
                            ),
                        child: const Text('open'),
                      ),
                    ),
                  ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'bulk 모드에서도 BoxConstraints 크래시 없이 렌더되어야 한다',
      );
      expect(find.text('매주 월 14:00'), findsOneWidget);
    },
  );
}
