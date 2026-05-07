// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_receipt_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherPaymentReceiptsHash() =>
    r'b3a3647948c44efe615802053caf4c3c4530d2ad';

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

/// All receipts for the current teacher (mock data).
///
/// Copied from [teacherPaymentReceipts].
@ProviderFor(teacherPaymentReceipts)
const teacherPaymentReceiptsProvider = TeacherPaymentReceiptsFamily();

/// All receipts for the current teacher (mock data).
///
/// Copied from [teacherPaymentReceipts].
class TeacherPaymentReceiptsFamily
    extends Family<AsyncValue<List<PaymentReceipt>>> {
  /// All receipts for the current teacher (mock data).
  ///
  /// Copied from [teacherPaymentReceipts].
  const TeacherPaymentReceiptsFamily();

  /// All receipts for the current teacher (mock data).
  ///
  /// Copied from [teacherPaymentReceipts].
  TeacherPaymentReceiptsProvider call({
    int? year,
    int? month,
  }) {
    return TeacherPaymentReceiptsProvider(
      year: year,
      month: month,
    );
  }

  @override
  TeacherPaymentReceiptsProvider getProviderOverride(
    covariant TeacherPaymentReceiptsProvider provider,
  ) {
    return call(
      year: provider.year,
      month: provider.month,
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
  String? get name => r'teacherPaymentReceiptsProvider';
}

/// All receipts for the current teacher (mock data).
///
/// Copied from [teacherPaymentReceipts].
class TeacherPaymentReceiptsProvider
    extends AutoDisposeFutureProvider<List<PaymentReceipt>> {
  /// All receipts for the current teacher (mock data).
  ///
  /// Copied from [teacherPaymentReceipts].
  TeacherPaymentReceiptsProvider({
    int? year,
    int? month,
  }) : this._internal(
          (ref) => teacherPaymentReceipts(
            ref as TeacherPaymentReceiptsRef,
            year: year,
            month: month,
          ),
          from: teacherPaymentReceiptsProvider,
          name: r'teacherPaymentReceiptsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherPaymentReceiptsHash,
          dependencies: TeacherPaymentReceiptsFamily._dependencies,
          allTransitiveDependencies:
              TeacherPaymentReceiptsFamily._allTransitiveDependencies,
          year: year,
          month: month,
        );

  TeacherPaymentReceiptsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.year,
    required this.month,
  }) : super.internal();

  final int? year;
  final int? month;

  @override
  Override overrideWith(
    FutureOr<List<PaymentReceipt>> Function(TeacherPaymentReceiptsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherPaymentReceiptsProvider._internal(
        (ref) => create(ref as TeacherPaymentReceiptsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        year: year,
        month: month,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PaymentReceipt>> createElement() {
    return _TeacherPaymentReceiptsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherPaymentReceiptsProvider &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, year.hashCode);
    hash = _SystemHash.combine(hash, month.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherPaymentReceiptsRef
    on AutoDisposeFutureProviderRef<List<PaymentReceipt>> {
  /// The parameter `year` of this provider.
  int? get year;

  /// The parameter `month` of this provider.
  int? get month;
}

class _TeacherPaymentReceiptsProviderElement
    extends AutoDisposeFutureProviderElement<List<PaymentReceipt>>
    with TeacherPaymentReceiptsRef {
  _TeacherPaymentReceiptsProviderElement(super.provider);

  @override
  int? get year => (origin as TeacherPaymentReceiptsProvider).year;
  @override
  int? get month => (origin as TeacherPaymentReceiptsProvider).month;
}

String _$paymentReceiptHash() => r'5bd2c49a043f298982b498274ed8aac8c22429d4';

/// Single receipt by ID.
///
/// Copied from [paymentReceipt].
@ProviderFor(paymentReceipt)
const paymentReceiptProvider = PaymentReceiptFamily();

/// Single receipt by ID.
///
/// Copied from [paymentReceipt].
class PaymentReceiptFamily extends Family<AsyncValue<PaymentReceipt?>> {
  /// Single receipt by ID.
  ///
  /// Copied from [paymentReceipt].
  const PaymentReceiptFamily();

  /// Single receipt by ID.
  ///
  /// Copied from [paymentReceipt].
  PaymentReceiptProvider call(
    String id,
  ) {
    return PaymentReceiptProvider(
      id,
    );
  }

  @override
  PaymentReceiptProvider getProviderOverride(
    covariant PaymentReceiptProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'paymentReceiptProvider';
}

/// Single receipt by ID.
///
/// Copied from [paymentReceipt].
class PaymentReceiptProvider
    extends AutoDisposeFutureProvider<PaymentReceipt?> {
  /// Single receipt by ID.
  ///
  /// Copied from [paymentReceipt].
  PaymentReceiptProvider(
    String id,
  ) : this._internal(
          (ref) => paymentReceipt(
            ref as PaymentReceiptRef,
            id,
          ),
          from: paymentReceiptProvider,
          name: r'paymentReceiptProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$paymentReceiptHash,
          dependencies: PaymentReceiptFamily._dependencies,
          allTransitiveDependencies:
              PaymentReceiptFamily._allTransitiveDependencies,
          id: id,
        );

  PaymentReceiptProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<PaymentReceipt?> Function(PaymentReceiptRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PaymentReceiptProvider._internal(
        (ref) => create(ref as PaymentReceiptRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PaymentReceipt?> createElement() {
    return _PaymentReceiptProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentReceiptProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PaymentReceiptRef on AutoDisposeFutureProviderRef<PaymentReceipt?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PaymentReceiptProviderElement
    extends AutoDisposeFutureProviderElement<PaymentReceipt?>
    with PaymentReceiptRef {
  _PaymentReceiptProviderElement(super.provider);

  @override
  String get id => (origin as PaymentReceiptProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
