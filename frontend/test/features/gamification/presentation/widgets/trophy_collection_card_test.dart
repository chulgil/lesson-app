import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/gamification.dart';
import 'package:lessonaza/features/gamification/presentation/widgets/trophy_collection_card.dart';

PracticeBadge _badge(String id, {BadgeRarity rarity = BadgeRarity.common}) =>
    PracticeBadge(
      id: id,
      name: id,
      description: 'desc-$id',
      icon: 'icon-$id',
      rarity: rarity,
      isEarned: true,
      earnedAt: DateTime(2026, 6, 12),
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<PracticeBadge> badges,
  VoidCallback? onMore,
  bool viewerIsTeacher = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TrophyCollectionCard(
          badges: badges,
          onMoreTap: onMore,
          viewerIsTeacher: viewerIsTeacher,
        ),
      ),
    ),
  );
}

void main() {
  group('TrophyCollectionCard — Job 7 Task 7.1 / AC-6.3', () {
    testWidgets('widget smoke test — render exception 0 (HARD-GATE)', (
      tester,
    ) async {
      await _pump(tester, badges: const []);
      expect(tester.takeException(), isNull);
    });

    testWidgets('badge 0개 → 빈 상태 메시지', (tester) async {
      await _pump(tester, badges: const []);
      expect(
        find.byKey(const ValueKey('trophy_collection_empty')),
        findsOneWidget,
      );
      expect(find.text('곧 첫 트로피!'), findsOneWidget);
    });

    testWidgets('badge 1-8개 → 인라인 모두 표시', (tester) async {
      final badges = List.generate(5, (i) => _badge('b$i'));
      await _pump(tester, badges: badges);

      // 5 badge 모두 ValueKey 로 노출
      for (var i = 0; i < 5; i++) {
        expect(
          find.byKey(ValueKey('trophy_collection_item_b$i')),
          findsOneWidget,
        );
      }
      // 더보기 버튼 noShown
      expect(
        find.byKey(const ValueKey('trophy_collection_more')),
        findsNothing,
      );
    });

    testWidgets('badge 9+ → 8개 표시 + 더보기 버튼', (tester) async {
      final badges = List.generate(12, (i) => _badge('b$i'));
      await _pump(tester, badges: badges);

      // 첫 8개 노출
      for (var i = 0; i < 8; i++) {
        expect(
          find.byKey(ValueKey('trophy_collection_item_b$i')),
          findsOneWidget,
        );
      }
      // 9번째부터 hide
      expect(
        find.byKey(const ValueKey('trophy_collection_item_b8')),
        findsNothing,
      );
      // 더보기 버튼 노출
      expect(
        find.byKey(const ValueKey('trophy_collection_more')),
        findsOneWidget,
      );
    });

    testWidgets('count 표시 — "내 트로피 (N)"', (tester) async {
      final badges = List.generate(3, (i) => _badge('b$i'));
      await _pump(tester, badges: badges);

      expect(find.text('내 트로피'), findsOneWidget);
      expect(find.text('(3)'), findsOneWidget);
    });

    testWidgets('더보기 tap → onMoreTap callback 호출', (tester) async {
      var taps = 0;
      final badges = List.generate(12, (i) => _badge('b$i'));
      await _pump(tester, badges: badges, onMore: () => taps++);

      await tester.tap(find.byKey(const ValueKey('trophy_collection_more')));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets(
      '카테고리 라벨 노출 0 — rarity / "보상" / "common/rare/epic/legendary" 0건 (스펙 §16)',
      (tester) async {
        final badges = [
          _badge('b1', rarity: BadgeRarity.common),
          _badge('b2', rarity: BadgeRarity.rare),
          _badge('b3', rarity: BadgeRarity.epic),
          _badge('b4', rarity: BadgeRarity.legendary),
        ];
        await _pump(tester, badges: badges);

        // 카테고리 / rarity 라벨 0건
        expect(find.text('common'), findsNothing);
        expect(find.text('rare'), findsNothing);
        expect(find.text('epic'), findsNothing);
        expect(find.text('legendary'), findsNothing);
        expect(find.text('보상'), findsNothing);
        expect(find.text('카테고리'), findsNothing);
        expect(find.text('분류'), findsNothing);
      },
    );

    testWidgets('rarity 그룹화 없음 — 단일 행 표시', (tester) async {
      final badges = [
        _badge('b1', rarity: BadgeRarity.common),
        _badge('b2', rarity: BadgeRarity.legendary),
      ];
      await _pump(tester, badges: badges);

      // 그룹 헤더 / 구분선 / 카테고리 그룹 ValueKey 0
      expect(find.byKey(const ValueKey('trophy_group_common')), findsNothing);
      expect(
        find.byKey(const ValueKey('trophy_group_legendary')),
        findsNothing,
      );
    });

    // ── #783 티어 한글 라벨 ──────────────────────────────────────────────────
    testWidgets('#783 티어 한글 라벨 — 각 rarity 에 맞는 한글 표시', (tester) async {
      final badges = [
        _badge('b1', rarity: BadgeRarity.common),
        _badge('b2', rarity: BadgeRarity.rare),
        _badge('b3', rarity: BadgeRarity.epic),
        _badge('b4', rarity: BadgeRarity.legendary),
      ];
      await _pump(tester, badges: badges);

      expect(find.text('일반'), findsOneWidget);
      expect(find.text('희귀'), findsOneWidget);
      expect(find.text('특급'), findsOneWidget);
      expect(find.text('전설'), findsOneWidget);
    });

    // ── #783 역할 조건부 제목 ────────────────────────────────────────────────
    testWidgets('#783 viewerIsTeacher=false → "내 트로피" 제목', (tester) async {
      final badges = [_badge('b1')];
      await _pump(tester, badges: badges);

      expect(find.text('내 트로피'), findsOneWidget);
      expect(find.text('학생 트로피'), findsNothing);
    });

    testWidgets('#783 viewerIsTeacher=true → "학생 트로피" 제목', (tester) async {
      final badges = [_badge('b1')];
      await _pump(tester, badges: badges, viewerIsTeacher: true);

      expect(find.text('학생 트로피'), findsOneWidget);
      expect(find.text('내 트로피'), findsNothing);
    });

    testWidgets('#783 smoke test viewerIsTeacher=true — render exception 0', (
      tester,
    ) async {
      await _pump(tester, badges: const [], viewerIsTeacher: true);
      expect(tester.takeException(), isNull);
    });
  });
}
