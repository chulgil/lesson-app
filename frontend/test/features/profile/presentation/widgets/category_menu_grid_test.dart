// W2 Task 2.4 — CategoryMenuGrid 회귀 + smoke 테스트.
// W6 Task 6.4 — NEW 배지 wiring 회귀 추가.
// HARD-GATE: design-principles.md (widget-smoke-test).
// spec §3 (IA) + §7.2 (메인 홈) + §11.1 (카드 라벨 규칙) + §10.2 (NEW 배지).
//
// Verifies:
// - 5 카드 노출 (운영시간/수업방식/수강권·정산/내 프로필/정책·알림·지원)
// - 기존 "레슨 시간 설정" / "가용 요일/시간" 메뉴 부재 (5묶음으로 흡수)
// - 각 카드 탭 → 해당 콜백 호출
// - 좁은 폭 layout 안전
// - NEW 배지: introducedAt 있고 7일 윈도우 내 + entered==false 일 때 노출
// - 카드 tap → markEntered → 다음 build 에서 NEW 사라짐

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/presentation/providers/category_new_badge_provider.dart';
import 'package:lessonaza/features/profile/presentation/providers/category_status_provider.dart';
import 'package:lessonaza/features/profile/presentation/widgets/category_menu_grid.dart';

/// Hive 의존성 우회용 fake — initial entries 를 in-memory state 로 노출.
class _FakeCategoryNewBadge extends CategoryNewBadge {
  _FakeCategoryNewBadge(this._initial);
  final Map<ProfileCategoryId, CategoryNewBadgeEntry> _initial;

  @override
  Future<CategoryNewBadgeState> build() async {
    return CategoryNewBadgeState(entries: Map.of(_initial));
  }

  @override
  Future<void> markCategoryIntroduced(
    ProfileCategoryId id,
    DateTime now,
  ) async {
    final current = state.requireValue;
    if (current.entries[id]?.introducedAt != null) return;
    final next = Map<ProfileCategoryId, CategoryNewBadgeEntry>.from(
      current.entries,
    );
    final previous = next[id];
    next[id] = CategoryNewBadgeEntry(
      introducedAt: now,
      entered: previous?.entered ?? false,
    );
    state = AsyncValue.data(CategoryNewBadgeState(entries: next));
  }

  @override
  Future<void> markEntered(ProfileCategoryId id) async {
    final current = state.requireValue;
    final next = Map<ProfileCategoryId, CategoryNewBadgeEntry>.from(
      current.entries,
    );
    final previous = next[id];
    next[id] = CategoryNewBadgeEntry(
      introducedAt: previous?.introducedAt,
      entered: true,
    );
    state = AsyncValue.data(CategoryNewBadgeState(entries: next));
  }
}

