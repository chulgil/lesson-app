// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_new_badge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$categoryNewBadgeHash() => r'5a5b3c74bdf6ea3174ea910a90fc66421df451f1';

/// W6 마이그레이션 NEW 배지 영속 provider.
///
/// Hive box (`category_new_badge_state`) 에 카테고리별 introducedAt /
/// entered flag 를 ISO 문자열 / boolean 으로 저장.
///
/// keepAlive — ProfileTab 탭 전환 시 상태 유지.
///
/// Copied from [CategoryNewBadge].
@ProviderFor(CategoryNewBadge)
final categoryNewBadgeProvider =
    AsyncNotifierProvider<CategoryNewBadge, CategoryNewBadgeState>.internal(
  CategoryNewBadge.new,
  name: r'categoryNewBadgeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$categoryNewBadgeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CategoryNewBadge = AsyncNotifier<CategoryNewBadgeState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
