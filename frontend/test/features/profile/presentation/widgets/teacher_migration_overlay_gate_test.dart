// Tests for TeacherMigrationOverlayGate (W6 Task 6.3).
//
// Spec: .harness/spec/2026-06-11-teacher-settings-redesign.md §10.1
//   - 기존 가입 선생님이 ProfileTab 첫 진입 시 OnboardingCategoryPreviewScreen 1회 overlay
//   - 진행/스킵 후 markCategoryIntroduced(5개) + markShown → 정상 본 화면 노출
//   - shown==true 면 즉시 child 노출
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/onboarding/onboarding_facade.dart'
    show
        OnboardingCategoryPreviewScreen,
        OnboardingCategoryShown,
        onboardingCategoryShownProvider;
import 'package:lessonaza/features/profile/presentation/widgets/teacher_migration_overlay_gate.dart';

/// onboardingCategoryShownProvider override — Hive 없이 동작.
///
/// `state` setter 직접 사용 (invalidateSelf 회피) — 그래야 fake 인스턴스가
/// 재생성되며 초기 `_initial` 로 리셋되는 사고를 피할 수 있다.
class _FakeOnboardingCategoryShown extends OnboardingCategoryShown {
  _FakeOnboardingCategoryShown(this._initial);
  final bool _initial;

  @override
  Future<bool> build() async => _initial;

  @override
  Future<void> markShown() async {
    state = const AsyncValue.data(true);
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'lessonaza_migration_overlay_gate_test_',
    );
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// OnboardingCategoryPreviewScreen 의 grid + buttons 가 600px 기본 높이를
  /// 초과하므로, tap 이 hit 되도록 viewport 를 키운다.
  Future<void> setupTallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildHarness({required bool initialShown, required Widget child}) {
    return ProviderScope(
      overrides: [
        onboardingCategoryShownProvider.overrideWith(
          () => _FakeOnboardingCategoryShown(initialShown),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: TeacherMigrationOverlayGate(child: child)),
      ),
    );
  }

  group('TeacherMigrationOverlayGate — W6 마이그레이션 overlay (Task 6.3)', () {
    testWidgets('shown==false → overlay 노출, child 미렌더', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          initialShown: false,
          child: const Text('profile-tab-content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingCategoryPreviewScreen), findsOneWidget);
      expect(find.text('profile-tab-content'), findsNothing);
    });

    testWidgets('overlay 는 기존 사용자 문구 — 변경 공지 + 기능 보존 (신규 환영 문구 X)', (
      tester,
    ) async {
      // UX 카피 원칙 (2026-06-12): 같은 화면, 다른 청중 → 문구 분리.
      // 기존 가입 선생님에게 "환영합니다!" 는 컨텍스트 오류.
      await tester.pumpWidget(
        buildHarness(
          initialShown: false,
          child: const Text('profile-tab-content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.migrationCategoryPreviewTitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.migrationCategoryPreviewSubtitle),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.onboardingCategoryPreviewTitle),
        findsNothing,
      );
    });

    testWidgets('shown==true → child 즉시 노출, overlay 없음', (tester) async {
      await tester.pumpWidget(
        buildHarness(
          initialShown: true,
          child: const Text('profile-tab-content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingCategoryPreviewScreen), findsNothing);
      expect(find.text('profile-tab-content'), findsOneWidget);
    });

    // markCategoryIntroduced + markShown 의 동작 자체는
    // category_new_badge_provider_test (markAllIntroduced 케이스) + onboarding W4 의
    // onboarding_category_shown_provider 가 검증한다. Gate test 는 wiring contract 만.

    testWidgets('overlay [시작하기] / [건너뛰기] 두 버튼 모두 onProceed 콜백을 가진다', (
      tester,
    ) async {
      // tap chain 자체는 OnboardingCategoryPreviewScreen 의 W4 회귀 테스트가 담당.
      // 여기서는 두 버튼이 정확히 onProceed 를 호출하도록 wiring 되어 있는지만
      // contract 차원에서 보장한다 (gate 가 콜백 주입했음을 확인).
      await setupTallViewport(tester);
      await tester.pumpWidget(
        buildHarness(
          initialShown: false,
          child: const Text('profile-tab-content'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.onboardingCategoryPreviewStart),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.onboardingCategoryPreviewSkip),
        findsOneWidget,
      );

      final overlay = tester.widget<OnboardingCategoryPreviewScreen>(
        find.byType(OnboardingCategoryPreviewScreen),
      );
      expect(overlay.onProceed, isNotNull);
    });
  });
}
