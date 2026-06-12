// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_category_shown_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingCategoryShownHash() =>
    r'38443fb89c3c1c34c23c598abc5adefdfc8377e4';

/// Step 2.5 카테고리 미리보기 영속 provider (W4 Task 4.2).
///
/// spec §9.1 — Step 2.5 `OnboardingCategoryPreviewScreen` 의 1회 노출 제어.
/// `markShown()` 호출 후에는 같은 사용자가 다시 진입해도 별도 처리 없이
/// 자동 spring-through (또는 Step 2.5 자체를 건너뛰는 로직 외부에서 활용).
///
/// `questFirstShownProvider` 와 별도 — 카테고리 미리보기와 첫 도착 카드
/// 윈도우의 개념이 다름 (architect P1 #4 의 NextMissionSpotlight 와는
/// 별개로 분리하지 않음).
///
/// Copied from [OnboardingCategoryShown].
@ProviderFor(OnboardingCategoryShown)
final onboardingCategoryShownProvider =
    AutoDisposeAsyncNotifierProvider<OnboardingCategoryShown, bool>.internal(
  OnboardingCategoryShown.new,
  name: r'onboardingCategoryShownProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$onboardingCategoryShownHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$OnboardingCategoryShown = AutoDisposeAsyncNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
