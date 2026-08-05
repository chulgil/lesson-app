import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_bottom_nav.dart';

void main() {
  const items = [
    NotebookBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '홈',
    ),
    NotebookBottomNavItem(
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: '스케줄',
    ),
    NotebookBottomNavItem(
      icon: Icons.album_outlined,
      activeIcon: Icons.album,
      label: '수강관리',
    ),
    NotebookBottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '프로필',
    ),
  ];

  Future<void> pump(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onTap,
    Widget? centerAction,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: NotebookBottomNav(
            items: items,
            currentIndex: currentIndex,
            onTap: onTap ?? (_) {},
            centerAction: centerAction,
          ),
        ),
      ),
    );
  }

  testWidgets('렌더 — 예외 없이 아이콘/라벨을 표시한다', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 선택 탭은 filled, 나머지는 outlined.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    expect(find.text('수강관리'), findsOneWidget);
  });

  testWidgets('탭하면 해당 인덱스로 콜백한다', (tester) async {
    final tapped = <int>[];
    await pump(tester, onTap: tapped.add);

    await tester.tap(find.text('프로필'));
    await tester.pumpAndSettle();

    expect(tapped, [3]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('선택 탭은 paperAccent, 비선택은 inkTertiary', (tester) async {
    await pump(tester, currentIndex: 1);
    await tester.pumpAndSettle();

    final active = tester.widget<Icon>(find.byIcon(Icons.calendar_month));
    final inactive = tester.widget<Icon>(find.byIcon(Icons.home_outlined));

    expect(active.color, AppColors.paperAccent);
    expect(inactive.color, AppColors.inkTertiary);
  });

  testWidgets('centerAction 은 탭 가운데에 삽입되고 좁은 폭에서도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(
      tester,
      centerAction: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.mic_none),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });
}
