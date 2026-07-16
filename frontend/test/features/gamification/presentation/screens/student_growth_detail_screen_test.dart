import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/gamification.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/presentation/providers/gamification_provider.dart';
import 'package:lessonaza/features/gamification/presentation/providers/growth_heatmap_provider.dart';
import 'package:lessonaza/features/gamification/presentation/screens/student_growth_detail_screen.dart';

/// 메모리 stub — `getHeatmap` 만 반환.
class _StubGrowthHeatmapRepository implements GrowthHeatmapRepository {
  _StubGrowthHeatmapRepository(this._heatmap);
  final GrowthHeatmap _heatmap;

  @override
  Future<GrowthHeatmap> getHeatmap(
    String studentId, {
    int yearsBack = 1,
  }) async => _heatmap;

  @override
  Future<void> recordPractice(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  ) async {}
}

StudentGamification _makeGamification({
  required String studentId,
  List<PracticeBadge> badges = const [],
}) {
  return StudentGamification(
    studentId: studentId,
    totalPoints: 0,
    level: 1,
    levelTitle: 'Beginner',
    pointsToNextLevel: 100,
    currentLevelMinPoints: 0,
    nextLevelMinPoints: 100,
    earnedBadges: badges,
    recentHistory: const [],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required String studentId,
  GrowthHeatmap? heatmap,
  List<PracticeBadge> badges = const [],
}) async {
  final stub = _StubGrowthHeatmapRepository(
    heatmap ?? GrowthHeatmap(studentId: studentId, days: const {}),
  );
  final gamification = _makeGamification(studentId: studentId, badges: badges);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        growthHeatmapRepositoryProvider.overrideWithValue(stub),
        studentGamificationProvider(
          studentId,
        ).overrideWith((_) async => gamification),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: StudentGrowthDetailScreen(
            studentId: studentId,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StudentGrowthDetailScreen — Job 9 Task 9.1 / AC-6.4', () {
    testWidgets('widget smoke test (HARD-GATE) — render exception 0', (
      tester,
    ) async {
      await _pump(tester, studentId: 's1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('YearHeatmapGrid 노출', (tester) async {
      await _pump(tester, studentId: 's1');
      expect(find.byKey(const ValueKey('year_heatmap_grid')), findsOneWidget);
    });

    // #936: provider 에서 earnedBadges 읽어 트로피 그리드에 노출
    testWidgets('TrophyCollectionCard 노출 — provider earnedBadges 반영 (#936)', (
      tester,
    ) async {
      final badges = [
        PracticeBadge(
          id: 'b1',
          name: 'badge1',
          description: 'd',
          icon: 'i',
          rarity: BadgeRarity.common,
          isEarned: true,
        ),
      ];
      await _pump(tester, studentId: 's1', badges: badges);
      expect(
        find.byKey(const ValueKey('trophy_collection_card')),
        findsOneWidget,
      );
      // 트로피 아이템이 provider 배지로 렌더링되어야 함 (#936 핵심 검증)
      expect(
        find.byKey(const ValueKey('trophy_collection_item_b1')),
        findsOneWidget,
        reason: '#936: provider 배지 b1 이 트로피 그리드에 노출되어야 한다',
      );
    });

    // #936: 빈 배지 → 트로피 아이템 0건 (빈 상태)
    testWidgets('TrophyCollectionCard 빈 상태 — badges 0개 (#936)', (tester) async {
      await _pump(tester, studentId: 's1', badges: const []);
      expect(
        find.byKey(const ValueKey('trophy_collection_card')),
        findsOneWidget,
      );
    });

  });
}
