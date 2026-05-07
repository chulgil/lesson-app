// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_repertoire_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentRepertoiresHash() =>
    r'9509cf2b55ced07cb652cdad8be2faf0320512fa';

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

/// Provider for student's repertoires list
///
/// Copied from [studentRepertoires].
@ProviderFor(studentRepertoires)
const studentRepertoiresProvider = StudentRepertoiresFamily();

/// Provider for student's repertoires list
///
/// Copied from [studentRepertoires].
class StudentRepertoiresFamily
    extends Family<AsyncValue<List<PracticeRepertoire>>> {
  /// Provider for student's repertoires list
  ///
  /// Copied from [studentRepertoires].
  const StudentRepertoiresFamily();

  /// Provider for student's repertoires list
  ///
  /// Copied from [studentRepertoires].
  StudentRepertoiresProvider call(String studentId) {
    return StudentRepertoiresProvider(studentId);
  }

  @override
  StudentRepertoiresProvider getProviderOverride(
    covariant StudentRepertoiresProvider provider,
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
  String? get name => r'studentRepertoiresProvider';
}

/// Provider for student's repertoires list
///
/// Copied from [studentRepertoires].
class StudentRepertoiresProvider
    extends FutureProvider<List<PracticeRepertoire>> {
  /// Provider for student's repertoires list
  ///
  /// Copied from [studentRepertoires].
  StudentRepertoiresProvider(String studentId)
    : this._internal(
        (ref) => studentRepertoires(ref as StudentRepertoiresRef, studentId),
        from: studentRepertoiresProvider,
        name: r'studentRepertoiresProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$studentRepertoiresHash,
        dependencies: StudentRepertoiresFamily._dependencies,
        allTransitiveDependencies:
            StudentRepertoiresFamily._allTransitiveDependencies,
        studentId: studentId,
      );

  StudentRepertoiresProvider._internal(
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
    FutureOr<List<PracticeRepertoire>> Function(StudentRepertoiresRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentRepertoiresProvider._internal(
        (ref) => create(ref as StudentRepertoiresRef),
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
  FutureProviderElement<List<PracticeRepertoire>> createElement() {
    return _StudentRepertoiresProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentRepertoiresProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentRepertoiresRef on FutureProviderRef<List<PracticeRepertoire>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentRepertoiresProviderElement
    extends FutureProviderElement<List<PracticeRepertoire>>
    with StudentRepertoiresRef {
  _StudentRepertoiresProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentRepertoiresProvider).studentId;
}

String _$repertoiresForDateHash() =>
    r'9ec85775e470d324358a4768b456c388c9975233';

/// Provider for student's repertoires filtered by date
///
/// Copied from [repertoiresForDate].
@ProviderFor(repertoiresForDate)
const repertoiresForDateProvider = RepertoiresForDateFamily();

/// Provider for student's repertoires filtered by date
///
/// Copied from [repertoiresForDate].
class RepertoiresForDateFamily
    extends Family<AsyncValue<List<PracticeRepertoire>>> {
  /// Provider for student's repertoires filtered by date
  ///
  /// Copied from [repertoiresForDate].
  const RepertoiresForDateFamily();

  /// Provider for student's repertoires filtered by date
  ///
  /// Copied from [repertoiresForDate].
  RepertoiresForDateProvider call(RepertoiresForDateParams params) {
    return RepertoiresForDateProvider(params);
  }

  @override
  RepertoiresForDateProvider getProviderOverride(
    covariant RepertoiresForDateProvider provider,
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
  String? get name => r'repertoiresForDateProvider';
}

/// Provider for student's repertoires filtered by date
///
/// Copied from [repertoiresForDate].
class RepertoiresForDateProvider
    extends FutureProvider<List<PracticeRepertoire>> {
  /// Provider for student's repertoires filtered by date
  ///
  /// Copied from [repertoiresForDate].
  RepertoiresForDateProvider(RepertoiresForDateParams params)
    : this._internal(
        (ref) => repertoiresForDate(ref as RepertoiresForDateRef, params),
        from: repertoiresForDateProvider,
        name: r'repertoiresForDateProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$repertoiresForDateHash,
        dependencies: RepertoiresForDateFamily._dependencies,
        allTransitiveDependencies:
            RepertoiresForDateFamily._allTransitiveDependencies,
        params: params,
      );

  RepertoiresForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final RepertoiresForDateParams params;

  @override
  Override overrideWith(
    FutureOr<List<PracticeRepertoire>> Function(RepertoiresForDateRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RepertoiresForDateProvider._internal(
        (ref) => create(ref as RepertoiresForDateRef),
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
  FutureProviderElement<List<PracticeRepertoire>> createElement() {
    return _RepertoiresForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RepertoiresForDateProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RepertoiresForDateRef on FutureProviderRef<List<PracticeRepertoire>> {
  /// The parameter `params` of this provider.
  RepertoiresForDateParams get params;
}

class _RepertoiresForDateProviderElement
    extends FutureProviderElement<List<PracticeRepertoire>>
    with RepertoiresForDateRef {
  _RepertoiresForDateProviderElement(super.provider);

  @override
  RepertoiresForDateParams get params =>
      (origin as RepertoiresForDateProvider).params;
}

String _$repertoireHash() => r'a16b34f60c06368d1300b60462896c322982db63';

/// Provider for a single repertoire
///
/// Copied from [repertoire].
@ProviderFor(repertoire)
const repertoireProvider = RepertoireFamily();

/// Provider for a single repertoire
///
/// Copied from [repertoire].
class RepertoireFamily extends Family<AsyncValue<PracticeRepertoire?>> {
  /// Provider for a single repertoire
  ///
  /// Copied from [repertoire].
  const RepertoireFamily();

  /// Provider for a single repertoire
  ///
  /// Copied from [repertoire].
  RepertoireProvider call(String repertoireId) {
    return RepertoireProvider(repertoireId);
  }

  @override
  RepertoireProvider getProviderOverride(
    covariant RepertoireProvider provider,
  ) {
    return call(provider.repertoireId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'repertoireProvider';
}

/// Provider for a single repertoire
///
/// Copied from [repertoire].
class RepertoireProvider extends FutureProvider<PracticeRepertoire?> {
  /// Provider for a single repertoire
  ///
  /// Copied from [repertoire].
  RepertoireProvider(String repertoireId)
    : this._internal(
        (ref) => repertoire(ref as RepertoireRef, repertoireId),
        from: repertoireProvider,
        name: r'repertoireProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$repertoireHash,
        dependencies: RepertoireFamily._dependencies,
        allTransitiveDependencies: RepertoireFamily._allTransitiveDependencies,
        repertoireId: repertoireId,
      );

  RepertoireProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.repertoireId,
  }) : super.internal();

  final String repertoireId;

  @override
  Override overrideWith(
    FutureOr<PracticeRepertoire?> Function(RepertoireRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RepertoireProvider._internal(
        (ref) => create(ref as RepertoireRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        repertoireId: repertoireId,
      ),
    );
  }

  @override
  FutureProviderElement<PracticeRepertoire?> createElement() {
    return _RepertoireProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RepertoireProvider && other.repertoireId == repertoireId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, repertoireId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin RepertoireRef on FutureProviderRef<PracticeRepertoire?> {
  /// The parameter `repertoireId` of this provider.
  String get repertoireId;
}

class _RepertoireProviderElement
    extends FutureProviderElement<PracticeRepertoire?>
    with RepertoireRef {
  _RepertoireProviderElement(super.provider);

  @override
  String get repertoireId => (origin as RepertoireProvider).repertoireId;
}

String _$sectionHash() => r'3365c3dccd112e22f082f2b19bb252333b024d47';

/// Provider for a single section
///
/// Copied from [section].
@ProviderFor(section)
const sectionProvider = SectionFamily();

/// Provider for a single section
///
/// Copied from [section].
class SectionFamily extends Family<AsyncValue<PracticeSection?>> {
  /// Provider for a single section
  ///
  /// Copied from [section].
  const SectionFamily();

  /// Provider for a single section
  ///
  /// Copied from [section].
  SectionProvider call(String sectionId) {
    return SectionProvider(sectionId);
  }

  @override
  SectionProvider getProviderOverride(covariant SectionProvider provider) {
    return call(provider.sectionId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'sectionProvider';
}

/// Provider for a single section
///
/// Copied from [section].
class SectionProvider extends FutureProvider<PracticeSection?> {
  /// Provider for a single section
  ///
  /// Copied from [section].
  SectionProvider(String sectionId)
    : this._internal(
        (ref) => section(ref as SectionRef, sectionId),
        from: sectionProvider,
        name: r'sectionProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$sectionHash,
        dependencies: SectionFamily._dependencies,
        allTransitiveDependencies: SectionFamily._allTransitiveDependencies,
        sectionId: sectionId,
      );

  SectionProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.sectionId,
  }) : super.internal();

  final String sectionId;

  @override
  Override overrideWith(
    FutureOr<PracticeSection?> Function(SectionRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SectionProvider._internal(
        (ref) => create(ref as SectionRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        sectionId: sectionId,
      ),
    );
  }

  @override
  FutureProviderElement<PracticeSection?> createElement() {
    return _SectionProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SectionProvider && other.sectionId == sectionId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, sectionId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SectionRef on FutureProviderRef<PracticeSection?> {
  /// The parameter `sectionId` of this provider.
  String get sectionId;
}

class _SectionProviderElement extends FutureProviderElement<PracticeSection?>
    with SectionRef {
  _SectionProviderElement(super.provider);

  @override
  String get sectionId => (origin as SectionProvider).sectionId;
}

String _$repertoireCrudHash() => r'1a5229356d6b0cf409a520aa90d92fd91658d74e';

/// Notifier for repertoire CRUD operations
///
/// Copied from [RepertoireCrud].
@ProviderFor(RepertoireCrud)
final repertoireCrudProvider =
    AsyncNotifierProvider<RepertoireCrud, void>.internal(
      RepertoireCrud.new,
      name: r'repertoireCrudProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$repertoireCrudHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RepertoireCrud = AsyncNotifier<void>;
String _$sectionCrudHash() => r'a89bb9a78af8438f6b60289b68a344d23539076e';

/// Notifier for section CRUD operations
///
/// Copied from [SectionCrud].
@ProviderFor(SectionCrud)
final sectionCrudProvider = AsyncNotifierProvider<SectionCrud, void>.internal(
  SectionCrud.new,
  name: r'sectionCrudProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$sectionCrudHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SectionCrud = AsyncNotifier<void>;
String _$recordingCrudHash() => r'ce3b1b73054137f1f6e59c6540f11d38988f00c7';

/// Notifier for recording CRUD operations
///
/// Copied from [RecordingCrud].
@ProviderFor(RecordingCrud)
final recordingCrudProvider =
    AsyncNotifierProvider<RecordingCrud, void>.internal(
      RecordingCrud.new,
      name: r'recordingCrudProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$recordingCrudHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RecordingCrud = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
