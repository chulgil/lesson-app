import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/gamification.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';
import 'package:lessonaza/features/gamification/domain/repositories/growth_heatmap_repository.dart';
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

Future<void> _pump(
  WidgetTester tester, {
  required String studentId,
  GrowthHeatmap? heatmap,
  List<PracticeBadge> badges = const [],
  bool isUnder14 = false,
}) async {
  final stub = _StubGrowthHeatmapRepository(
    heatmap ?? GrowthHeatmap(studentId: studentId, days: const {}),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [growthHeatmapRepositoryProvider.overrideWithValue(stub)],
      child: MaterialApp(
        home: Scaffold(
          body: StudentGrowthDetailScreen(
            studentId: studentId,
            earnedBadges: badges,
            isUnder14: isUnder14,
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

    testWidgets('TrophyCollectionCard 노출 (badges)', (tester) async {
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
    });

    testWidgets('14세 이상 → 비교 보기 placeholder 노출', (tester) async {
      await _pump(tester, studentId: 's1', isUnder14: false);
      expect(
        find.byKey(const ValueKey('comparison_placeholder')),
        findsOneWidget,
      );
    });

    testWidgets('14세 미만 → 비교 보기 placeholder hide (스펙 §9.1)', (tester) async {
      await _pump(tester, studentId: 's1', isUnder14: true);
      expect(
        find.byKey(const ValueKey('comparison_placeholder')),
        findsNothing,
      );
    });

    testWidgets('Spotlight placeholder 노출 (P3 예정)', (tester) async {
      await _pump(tester, studentId: 's1');
      expect(
        find.byKey(const ValueKey('spotlight_placeholder')),
        findsOneWidget,
      );
    });

    testWidgets(
      'NO-OP 버튼 0건 — placeholder 영역에 onTap: () {} / onPressed: null 패턴 0 (ux-rules)',
      (tester) async {
        await _pump(tester, studentId: 's1', isUnder14: false);

        // GestureDetector.onTap 가 null 인 패턴만 허용 (정보 표시).
        // NO-OP 빈 함수 () {} 는 금지.
        final detectors = find.byType(GestureDetector);
        for (final el in detectors.evaluate()) {
          final widget = el.widget as GestureDetector;
          // 본 화면에서 GestureDetector 가 placeholder 영역에 존재하면
          // onTap 는 null (정보 표시) 또는 실제 라우팅 callback 이어야 함
          if (widget.onTap != null) {
            // 함수 본문이 빈 () {} 인지는 런타임 확인 불가 — 단, 본 테스트는
            // GestureDetector 가 placeholder 안에 실수로 들어가지 않는지만
            // 회귀 확인 (placeholder 자체에 GestureDetector 가 0개여야 함).
          }
        }

        // placeholder 컨테이너 안에 직접 GestureDetector 가 없어야 함
        final comparisonFinder = find.byKey(
          const ValueKey('comparison_placeholder'),
        );
        expect(comparisonFinder, findsOneWidget);
        // placeholder 의 children 안에서 GestureDetector 검색
        final gestureInPlaceholder = find.descendant(
          of: comparisonFinder,
          matching: find.byType(GestureDetector),
        );
        expect(
          gestureInPlaceholder,
          findsNothing,
          reason: 'placeholder 안에 GestureDetector 0개 (NO-OP 버튼 금지)',
        );
      },
    );
  });
}
