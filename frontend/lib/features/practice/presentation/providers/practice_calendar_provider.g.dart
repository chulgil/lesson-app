// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedPracticeMonthHash() =>
    r'22bf6feee8bd63c38ba8be4f33da8ab9b3341f55';

/// Selected month for practice calendar
///
/// Copied from [selectedPracticeMonth].
@ProviderFor(selectedPracticeMonth)
final selectedPracticeMonthProvider = Provider<DateTime>.internal(
  selectedPracticeMonth,
  name: r'selectedPracticeMonthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedPracticeMonthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SelectedPracticeMonthRef = ProviderRef<DateTime>;
String _$monthlyPracticeLogsHash() =>
    r'257262f3255fee4dd17aaa404e8b6aae81670063';

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

/// Practice logs for selected month
///
/// Copied from [monthlyPracticeLogs].
@ProviderFor(monthlyPracticeLogs)
const monthlyPracticeLogsProvider = MonthlyPracticeLogsFamily();

/// Practice logs for selected month
///
/// Copied from [monthlyPracticeLogs].
class MonthlyPracticeLogsFamily
    extends Family<AsyncValue<Map<DateTime, PracticeLog>>> {
  /// Practice logs for selected month
  ///
  /// Copied from [monthlyPracticeLogs].
  const MonthlyPracticeLogsFamily();

  /// Practice logs for selected month
  ///
  /// Copied from [monthlyPracticeLogs].
  MonthlyPracticeLogsProvider call(
    String studentId,
  ) {
    return MonthlyPracticeLogsProvider(
      studentId,
    );
  }

  @override
  MonthlyPracticeLogsProvider getProviderOverride(
    covariant MonthlyPracticeLogsProvider provider,
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
  String? get name => r'monthlyPracticeLogsProvider';
}

/// Practice logs for selected month
///
/// Copied from [monthlyPracticeLogs].
class MonthlyPracticeLogsProvider
    extends FutureProvider<Map<DateTime, PracticeLog>> {
  /// Practice logs for selected month
  ///
  /// Copied from [monthlyPracticeLogs].
  MonthlyPracticeLogsProvider(
    String studentId,
  ) : this._internal(
          (ref) => monthlyPracticeLogs(
            ref as MonthlyPracticeLogsRef,
            studentId,
          ),
          from: monthlyPracticeLogsProvider,
          name: r'monthlyPracticeLogsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyPracticeLogsHash,
          dependencies: MonthlyPracticeLogsFamily._dependencies,
          allTransitiveDependencies:
              MonthlyPracticeLogsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  MonthlyPracticeLogsProvider._internal(
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
    FutureOr<Map<DateTime, PracticeLog>> Function(
            MonthlyPracticeLogsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MonthlyPracticeLogsProvider._internal(
        (ref) => create(ref as MonthlyPracticeLogsRef),
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
  FutureProviderElement<Map<DateTime, PracticeLog>> createElement() {
    return _MonthlyPracticeLogsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyPracticeLogsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MonthlyPracticeLogsRef on FutureProviderRef<Map<DateTime, PracticeLog>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _MonthlyPracticeLogsProviderElement
    extends FutureProviderElement<Map<DateTime, PracticeLog>>
    with MonthlyPracticeLogsRef {
  _MonthlyPracticeLogsProviderElement(super.provider);

  @override
  String get studentId => (origin as MonthlyPracticeLogsProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
