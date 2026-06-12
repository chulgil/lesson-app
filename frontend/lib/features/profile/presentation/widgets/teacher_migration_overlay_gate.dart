// W6 Task 6.3 — 기존 가입자 첫 진입 마이그레이션 overlay 게이트.
//
// spec §10.1 — 기존 가입 선생님이 새 5묶음 카테고리를 처음 인지하도록
// `OnboardingCategoryPreviewScreen` 을 1회 overlay 로 재활용한다.
//
// 동작:
//   - `onboardingCategoryShownProvider == false` → overlay 노출 (child 숨김)
//   - 사용자가 [시작하기]/[건너뛰기] 탭 → `_completeMigration`:
//       1. 5개 카테고리 `markCategoryIntroduced(now)` — NEW 7일 윈도우 시작
//       2. `markShown()` → flag 영속 → gate 자동 rebuild → child 노출
//   - `onboardingCategoryShownProvider == true` → child 즉시 노출 (정상)
//   - loading / error → child (안전한 fallback — overlay 누락 ≪ 데이터 차단)
//
// Constraint: gate 만 widget test 가능하도록 ProfileTab 의 의존성과 분리.
// Directive: child 가 비어있더라도 onboardingCategoryShownProvider 만 watch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../onboarding/onboarding_facade.dart'
    show OnboardingCategoryPreviewScreen, onboardingCategoryShownProvider;
import '../providers/category_new_badge_provider.dart';

/// ProfileTab 마이그레이션 overlay 게이트.
///
/// [child] 는 기존 ProfileTab body. shown==false 일 때만 overlay 가 보이고
/// child 는 mount 되지 않는다.
class TeacherMigrationOverlayGate extends ConsumerWidget {
  final Widget child;

  const TeacherMigrationOverlayGate({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shownAsync = ref.watch(onboardingCategoryShownProvider);
    final shown = shownAsync.valueOrNull;
    if (shown == false) {
      return OnboardingCategoryPreviewScreen(
        onProceed: () => _completeMigration(ref),
      );
    }
    return child;
  }

  /// overlay 진행/스킵 시 호출 — NEW 7일 윈도우 시작 + shown flag 영속.
  Future<void> _completeMigration(WidgetRef ref) async {
    await ref.read(categoryNewBadgeProvider.future);
    await ref
        .read(categoryNewBadgeProvider.notifier)
        .markAllIntroduced(DateTime.now());
    await ref.read(onboardingCategoryShownProvider.notifier).markShown();
  }
}
