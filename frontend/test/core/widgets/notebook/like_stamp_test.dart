import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/core/widgets/notebook/like_stamp.dart';

/// §7.133 LikeStamp 비대칭 디자인 회귀 테스트.
///
/// OFF (verb, 행동 초대): 텍스트 링크 — container/border/bg 없음, "좋아요 표시"
/// ON  (noun, 기록된 결과): solid stamp pill — paperAccent bg, "좋음"
///
/// 두 상태가 다른 시각 카테고리에 속해야 OFF가 "muted ON"으로 오인되지 않는다.
void main() {
  Future<void> pumpStamp(
    WidgetTester tester, {
    required bool isLiked,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(child: LikeStamp(isLiked: isLiked, onTap: onTap)),
        ),
      ),
    );
  }

  group('LikeStamp OFF 상태 (verb)', () {
    testWidgets('hollow heart 글리프(♡) + "좋아요 표시" 라벨을 렌더한다', (tester) async {
      await pumpStamp(tester, isLiked: false, onTap: () {});

      // §9 Phase 2: Material Icon → NotebookGlyph 마이그레이션
      expect(find.text('♡'), findsOneWidget);
      expect(find.text('♥'), findsNothing);
      expect(find.text(AppStrings.practiceLikeOff), findsOneWidget);
      expect(find.text('좋아요 표시'), findsOneWidget);
    });

    testWidgets('container/border/bg 가 없다 (텍스트 링크 스타일)', (tester) async {
      await pumpStamp(tester, isLiked: false, onTap: () {});

      // OFF는 BoxDecoration을 가진 Container가 없어야 함
      // (있다면 OFF가 "muted ON"으로 오인됨)
      final containers =
          find
              .byType(Container)
              .evaluate()
              .map((e) => e.widget as Container)
              .where((c) => c.decoration is BoxDecoration)
              .toList();

      for (final container in containers) {
        final decoration = container.decoration as BoxDecoration;
        // paperAccent bg 또는 border 가 없어야 한다
        expect(
          decoration.color == AppColors.paperAccent,
          isFalse,
          reason: 'OFF 상태에 paperAccent bg 가 있으면 ON으로 오인됨',
        );
        expect(
          decoration.border != null,
          isFalse,
          reason: 'OFF 상태에 border 가 있으면 pill 구조로 오인됨',
        );
      }
    });
  });

  group('LikeStamp ON 상태 (noun)', () {
    testWidgets('filled heart 글리프(♥) + "좋음" 라벨을 렌더한다', (tester) async {
      await pumpStamp(tester, isLiked: true, onTap: () {});

      // §9 Phase 2: Material Icon → NotebookGlyph 마이그레이션
      expect(find.text('♥'), findsOneWidget);
      expect(find.text('♡'), findsNothing);
      expect(find.text(AppStrings.practiceLikeOn), findsOneWidget);
      expect(find.text('좋음'), findsOneWidget);
    });

    testWidgets('paperAccent solid bg pill 구조를 가진다', (tester) async {
      await pumpStamp(tester, isLiked: true, onTap: () {});

      final hasPaperAccentBg = find
          .byType(Container)
          .evaluate()
          .map((e) => e.widget as Container)
          .any(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).color == AppColors.paperAccent,
          );

      expect(
        hasPaperAccentBg,
        isTrue,
        reason: 'ON 상태는 paperAccent solid bg 가 있어야 stamp 메타포 성립',
      );
    });
  });

  group('LikeStamp tap 동작', () {
    testWidgets('onTap 제공 시 탭하면 콜백이 호출된다 (OFF→ON)', (tester) async {
      var tapped = 0;
      await pumpStamp(tester, isLiked: false, onTap: () => tapped++);

      await tester.tap(find.byType(LikeStamp));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('onTap 제공 시 탭하면 콜백이 호출된다 (ON→OFF)', (tester) async {
      var tapped = 0;
      await pumpStamp(tester, isLiked: true, onTap: () => tapped++);

      await tester.tap(find.byType(LikeStamp));
      await tester.pumpAndSettle();

      expect(tapped, 1);
    });

    testWidgets('onTap == null 이면 GestureDetector 가 없다 (read-only)', (
      tester,
    ) async {
      await pumpStamp(tester, isLiked: true, onTap: null);

      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('LikeStamp 접근성', () {
    testWidgets('onTap 제공 시 Semantics(button: true, toggled) 가 부여된다', (
      tester,
    ) async {
      await pumpStamp(tester, isLiked: false, onTap: () {});

      final semantics = tester.getSemantics(find.byType(LikeStamp));
      // ignore: deprecated_member_use — flagsCollection (Flutter 3.32+) 까지의 호환 유지
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      // ignore: deprecated_member_use
      expect(semantics.hasFlag(SemanticsFlag.hasToggledState), isTrue);
      // ignore: deprecated_member_use
      expect(semantics.hasFlag(SemanticsFlag.isToggled), isFalse);
    });

    testWidgets('ON 상태 Semantics 는 isToggled = true', (tester) async {
      await pumpStamp(tester, isLiked: true, onTap: () {});

      final semantics = tester.getSemantics(find.byType(LikeStamp));
      // ignore: deprecated_member_use
      expect(semantics.hasFlag(SemanticsFlag.isToggled), isTrue);
    });
  });

  group('LikeStamp 레이아웃 회귀', () {
    testWidgets('Row 안에서 OFF 상태가 BoxConstraints 크래시 없이 렌더된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                LikeStamp(isLiked: false, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('Row 안에서 ON 상태가 BoxConstraints 크래시 없이 렌더된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Row(
              children: [
                const Expanded(child: SizedBox()),
                LikeStamp(isLiked: true, onTap: () {}),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
