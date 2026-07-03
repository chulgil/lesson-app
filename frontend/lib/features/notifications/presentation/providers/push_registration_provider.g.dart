// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_registration_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pushInitializerHash() => r'792705bbf089b77383e82ddb825215cf4bd883e9';

/// See also [pushInitializer].
@ProviderFor(pushInitializer)
final pushInitializerProvider = Provider<PushInitializer>.internal(
  pushInitializer,
  name: r'pushInitializerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushInitializerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PushInitializerRef = ProviderRef<PushInitializer>;
String _$pushRegistrationHash() => r'05de5867420a91656e81133d56c66cf8fc910884';

/// Registers the device for push once the user finishes onboarding (#475).
///
/// Wired in `main.dart` to fire when auth reaches [AuthAuthenticated], so the
/// OS notification-permission prompt appears *after* onboarding — never at
/// cold start before the user understands why. Guarded to run at most once per
/// session and skipped in mock mode (no backend to register the token with).
///
/// Copied from [PushRegistration].
@ProviderFor(PushRegistration)
final pushRegistrationProvider =
    NotifierProvider<PushRegistration, void>.internal(
  PushRegistration.new,
  name: r'pushRegistrationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushRegistrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PushRegistration = Notifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