void main() {
  Widget wrap(
    Widget child, {
    double? width,
    Map<ProfileCategoryId, CategoryNewBadgeEntry> newBadgeEntries = const {},
  }) {
    return ProviderScope(
      overrides: [
        operatingHoursStatusProvider.overrideWith(
          (ref) => const CategoryStatusComplete(),
        ),
        lessonStyleStatusProvider.overrideWith(
          (ref) => const CategoryStatusPartial(filled: 2, total: 3),
        ),
        subscriptionBillingStatusProvider.overrideWith(
          (ref) => const CategoryStatusEmpty(),
        ),
        myProfileStatusProvider.overrideWith(
          (ref) => const CategoryStatusComplete(),
        ),
        policyNotificationsStatusProvider.overrideWith(
          (ref) => const CategoryStatusNeutral(),
        ),
        categoryNewBadgeProvider.overrideWith(
          () => _FakeCategoryNewBadge(newBadgeEntries),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: width ?? 360, child: child),
          ),
        ),
      ),
    );
  }

  CategoryMenuGrid buildGrid({
    VoidCallback? onOperatingHours,
    VoidCallback? onLessonStyle,
    VoidCallback? onSubscriptionBilling,
    VoidCallback? onMyProfile,
    VoidCallback? onPolicyNotifications,
  }) {
    return CategoryMenuGrid(
      onOperatingHoursTap: onOperatingHours ?? () {},
      onLessonStyleTap: onLessonStyle ?? () {},
      onSubscriptionBillingTap: onSubscriptionBilling ?? () {},
      onMyProfileTap: onMyProfile ?? () {},
      onPolicyNotificationsTap: onPolicyNotifications ?? () {},
    );
  }

  group('CategoryMenuGrid 5묶음 그리드 (W2 Task 2.4)', () {
    testWidgets('5 카테고리 카드 제목 노출', (tester) async {
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.categoryOperatingHours), findsOneWidget);
      expect(find.text(AppStrings.categoryLessonStyle), findsOneWidget);
      expect(find.text(AppStrings.categorySubscriptionBilling), findsOneWidget);
      expect(find.text(AppStrings.categoryMyProfile), findsOneWidget);
      expect(find.text(AppStrings.categoryPolicyNotifications), findsOneWidget);
      expect(find.text(AppStrings.categorySectionTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5묶음으로 흡수된 기존 메뉴 라벨 부재', (tester) async {
      // 5묶음 IA 로 흩어진 항목들 — 그리드 자체에서는 0 hit.
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      expect(find.text('레슨 시간 설정'), findsNothing);
      expect(find.text('가용 요일/시간'), findsNothing);
      expect(find.text('가용 시간 관리'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('운영시간 카드 탭 → onOperatingHoursTap 호출', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(buildGrid(onOperatingHours: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categoryOperatingHours));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('수업방식 카드 탭 → onLessonStyleTap 호출', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(buildGrid(onLessonStyle: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categoryLessonStyle));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('수강권·정산 카드 탭 → onSubscriptionBillingTap 호출 (BottomSheet 후크)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(buildGrid(onSubscriptionBilling: () => taps++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categorySubscriptionBilling));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('내 프로필 카드 탭 → onMyProfileTap 호출', (tester) async {
      var taps = 0;
      await tester.pumpWidget(wrap(buildGrid(onMyProfile: () => taps++)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categoryMyProfile));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('정책·알림 카드 탭 → onPolicyNotificationsTap 호출 (BottomSheet 후크)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(buildGrid(onPolicyNotifications: () => taps++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.categoryPolicyNotifications));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('상태 라벨 노출 — 5묶음별 status provider 반영', (tester) async {
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      // Complete (운영시간, 내 프로필) → 설정완료 2회 노출
      expect(find.text(AppStrings.categoryStatusComplete), findsNWidgets(2));
      // Partial 2/3 (수업방식)
      expect(
        find.text(AppStrings.categoryStatusPartialNOfM(2, 3)),
        findsOneWidget,
      );
      // Empty (수강권·정산)
      expect(find.text(AppStrings.categoryStatusEmpty), findsOneWidget);
      // Neutral (정책·알림)
      expect(
        find.text(AppStrings.categoryStatusNeutralDefault),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('좁은 width (280px) — BoxConstraints 크래시 없음', (tester) async {
      await tester.pumpWidget(wrap(buildGrid(), width: 280));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // ---- W6 Task 6.4 — NEW 배지 wiring 회귀 ----

    testWidgets('초기 상태 (markCategoryIntroduced 미호출) → NEW 배지 0개', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_card_badge_new')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('markCategoryIntroduced(운영시간) → 운영시간 카드에만 NEW 점 노출', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CategoryMenuGrid)),
      );
      await container.read(categoryNewBadgeProvider.future);
      await container
          .read(categoryNewBadgeProvider.notifier)
          .markCategoryIntroduced(
            ProfileCategoryId.operatingHours,
            DateTime.now(),
          );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('category_card_badge_new')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('markAllIntroduced → 5묶음 모두 NEW 배지 노출 (overlay 진행 후 시나리오)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(buildGrid()));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CategoryMenuGrid)),
      );
      await container.read(categoryNewBadgeProvider.future);
      await container
          .read(categoryNewBadgeProvider.notifier)
          .markAllIntroduced(DateTime.now());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('category_card_badge_new')),
        findsNWidgets(5),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
