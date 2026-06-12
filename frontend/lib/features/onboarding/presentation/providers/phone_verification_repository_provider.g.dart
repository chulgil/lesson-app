// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_verification_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$phoneVerificationRepositoryHash() =>
    r'44c8f0a793625631f489c73aae33d9d0e60d46d1';

/// Phone verification repository provider — #709.
///
/// 항상 remote 구현을 반환한다. mock 모드(mockDataModeProvider)에서는
/// 호출자(TeacherOnboardingNotifier)가 이 repo 를 호출하지 않고 기존
/// 로컬 시뮬레이션 동작을 유지한다 — 개발 편의.
///
/// Copied from [phoneVerificationRepository].
@ProviderFor(phoneVerificationRepository)
final phoneVerificationRepositoryProvider =
    Provider<PhoneVerificationRepository>.internal(
  phoneVerificationRepository,
  name: r'phoneVerificationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$phoneVerificationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PhoneVerificationRepositoryRef
    = ProviderRef<PhoneVerificationRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
