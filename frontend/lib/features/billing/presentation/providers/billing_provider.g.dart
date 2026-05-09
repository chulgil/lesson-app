// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$billingRepositoryHash() => r'2bb5f5b63808287737b07bdf16081904c1330bb3';

/// See also [billingRepository].
@ProviderFor(billingRepository)
final billingRepositoryProvider = Provider<BillingRepository>.internal(
  billingRepository,
  name: r'billingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BillingRepositoryRef = ProviderRef<BillingRepository>;
String _$billingLimitReachedHash() =>
    r'ffc2d99c278822cea299a35a2d907abbe923fab2';

/// Whether the current teacher has exceeded the free plan student limit.
///
/// Returns `true` when:
/// - Plan is "free" AND student count >= studentLimit (5)
///
/// Used by [BillingGuard] to trigger the paywall/trial sheet.
///
/// Copied from [billingLimitReached].
@ProviderFor(billingLimitReached)
final billingLimitReachedProvider = AutoDisposeProvider<bool>.internal(
  billingLimitReached,
  name: r'billingLimitReachedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billingLimitReachedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BillingLimitReachedRef = AutoDisposeProviderRef<bool>;
String _$billingProductsHash() => r'e5c16bf874d827b10ae2009b7373782d68c4834d';

/// Available IAP products from the store.
///
/// Copied from [billingProducts].
@ProviderFor(billingProducts)
final billingProductsProvider =
    AutoDisposeFutureProvider<List<BillingProduct>>.internal(
  billingProducts,
  name: r'billingProductsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billingProductsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef BillingProductsRef = AutoDisposeFutureProviderRef<List<BillingProduct>>;
String _$billingStatusNotifierHash() =>
    r'7db5b27c4f4c97a230db73b94d4f889a3eb1cd6b';

/// Current billing status — cached and refreshable.
///
/// Copied from [BillingStatusNotifier].
@ProviderFor(BillingStatusNotifier)
final billingStatusNotifierProvider =
    AsyncNotifierProvider<BillingStatusNotifier, BillingStatus>.internal(
  BillingStatusNotifier.new,
  name: r'billingStatusNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$billingStatusNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BillingStatusNotifier = AsyncNotifier<BillingStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
