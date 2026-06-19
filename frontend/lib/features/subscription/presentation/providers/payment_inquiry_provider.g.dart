// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_inquiry_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$paymentInquiryStorageHash() =>
    r'311462137c870ccf779edce69caac1b73e42fd9b';

/// Storage instance provider — overridden in tests with an in-memory fake so
/// the records notifier can be exercised without Hive.
///
/// Copied from [paymentInquiryStorage].
@ProviderFor(paymentInquiryStorage)
final paymentInquiryStorageProvider = Provider<PaymentInquiryStorage>.internal(
  paymentInquiryStorage,
  name: r'paymentInquiryStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$paymentInquiryStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PaymentInquiryStorageRef = ProviderRef<PaymentInquiryStorage>;
String _$paymentInquiryRecordsHash() =>
    r'8b4f46a3537f70211f18fa8bfd1528d399da5126';

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

abstract class _$PaymentInquiryRecords
    extends BuildlessAutoDisposeAsyncNotifier<Map<String, DateTime>> {
  late final String teacherId;

  FutureOr<Map<String, DateTime>> build(
    String teacherId,
  );
}

/// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
///
/// Mutations update the Hive store and the in-memory state directly (no
/// invalidateSelf) so the cached box / family instance survives.
///
/// Copied from [PaymentInquiryRecords].
@ProviderFor(PaymentInquiryRecords)
const paymentInquiryRecordsProvider = PaymentInquiryRecordsFamily();

/// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
///
/// Mutations update the Hive store and the in-memory state directly (no
/// invalidateSelf) so the cached box / family instance survives.
///
/// Copied from [PaymentInquiryRecords].
class PaymentInquiryRecordsFamily
    extends Family<AsyncValue<Map<String, DateTime>>> {
  /// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
  ///
  /// Mutations update the Hive store and the in-memory state directly (no
  /// invalidateSelf) so the cached box / family instance survives.
  ///
  /// Copied from [PaymentInquiryRecords].
  const PaymentInquiryRecordsFamily();

  /// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
  ///
  /// Mutations update the Hive store and the in-memory state directly (no
  /// invalidateSelf) so the cached box / family instance survives.
  ///
  /// Copied from [PaymentInquiryRecords].
  PaymentInquiryRecordsProvider call(
    String teacherId,
  ) {
    return PaymentInquiryRecordsProvider(
      teacherId,
    );
  }

  @override
  PaymentInquiryRecordsProvider getProviderOverride(
    covariant PaymentInquiryRecordsProvider provider,
  ) {
    return call(
      provider.teacherId,
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
  String? get name => r'paymentInquiryRecordsProvider';
}

/// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
///
/// Mutations update the Hive store and the in-memory state directly (no
/// invalidateSelf) so the cached box / family instance survives.
///
/// Copied from [PaymentInquiryRecords].
class PaymentInquiryRecordsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PaymentInquiryRecords,
        Map<String, DateTime>> {
  /// Teacher-scoped map of `proposalId → last inquiry time` for "확인 보류" state.
  ///
  /// Mutations update the Hive store and the in-memory state directly (no
  /// invalidateSelf) so the cached box / family instance survives.
  ///
  /// Copied from [PaymentInquiryRecords].
  PaymentInquiryRecordsProvider(
    String teacherId,
  ) : this._internal(
          () => PaymentInquiryRecords()..teacherId = teacherId,
          from: paymentInquiryRecordsProvider,
          name: r'paymentInquiryRecordsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$paymentInquiryRecordsHash,
          dependencies: PaymentInquiryRecordsFamily._dependencies,
          allTransitiveDependencies:
              PaymentInquiryRecordsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  PaymentInquiryRecordsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
  }) : super.internal();

  final String teacherId;

  @override
  FutureOr<Map<String, DateTime>> runNotifierBuild(
    covariant PaymentInquiryRecords notifier,
  ) {
    return notifier.build(
      teacherId,
    );
  }

  @override
  Override overrideWith(PaymentInquiryRecords Function() create) {
    return ProviderOverride(
      origin: this,
      override: PaymentInquiryRecordsProvider._internal(
        () => create()..teacherId = teacherId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PaymentInquiryRecords,
      Map<String, DateTime>> createElement() {
    return _PaymentInquiryRecordsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentInquiryRecordsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PaymentInquiryRecordsRef
    on AutoDisposeAsyncNotifierProviderRef<Map<String, DateTime>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _PaymentInquiryRecordsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PaymentInquiryRecords,
        Map<String, DateTime>> with PaymentInquiryRecordsRef {
  _PaymentInquiryRecordsProviderElement(super.provider);

  @override
  String get teacherId => (origin as PaymentInquiryRecordsProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
