// W2 Task 2.4 fix — profile category sheets 회귀 테스트.
// spec §3 line 108-122 5묶음 IA 정합.
//
// Verifies:
// - 내 프로필 BottomSheet 5 sub-항목 (기본정보/악기/자격증/레퍼토리/공개+미리보기)
// - 정책·알림·지원 BottomSheet: profileVisibility 제거됨, 가이드 다시 보기/팔로우/뉴스 추가됨
// - 수강권·정산 BottomSheet 5 sub-항목 유지

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/presentation/widgets/profile_category_sheets.dart';

void main() {
  Widget hostApp(void Function(BuildContext) onPressed) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => onPressed(ctx),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
        // Stub destinations — sheets navigate via context.push; we don't assert
        // the route push side effect here.
        GoRoute(path: '/:rest', builder: (ctx, state) => const SizedBox()),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  group('내 프로필 BottomSheet — spec §3 line 108-113', () {
    testWidgets('5 sub-항목 노출 (기본정보/악기/자격증/레퍼토리/공개)', (tester) async {
      await tester.pumpWidget(hostApp((ctx) => showMyProfileSheet(ctx)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.categorySheetMyProfileTitle), findsOneWidget);
      expect(find.text(AppStrings.profileBasicInfoEditLabel), findsOneWidget);
      expect(
        find.text(AppStrings.profileInstrumentManagementLabel),
        findsOneWidget,
      );
      expect(find.text(AppStrings.profileCredentialsLabel), findsOneWidget);
      expect(find.text(AppStrings.profileRepertoireLabel), findsOneWidget);
      expect(find.text(AppStrings.profileVisibilityLabel), findsOneWidget);
      expect(find.text(AppStrings.profilePreviewCta), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('정책·알림·지원 BottomSheet — spec §3 line 115-122', () {
    testWidgets('profileVisibility 제거됨 (→ 내 프로필 묶음으로 이동)', (tester) async {
      // Policy sheet 는 WidgetRef 가 필요 — ConsumerStatefulWidget 호스트 사용.
      await tester.pumpWidget(const _PolicySheetHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // profileVisibility 라벨이 정책 시트에서 사라졌는지 확인
      expect(find.text(AppStrings.profileVisibilityLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('가이드 다시 보기 / 팔로우 / 뉴스 신규 항목 노출', (tester) async {
      await tester.pumpWidget(const _PolicySheetHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.categoryGuideReplayLabel), findsOneWidget);
      expect(find.text(AppStrings.profileFollowingLabel), findsOneWidget);
      expect(find.text(AppStrings.profileNewsLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('가이드 다시 보기 탭 → guideReshow 라우트 이동 (W5 활성)', (tester) async {
      await tester.pumpWidget(const _PolicySheetHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categoryGuideReplayLabel));
      await tester.pumpAndSettle();

      // 시트가 닫히고 catch-all stub 라우트로 push 됨 — 시트 항목 사라짐.
      expect(find.text(AppStrings.categoryGuideReplayLabel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('기존 정책 항목 (피드백/팁/알림/녹음/계정) 보존', (tester) async {
      await tester.pumpWidget(const _PolicySheetHost());
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.profileNotificationLabel), findsOneWidget);
      expect(find.text(AppStrings.profileRecordingLabel), findsOneWidget);
      expect(find.text(AppStrings.profileTermsLabel), findsOneWidget);
      expect(find.text(AppStrings.profilePrivacyPolicyLabel), findsOneWidget);
      expect(find.text(AppStrings.profileLogoutLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('수강권·정산 BottomSheet — spec §3 line 100-106', () {
    testWidgets('5 sub-항목 노출 (템플릿/입금대기/계좌/취소정책/취소디폴트)', (tester) async {
      await tester.pumpWidget(
        hostApp((ctx) => showSubscriptionBillingSheet(ctx, 'teacher-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.profileSubscriptionTemplateLabel),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.profileOutstandingPaymentsLabel),
        findsOneWidget,
      );
      expect(find.text(AppStrings.profileBankAccountLabel), findsOneWidget);
      expect(find.text(AppStrings.profileCancelPolicyLabel), findsOneWidget);
      expect(
        find.text(AppStrings.profileCancellationDefaultsLabel),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    // #785 — 가격표 역할 구분 subtitle 노출 확인.
    testWidgets('가격표 항목에 역할 구분 subtitle 노출', (tester) async {
      await tester.pumpWidget(
        hostApp((ctx) => showSubscriptionBillingSheet(ctx, 'teacher-1')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.priceTableSection), findsOneWidget);
      expect(find.text(AppStrings.priceListRoleSubtitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Policy sheet 는 WidgetRef 가 필요하므로 ConsumerStatefulWidget 으로 호스트.
class _PolicySheetHost extends ConsumerStatefulWidget {
  const _PolicySheetHost();

  @override
  ConsumerState<_PolicySheetHost> createState() => _PolicySheetHostState();
}

class _PolicySheetHostState extends ConsumerState<_PolicySheetHost> {
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPolicyNotificationsSheet(ctx, ref),
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
        GoRoute(path: '/:rest', builder: (ctx, state) => const SizedBox()),
      ],
    );
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }
}
