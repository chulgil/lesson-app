import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_with_freeze_calculator.dart';
import 'package:lessonaza/features/gamification/presentation/providers/effective_streak_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/practice_start_section.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_repertoire_crud_provider.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/presentation/providers/student_crud_provider.dart';

/// G3 PR-C2 회귀 — PracticeStartSection 의 표시 streak 은 SSOT 에서 온다.
/// 과거 UTC `heatmap.streakDays()` 가 아님을 증명: 빈 heatmap(= heatmap 스트릭 0)
/// 이어도 provider 값(5)을 표시.
///
/// #1214 Phase 3 — 표시 SSOT 가 practiceStreakProvider → effectiveStreakProvider
/// 로 이동 (freeze 브리지 포함). 계약(heatmap 아님)은 그대로.
void main() {
  testWidgets(
    'home card streak comes from practiceStreakProvider (SSOT), not heatmap',
    (tester) async {
      const studentId = 's1';
      final student = Student(
        id: studentId,
        name: '민지',
        instrument: 'piano',
        nickname: '민지짱',
        createdAt: DateTime(2026, 1, 1),
      );
      // 빈 heatmap → 과거 코드의 heatmap.streakDays(today) 는 0. provider 는 5.
      final emptyHeatmap = GrowthHeatmap(studentId: studentId, days: const {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentProvider(studentId).overrideWith((ref) async => student),
            growthHeatmapProvider(
              studentId,
            ).overrideWith((ref) async => emptyHeatmap),
            effectiveStreakProvider(studentId).overrideWith(
              (ref) async => const StreakWithFreezeResult(
                effectiveCurrentStreak: 5,
                freezeShouldApply: false,
                absenceDate: null,
                streakBroken: false,
                examModeDormant: false,
              ),
            ),
            studentRepertoiresProvider(
              studentId,
            ).overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PracticeStartSection(studentId: studentId)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SSOT(5), heatmap 함의(0) 아님.
      expect(find.text('5일'), findsOneWidget);
      expect(find.text('0일'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
