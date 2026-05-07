// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'travel_time_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$travelTimeApiHash() => r'254b1dc9bd544dccf438ba60bd91cd76c23e7b62';

/// See also [travelTimeApi].
@ProviderFor(travelTimeApi)
final travelTimeApiProvider = Provider<TravelTimeApi>.internal(
  travelTimeApi,
  name: r'travelTimeApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$travelTimeApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TravelTimeApiRef = ProviderRef<TravelTimeApi>;
String _$estimatedTravelTimeHash() =>
    r'39ab1b80d24a6347676a7583801b0cce8ea665cc';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Estimate travel time between teacher and student addresses.
/// Returns null if either address is missing or API fails.
/// Used by LocationTravelSelector to auto-fill travel time input.
///
/// Copied from [estimatedTravelTime].
@ProviderFor(estimatedTravelTime)
const estimatedTravelTimeProvider = EstimatedTravelTimeFamily();

/// Estimate travel time between teacher and student addresses.
/// Returns null if either address is missing or API fails.
/// Used by LocationTravelSelector to auto-fill travel time input.
///
/// Copied from [estimatedTravelTime].
class EstimatedTravelTimeFamily extends Family<AsyncValue<TravelTimeResult?>> {
  /// Estimate travel time between teacher and student addresses.
  /// Returns null if either address is missing or API fails.
  /// Used by LocationTravelSelector to auto-fill travel time input.
  ///
  /// Copied from [estimatedTravelTime].
  const EstimatedTravelTimeFamily();

  /// Estimate travel time between teacher and student addresses.
  /// Returns null if either address is missing or API fails.
  /// Used by LocationTravelSelector to auto-fill travel time input.
  ///
  /// Copied from [estimatedTravelTime].
  EstimatedTravelTimeProvider call({
    required String originAddress,
    required String destinationAddress,
  }) {
    return EstimatedTravelTimeProvider(
      originAddress: originAddress,
      destinationAddress: destinationAddress,
    );
  }

  @override
  EstimatedTravelTimeProvider getProviderOverride(
    covariant EstimatedTravelTimeProvider provider,
  ) {
    return call(
      originAddress: provider.originAddress,
      destinationAddress: provider.destinationAddress,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'estimatedTravelTimeProvider';
}

/// Estimate travel time between teacher and student addresses.
/// Returns null if either address is missing or API fails.
/// Used by LocationTravelSelector to auto-fill travel time input.
///
/// Copied from [estimatedTravelTime].
class EstimatedTravelTimeProvider
    extends AutoDisposeFutureProvider<TravelTimeResult?> {
  /// Estimate travel time between teacher and student addresses.
  /// Returns null if either address is missing or API fails.
  /// Used by LocationTravelSelector to auto-fill travel time input.
  ///
  /// Copied from [estimatedTravelTime].
  EstimatedTravelTimeProvider({
    required String originAddress,
    required String destinationAddress,
  }) : this._internal(
          (ref) => estimatedTravelTime(
            ref as EstimatedTravelTimeRef,
            originAddress: originAddress,
            destinationAddress: destinationAddress,
          ),
          from: estimatedTravelTimeProvider,
          name: r'estimatedTravelTimeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$estimatedTravelTimeHash,
          dependencies: EstimatedTravelTimeFamily._dependencies,
          allTransitiveDependencies:
              EstimatedTravelTimeFamily._allTransitiveDependencies,
          originAddress: originAddress,
          destinationAddress: destinationAddress,
        );

  EstimatedTravelTimeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.originAddress,
    required this.destinationAddress,
  }) : super.internal();

  final String originAddress;
  final String destinationAddress;

  @override
  Override overrideWith(
    FutureOr<TravelTimeResult?> Function(EstimatedTravelTimeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EstimatedTravelTimeProvider._internal(
        (ref) => create(ref as EstimatedTravelTimeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        originAddress: originAddress,
        destinationAddress: destinationAddress,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TravelTimeResult?> createElement() {
    return _EstimatedTravelTimeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EstimatedTravelTimeProvider &&
        other.originAddress == originAddress &&
        other.destinationAddress == destinationAddress;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, originAddress.hashCode);
    hash = _SystemHash.combine(hash, destinationAddress.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin EstimatedTravelTimeRef
    on AutoDisposeFutureProviderRef<TravelTimeResult?> {
  /// The parameter `originAddress` of this provider.
  String get originAddress;

  /// The parameter `destinationAddress` of this provider.
  String get destinationAddress;
}

class _EstimatedTravelTimeProviderElement
    extends AutoDisposeFutureProviderElement<TravelTimeResult?>
    with EstimatedTravelTimeRef {
  _EstimatedTravelTimeProviderElement(super.provider);

  @override
  String get originAddress =>
      (origin as EstimatedTravelTimeProvider).originAddress;
  @override
  String get destinationAddress =>
      (origin as EstimatedTravelTimeProvider).destinationAddress;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
