// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allPaymentsHash() => r'1c9e66ded39ba2fe08fd05c2b04b709eebb351c2';

/// All payments provider
///
/// Copied from [allPayments].
@ProviderFor(allPayments)
final allPaymentsProvider = FutureProvider<List<Payment>>.internal(
  allPayments,
  name: r'allPaymentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPaymentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllPaymentsRef = FutureProviderRef<List<Payment>>;
String _$paymentHash() => r'3d98f03c4ecd035fda9675626f9a353ba6d27da0';

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

/// Single payment provider
///
/// Copied from [payment].
@ProviderFor(payment)
const paymentProvider = PaymentFamily();

/// Single payment provider
///
/// Copied from [payment].
class PaymentFamily extends Family<AsyncValue<Payment?>> {
  /// Single payment provider
  ///
  /// Copied from [payment].
  const PaymentFamily();

  /// Single payment provider
  ///
  /// Copied from [payment].
  PaymentProvider call(String paymentId) {
    return PaymentProvider(paymentId);
  }

  @override
  PaymentProvider getProviderOverride(covariant PaymentProvider provider) {
    return call(provider.paymentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'paymentProvider';
}

/// Single payment provider
///
/// Copied from [payment].
class PaymentProvider extends FutureProvider<Payment?> {
  /// Single payment provider
  ///
  /// Copied from [payment].
  PaymentProvider(String paymentId)
    : this._internal(
        (ref) => payment(ref as PaymentRef, paymentId),
        from: paymentProvider,
        name: r'paymentProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$paymentHash,
        dependencies: PaymentFamily._dependencies,
        allTransitiveDependencies: PaymentFamily._allTransitiveDependencies,
        paymentId: paymentId,
      );

  PaymentProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.paymentId,
  }) : super.internal();

  final String paymentId;

  @override
  Override overrideWith(
    FutureOr<Payment?> Function(PaymentRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PaymentProvider._internal(
        (ref) => create(ref as PaymentRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        paymentId: paymentId,
      ),
    );
  }

  @override
  FutureProviderElement<Payment?> createElement() {
    return _PaymentProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentProvider && other.paymentId == paymentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, paymentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PaymentRef on FutureProviderRef<Payment?> {
  /// The parameter `paymentId` of this provider.
  String get paymentId;
}

class _PaymentProviderElement extends FutureProviderElement<Payment?>
    with PaymentRef {
  _PaymentProviderElement(super.provider);

  @override
  String get paymentId => (origin as PaymentProvider).paymentId;
}

String _$studentPaymentsHash() => r'9b16db18f7dcd569997bfc50c37efb56b4d975de';

/// Payments by student provider
///
/// Copied from [studentPayments].
@ProviderFor(studentPayments)
const studentPaymentsProvider = StudentPaymentsFamily();

/// Payments by student provider
///
/// Copied from [studentPayments].
class StudentPaymentsFamily extends Family<AsyncValue<List<Payment>>> {
  /// Payments by student provider
  ///
  /// Copied from [studentPayments].
  const StudentPaymentsFamily();

  /// Payments by student provider
  ///
  /// Copied from [studentPayments].
  StudentPaymentsProvider call(String studentId) {
    return StudentPaymentsProvider(studentId);
  }

  @override
  StudentPaymentsProvider getProviderOverride(
    covariant StudentPaymentsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'studentPaymentsProvider';
}

/// Payments by student provider
///
/// Copied from [studentPayments].
class StudentPaymentsProvider extends FutureProvider<List<Payment>> {
  /// Payments by student provider
  ///
  /// Copied from [studentPayments].
  StudentPaymentsProvider(String studentId)
    : this._internal(
        (ref) => studentPayments(ref as StudentPaymentsRef, studentId),
        from: studentPaymentsProvider,
        name: r'studentPaymentsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentPaymentsHash,
        dependencies: StudentPaymentsFamily._dependencies,
        allTransitiveDependencies:
            StudentPaymentsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentPaymentsProvider._internal(
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
    FutureOr<List<Payment>> Function(StudentPaymentsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentPaymentsProvider._internal(
        (ref) => create(ref as StudentPaymentsRef),
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
  FutureProviderElement<List<Payment>> createElement() {
    return _StudentPaymentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentPaymentsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentPaymentsRef on FutureProviderRef<List<Payment>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentPaymentsProviderElement
    extends FutureProviderElement<List<Payment>>
    with StudentPaymentsRef {
  _StudentPaymentsProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentPaymentsProvider).studentId;
}

String _$paymentsByStatusHash() => r'29abb7f7a66afcb88e6e11f92bf7dff48f247838';

/// Payments by status provider
///
/// Copied from [paymentsByStatus].
@ProviderFor(paymentsByStatus)
const paymentsByStatusProvider = PaymentsByStatusFamily();

/// Payments by status provider
///
/// Copied from [paymentsByStatus].
class PaymentsByStatusFamily extends Family<AsyncValue<List<Payment>>> {
  /// Payments by status provider
  ///
  /// Copied from [paymentsByStatus].
  const PaymentsByStatusFamily();

  /// Payments by status provider
  ///
  /// Copied from [paymentsByStatus].
  PaymentsByStatusProvider call(PaymentStatus status) {
    return PaymentsByStatusProvider(status);
  }

  @override
  PaymentsByStatusProvider getProviderOverride(
    covariant PaymentsByStatusProvider provider,
  ) {
    return call(provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'paymentsByStatusProvider';
}

/// Payments by status provider
///
/// Copied from [paymentsByStatus].
class PaymentsByStatusProvider extends FutureProvider<List<Payment>> {
  /// Payments by status provider
  ///
  /// Copied from [paymentsByStatus].
  PaymentsByStatusProvider(PaymentStatus status)
    : this._internal(
        (ref) => paymentsByStatus(ref as PaymentsByStatusRef, status),
        from: paymentsByStatusProvider,
        name: r'paymentsByStatusProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$paymentsByStatusHash,
        dependencies: PaymentsByStatusFamily._dependencies,
        allTransitiveDependencies:
            PaymentsByStatusFamily._allTransitiveDependencies,
        status: status,
      );

  PaymentsByStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final PaymentStatus status;

  @override
  Override overrideWith(
    FutureOr<List<Payment>> Function(PaymentsByStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PaymentsByStatusProvider._internal(
        (ref) => create(ref as PaymentsByStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  FutureProviderElement<List<Payment>> createElement() {
    return _PaymentsByStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentsByStatusProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PaymentsByStatusRef on FutureProviderRef<List<Payment>> {
  /// The parameter `status` of this provider.
  PaymentStatus get status;
}

class _PaymentsByStatusProviderElement
    extends FutureProviderElement<List<Payment>>
    with PaymentsByStatusRef {
  _PaymentsByStatusProviderElement(super.provider);

  @override
  PaymentStatus get status => (origin as PaymentsByStatusProvider).status;
}

String _$pendingPaymentsHash() => r'd62dbd26f2560b6207fe84823a84c48e608b5a25';

/// Pending payments provider
///
/// Copied from [pendingPayments].
@ProviderFor(pendingPayments)
final pendingPaymentsProvider = FutureProvider<List<Payment>>.internal(
  pendingPayments,
  name: r'pendingPaymentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingPaymentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PendingPaymentsRef = FutureProviderRef<List<Payment>>;
String _$overduePaymentsHash() => r'3ad045c65ed4a26293ee5f54969fa07188f28204';

/// Overdue payments provider
///
/// Copied from [overduePayments].
@ProviderFor(overduePayments)
final overduePaymentsProvider = FutureProvider<List<Payment>>.internal(
  overduePayments,
  name: r'overduePaymentsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$overduePaymentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OverduePaymentsRef = FutureProviderRef<List<Payment>>;
String _$paymentSummaryHash() => r'29543f6f757c91f25f6c838d9404edc5c872b909';

/// Payment summary provider
///
/// Copied from [paymentSummary].
@ProviderFor(paymentSummary)
final paymentSummaryProvider = FutureProvider<PaymentSummary>.internal(
  paymentSummary,
  name: r'paymentSummaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paymentSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PaymentSummaryRef = FutureProviderRef<PaymentSummary>;
String _$monthlyPaymentSummaryHash() =>
    r'bd0f05816fa6e68972ed9fe55754623bc55146f0';

/// Monthly payment summary provider
///
/// Copied from [monthlyPaymentSummary].
@ProviderFor(monthlyPaymentSummary)
const monthlyPaymentSummaryProvider = MonthlyPaymentSummaryFamily();

/// Monthly payment summary provider
///
/// Copied from [monthlyPaymentSummary].
class MonthlyPaymentSummaryFamily extends Family<AsyncValue<PaymentSummary>> {
  /// Monthly payment summary provider
  ///
  /// Copied from [monthlyPaymentSummary].
  const MonthlyPaymentSummaryFamily();

  /// Monthly payment summary provider
  ///
  /// Copied from [monthlyPaymentSummary].
  MonthlyPaymentSummaryProvider call(({int month, int year}) params) {
    return MonthlyPaymentSummaryProvider(params);
  }

  @override
  MonthlyPaymentSummaryProvider getProviderOverride(
    covariant MonthlyPaymentSummaryProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'monthlyPaymentSummaryProvider';
}

/// Monthly payment summary provider
///
/// Copied from [monthlyPaymentSummary].
class MonthlyPaymentSummaryProvider extends FutureProvider<PaymentSummary> {
  /// Monthly payment summary provider
  ///
  /// Copied from [monthlyPaymentSummary].
  MonthlyPaymentSummaryProvider(({int month, int year}) params)
    : this._internal(
        (ref) => monthlyPaymentSummary(ref as MonthlyPaymentSummaryRef, params),
        from: monthlyPaymentSummaryProvider,
        name: r'monthlyPaymentSummaryProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$monthlyPaymentSummaryHash,
        dependencies: MonthlyPaymentSummaryFamily._dependencies,
        allTransitiveDependencies:
            MonthlyPaymentSummaryFamily._allTransitiveDependencies,
        params: params,
      );

  MonthlyPaymentSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({int month, int year}) params;

  @override
  Override overrideWith(
    FutureOr<PaymentSummary> Function(MonthlyPaymentSummaryRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyPaymentSummaryProvider._internal(
        (ref) => create(ref as MonthlyPaymentSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  FutureProviderElement<PaymentSummary> createElement() {
    return _MonthlyPaymentSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyPaymentSummaryProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyPaymentSummaryRef on FutureProviderRef<PaymentSummary> {
  /// The parameter `params` of this provider.
  ({int month, int year}) get params;
}

class _MonthlyPaymentSummaryProviderElement
    extends FutureProviderElement<PaymentSummary>
    with MonthlyPaymentSummaryRef {
  _MonthlyPaymentSummaryProviderElement(super.provider);

  @override
  ({int month, int year}) get params =>
      (origin as MonthlyPaymentSummaryProvider).params;
}

String _$tuitionSettingsHash() => r'edf1e0427e333a60e16f3c819facd229fa1335c4';

/// Tuition settings provider
///
/// Copied from [tuitionSettings].
@ProviderFor(tuitionSettings)
const tuitionSettingsProvider = TuitionSettingsFamily();

/// Tuition settings provider
///
/// Copied from [tuitionSettings].
class TuitionSettingsFamily extends Family<AsyncValue<TuitionSettings?>> {
  /// Tuition settings provider
  ///
  /// Copied from [tuitionSettings].
  const TuitionSettingsFamily();

  /// Tuition settings provider
  ///
  /// Copied from [tuitionSettings].
  TuitionSettingsProvider call(String studentId) {
    return TuitionSettingsProvider(studentId);
  }

  @override
  TuitionSettingsProvider getProviderOverride(
    covariant TuitionSettingsProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tuitionSettingsProvider';
}

/// Tuition settings provider
///
/// Copied from [tuitionSettings].
class TuitionSettingsProvider extends FutureProvider<TuitionSettings?> {
  /// Tuition settings provider
  ///
  /// Copied from [tuitionSettings].
  TuitionSettingsProvider(String studentId)
    : this._internal(
        (ref) => tuitionSettings(ref as TuitionSettingsRef, studentId),
        from: tuitionSettingsProvider,
        name: r'tuitionSettingsProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$tuitionSettingsHash,
        dependencies: TuitionSettingsFamily._dependencies,
        allTransitiveDependencies:
            TuitionSettingsFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  TuitionSettingsProvider._internal(
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
    FutureOr<TuitionSettings?> Function(TuitionSettingsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TuitionSettingsProvider._internal(
        (ref) => create(ref as TuitionSettingsRef),
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
  FutureProviderElement<TuitionSettings?> createElement() {
    return _TuitionSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TuitionSettingsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TuitionSettingsRef on FutureProviderRef<TuitionSettings?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TuitionSettingsProviderElement
    extends FutureProviderElement<TuitionSettings?>
    with TuitionSettingsRef {
  _TuitionSettingsProviderElement(super.provider);

  @override
  String get studentId => (origin as TuitionSettingsProvider).studentId;
}

String _$paymentsNotifierHash() => r'9f3c42acb74ee488ffa3d3cf014f0b5c9474eedf';

/// Payments notifier for CRUD operations
///
/// Copied from [PaymentsNotifier].
@ProviderFor(PaymentsNotifier)
final paymentsNotifierProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>.internal(
      PaymentsNotifier.new,
      name: r'paymentsNotifierProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$paymentsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaymentsNotifier = AsyncNotifier<List<Payment>>;
String _$tuitionSettingsNotifierHash() =>
    r'5fd6239b98c541e0c6a65a17db27f28f907d2377';

abstract class _$TuitionSettingsNotifier
    extends BuildlessAsyncNotifier<TuitionSettings?> {
  late final String studentId;

  FutureOr<TuitionSettings?> build(String studentId);
}

/// Tuition settings notifier
///
/// Copied from [TuitionSettingsNotifier].
@ProviderFor(TuitionSettingsNotifier)
const tuitionSettingsNotifierProvider = TuitionSettingsNotifierFamily();

/// Tuition settings notifier
///
/// Copied from [TuitionSettingsNotifier].
class TuitionSettingsNotifierFamily
    extends Family<AsyncValue<TuitionSettings?>> {
  /// Tuition settings notifier
  ///
  /// Copied from [TuitionSettingsNotifier].
  const TuitionSettingsNotifierFamily();

  /// Tuition settings notifier
  ///
  /// Copied from [TuitionSettingsNotifier].
  TuitionSettingsNotifierProvider call(String studentId) {
    return TuitionSettingsNotifierProvider(studentId);
  }

  @override
  TuitionSettingsNotifierProvider getProviderOverride(
    covariant TuitionSettingsNotifierProvider provider,
  ) {
    return call(provider.studentId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'tuitionSettingsNotifierProvider';
}

/// Tuition settings notifier
///
/// Copied from [TuitionSettingsNotifier].
class TuitionSettingsNotifierProvider
    extends
        AsyncNotifierProviderImpl<TuitionSettingsNotifier, TuitionSettings?> {
  /// Tuition settings notifier
  ///
  /// Copied from [TuitionSettingsNotifier].
  TuitionSettingsNotifierProvider(String studentId)
    : this._internal(
        () => TuitionSettingsNotifier()..studentId = studentId,
        from: tuitionSettingsNotifierProvider,
        name: r'tuitionSettingsNotifierProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$tuitionSettingsNotifierHash,
        dependencies: TuitionSettingsNotifierFamily._dependencies,
        allTransitiveDependencies:
            TuitionSettingsNotifierFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  TuitionSettingsNotifierProvider._internal(
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
  FutureOr<TuitionSettings?> runNotifierBuild(
    covariant TuitionSettingsNotifier notifier,
  ) {
    return notifier.build(studentId);
  }

  @override
  Override overrideWith(TuitionSettingsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: TuitionSettingsNotifierProvider._internal(
        () => create()..studentId = studentId,
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
  AsyncNotifierProviderElement<TuitionSettingsNotifier, TuitionSettings?>
  createElement() {
    return _TuitionSettingsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TuitionSettingsNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TuitionSettingsNotifierRef on AsyncNotifierProviderRef<TuitionSettings?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _TuitionSettingsNotifierProviderElement
    extends
        AsyncNotifierProviderElement<TuitionSettingsNotifier, TuitionSettings?>
    with TuitionSettingsNotifierRef {
  _TuitionSettingsNotifierProviderElement(super.provider);

  @override
  String get studentId => (origin as TuitionSettingsNotifierProvider).studentId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
