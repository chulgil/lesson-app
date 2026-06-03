// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherSettingsHash() => r'8280ea81365790eb469fa84e531b91724f29aa37';

/// Teacher settings provider (for current logged-in teacher)
///
/// Copied from [teacherSettings].
@ProviderFor(teacherSettings)
final teacherSettingsProvider = FutureProvider<TeacherSettings>.internal(
  teacherSettings,
  name: r'teacherSettingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherSettingsRef = FutureProviderRef<TeacherSettings>;
String _$teacherSettingsByIdHash() =>
    r'c3f6b94c934a8894c19137d74e69c6a613f6686a';

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

/// Teacher settings provider by teacherId (for viewing other teacher's settings)
///
/// Copied from [teacherSettingsById].
@ProviderFor(teacherSettingsById)
const teacherSettingsByIdProvider = TeacherSettingsByIdFamily();

/// Teacher settings provider by teacherId (for viewing other teacher's settings)
///
/// Copied from [teacherSettingsById].
class TeacherSettingsByIdFamily extends Family<AsyncValue<TeacherSettings>> {
  /// Teacher settings provider by teacherId (for viewing other teacher's settings)
  ///
  /// Copied from [teacherSettingsById].
  const TeacherSettingsByIdFamily();

  /// Teacher settings provider by teacherId (for viewing other teacher's settings)
  ///
  /// Copied from [teacherSettingsById].
  TeacherSettingsByIdProvider call(
    String teacherId,
  ) {
    return TeacherSettingsByIdProvider(
      teacherId,
    );
  }

  @override
  TeacherSettingsByIdProvider getProviderOverride(
    covariant TeacherSettingsByIdProvider provider,
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
  String? get name => r'teacherSettingsByIdProvider';
}

/// Teacher settings provider by teacherId (for viewing other teacher's settings)
///
/// Copied from [teacherSettingsById].
class TeacherSettingsByIdProvider extends FutureProvider<TeacherSettings> {
  /// Teacher settings provider by teacherId (for viewing other teacher's settings)
  ///
  /// Copied from [teacherSettingsById].
  TeacherSettingsByIdProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherSettingsById(
            ref as TeacherSettingsByIdRef,
            teacherId,
          ),
          from: teacherSettingsByIdProvider,
          name: r'teacherSettingsByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherSettingsByIdHash,
          dependencies: TeacherSettingsByIdFamily._dependencies,
          allTransitiveDependencies:
              TeacherSettingsByIdFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherSettingsByIdProvider._internal(
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
  Override overrideWith(
    FutureOr<TeacherSettings> Function(TeacherSettingsByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherSettingsByIdProvider._internal(
        (ref) => create(ref as TeacherSettingsByIdRef),
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
  FutureProviderElement<TeacherSettings> createElement() {
    return _TeacherSettingsByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherSettingsByIdProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherSettingsByIdRef on FutureProviderRef<TeacherSettings> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherSettingsByIdProviderElement
    extends FutureProviderElement<TeacherSettings> with TeacherSettingsByIdRef {
  _TeacherSettingsByIdProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherSettingsByIdProvider).teacherId;
}

String _$teacherInstrumentsHash() =>
    r'd99b793b5e800fb09d69c83cdf3fb8938127c2a3';

/// Teacher instruments provider (derived from settings)
///
/// Copied from [teacherInstruments].
@ProviderFor(teacherInstruments)
final teacherInstrumentsProvider = Provider<AsyncValue<List<String>>>.internal(
  teacherInstruments,
  name: r'teacherInstrumentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherInstrumentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherInstrumentsRef = ProviderRef<AsyncValue<List<String>>>;
String _$defaultLessonDurationHash() =>
    r'e241076635d0fbefe75cbf3c97ed8656404d25ed';

/// Default lesson duration provider (derived from settings)
///
/// Copied from [defaultLessonDuration].
@ProviderFor(defaultLessonDuration)
final defaultLessonDurationProvider = Provider<AsyncValue<int>>.internal(
  defaultLessonDuration,
  name: r'defaultLessonDurationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$defaultLessonDurationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DefaultLessonDurationRef = ProviderRef<AsyncValue<int>>;
String _$availableTimeSlotsHash() =>
    r'b278cf97fc51cb910e01b191fe0918d4d6eae865';

/// Available time slots provider (derived from settings)
///
/// Copied from [availableTimeSlots].
@ProviderFor(availableTimeSlots)
final availableTimeSlotsProvider =
    Provider<AsyncValue<List<TimeSlot>>>.internal(
  availableTimeSlots,
  name: r'availableTimeSlotsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableTimeSlotsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AvailableTimeSlotsRef = ProviderRef<AsyncValue<List<TimeSlot>>>;
String _$teacherSettingsNotifierHash() =>
    r'691702e0da684a2a3cc54f18d3837255c871a9a2';

/// Teacher settings notifier for CRUD operations
///
/// Copied from [TeacherSettingsNotifier].
@ProviderFor(TeacherSettingsNotifier)
final teacherSettingsNotifierProvider =
    AsyncNotifierProvider<TeacherSettingsNotifier, TeacherSettings>.internal(
  TeacherSettingsNotifier.new,
  name: r'teacherSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TeacherSettingsNotifier = AsyncNotifier<TeacherSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
