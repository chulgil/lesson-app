import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_category_shown_provider.g.dart';

const _kBoxName = 'onboarding_state';
const _kCategoryShownKey = 'category_preview_shown';

/// Step 2.5 카테고리 미리보기 영속 provider (W4 Task 4.2).
///
/// spec §9.1 — Step 2.5 `OnboardingCategoryPreviewScreen` 의 1회 노출 제어.
/// `markShown()` 호출 후에는 같은 사용자가 다시 진입해도 별도 처리 없이
/// 자동 spring-through (또는 Step 2.5 자체를 건너뛰는 로직 외부에서 활용).
///
/// `questFirstShownProvider` 와 별도 — 카테고리 미리보기와 첫 도착 카드
/// 윈도우의 개념이 다름 (architect P1 #4 의 NextMissionSpotlight 와는
/// 별개로 분리하지 않음).
@riverpod
class OnboardingCategoryShown extends _$OnboardingCategoryShown {
  Box<dynamic>? _box;

  Future<Box<dynamic>> _openBox() async {
    return _box ??= await Hive.openBox(_kBoxName);
  }

  @override
  Future<bool> build() async {
    final box = await _openBox();
    return box.get(_kCategoryShownKey, defaultValue: false) as bool;
  }

  /// Step 2.5 1회 노출 완료 표시 — [시작하기] / [건너뛰기] 어느 쪽이든 호출.
  Future<void> markShown() async {
    final box = await _openBox();
    await box.put(_kCategoryShownKey, true);
    ref.invalidateSelf();
    await future;
  }
}
