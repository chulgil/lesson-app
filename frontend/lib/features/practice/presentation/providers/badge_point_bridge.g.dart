// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_point_bridge.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$badgePointBridgeHash() => r'7f6d5cd3002ddf0c2eecdf07566382b0570f9e29';

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

/// Subscribes to [pointAwardNotifierProvider] and routes new awards to
/// the practice badge checker. Returns the number of point entries
/// observed so far (mostly for debug/diagnostics).
///
/// Copied from [badgePointBridge].
@ProviderFor(badgePointBridge)
const badgePointBridgeProvider = BadgePointBridgeFamily();

/// Subscribes to [pointAwardNotifierProvider] and routes new awards to
/// the practice badge checker. Returns the number of point entries
/// observed so far (mostly for debug/diagnostics).
///
/// Copied from [badgePointBridge].
class BadgePointBridgeFamily extends Family<int> {
  /// Subscribes to [pointAwardNotifierProvider] and routes new awards to
  /// the practice badge checker. Returns the number of point entries
  /// observed so far (mostly for debug/diagnostics).
  ///
  /// Copied from [badgePointBridge].
  const BadgePointBridgeFamily();

  /// Subscribes to [pointAwardNotifierProvider] and routes new awards to
  /// the practice badge checker. Returns the number of point entries
  /// observed so far (mostly for debug/diagnostics).
  ///
  /// Copied from [badgePointBridge].
  BadgePointBridgeProvider call(
    String studentId,
  ) {
    return BadgePointBridgeProvider(
      studentId,
    );
  }

  @override
  BadgePointBridgeProvider getProviderOverride(
    covariant BadgePointBridgeProvider provider,
  ) {
    return call(
      provider.studentId,
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
  String? get name => r'badgePointBridgeProvider';
}

/// Subscribes to [pointAwardNotifierProvider] and routes new awards to
/// the practice badge checker. Returns the number of point entries
/// observed so far (mostly for debug/diagnostics).
///
/// Copied from [badgePointBridge].
class BadgePointBridgeProvider extends Provider<int> {
  /// Subscribes to [pointAwardNotifierProvider] and routes new awards to
  /// the practice badge checker. Returns the number of point entries
  /// observed so far (mostly for debug/diagnostics).
  ///
  /// Copied from [badgePointBridge].
  BadgePointBridgeProvider(
    String studentId,
  ) : this._internal(
          (ref) => badgePointBridge(
            ref as BadgePointBridgeRef,
            studentId,
          ),
          from: badgePointBridgeProvider,
          name: r'badgePointBridgeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$badgePointBridgeHash,
          dependencies: BadgePointBridgeFamily._dependencies,
          allTransitiveDependencies:
              BadgePointBridgeFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  BadgePointBridgeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
  }) : super.internal();

  final String studentId;

  @override
  Override overrideWith(
    int Function(BadgePointBridgeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BadgePointBridgeProvider._internal(
        (ref) => create(ref as BadgePointBridgeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
      ),
    );
  }

  @override
  ProviderElement<int> createElement() {
    return _BadgePointBridgeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BadgePointBridgeProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin BadgePointBridgeRef on ProviderRef<int> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _BadgePointBridgeProviderElement extends ProviderElement<int>
    with BadgePointBridgeRef {
  _BadgePointBridgeProviderElement(super.provider);

  @override
  String get studentId => (origin as BadgePointBridgeProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
