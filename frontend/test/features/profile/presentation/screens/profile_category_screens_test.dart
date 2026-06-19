import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/router/app_routes.dart';
import 'package:lessonaza/features/profile/presentation/screens/my_profile_category_screen.dart';
import 'package:lessonaza/features/profile/presentation/screens/policy_notifications_category_screen.dart';
import 'package:lessonaza/features/profile/presentation/screens/subscription_billing_category_screen.dart';

/// #765 — 카테고리 BottomSheet → 정식 라우트 승격.
///
/// 핵심 회귀: 시트였을 땐 항목 탭 → 시트 pop → detail push 라서, detail 에서
/// 뒤로가기 시 메뉴가 사라졌다. 라우트 화면이면 detail pop 후 메뉴로 복귀한다.
void main() {
  group('카테고리 화면 smoke', () {
    testWidgets('수강권·정산 화면이 항목을 렌더한다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SubscriptionBillingCategoryScreen(teacherId: 'teacher_1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.categorySheetSubscriptionBillingTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.profileSubscriptionTemplateLabel),
        findsOneWidget,
      );
      expect(find.text(AppStrings.profileCancelPolicyLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('내 프로필 화면이 5 항목을 렌더한다', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MyProfileCategoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.categorySheetMyProfileTitle), findsOneWidget);
      expect(find.text(AppStrings.profileBasicInfoEditLabel), findsOneWidget);
      expect(find.text(AppStrings.profilePreviewAndPublic), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('알림·소식·지원 화면이 섹션·항목을 렌더한다 (375 폭)', (tester) async {
      tester.view.physicalSize = const Size(375, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: PolicyNotificationsCategoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.categorySheetPolicyNotificationsTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.categorySheetSectionTemplates),
        findsOneWidget,
      );
      expect(find.text(AppStrings.profileHelpLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('라우트 화면이라 detail 진입 후 뒤로가기 시 메뉴로 복귀한다', (tester) async {
    final router = GoRouter(
      initialLocation: '/root',
      routes: [
        GoRoute(
          path: '/root',
          builder:
              (ctx, state) => const Scaffold(body: Center(child: Text('ROOT'))),
        ),
        GoRoute(
          path: AppRoutes.policyNotificationsCategory,
          builder: (ctx, state) => const PolicyNotificationsCategoryScreen(),
        ),
        // Stub destination the menu pushes into.
        GoRoute(
          path: AppRoutes.help,
          builder:
              (ctx, state) =>
                  const Scaffold(body: Center(child: Text('HELP_DETAIL'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    // Enter the category menu screen.
    router.push(AppRoutes.policyNotificationsCategory);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.profileHelpLabel), findsOneWidget);

    // Tap a menu item → pushes the detail route.
    await tester.tap(find.text(AppStrings.profileHelpLabel));
    await tester.pumpAndSettle();
    expect(find.text('HELP_DETAIL'), findsOneWidget);
    expect(find.text(AppStrings.profileHelpLabel), findsNothing);

    // Back from detail → the menu screen is restored (not lost like a sheet).
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('HELP_DETAIL'), findsNothing);
    expect(find.text(AppStrings.profileHelpLabel), findsOneWidget);
  });
}
