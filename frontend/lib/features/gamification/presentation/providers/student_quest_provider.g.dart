// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_quest_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentQuestRepositoryHash() =>
    r'ff123b0ec02c78d15729b9b01a121cf2ce553de3';

/// P1: Mock 만 사용. P2 에서 BE 구현체 도입 시 환경 분기 추가 (O1 결정).
///
/// Copied from [studentQuestRepository].
@ProviderFor(studentQuestRepository)
final studentQuestRepositoryProvider =
    Provider<StudentQuestRepository>.internal(
  studentQuestRepository,
  name: r'studentQuestRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$studentQuestRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef StudentQuestRepositoryRef = ProviderRef<StudentQuestRepository>;
String _$activeQuestsHash() => r'c851439596dc07de7e2d309a41208afe1c19d2ff';

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

/// See also [activeQuests].
@ProviderFor(activeQuests)
const activeQuestsProvider = ActiveQuestsFamily();

/// See also [activeQuests].
class ActiveQuestsFamily extends Family<AsyncValue<List<StudentQuest>>> {
  /// See also [activeQuests].
  const ActiveQuestsFamily();

  /// See also [activeQuests].
  ActiveQuestsProvider call(
    String studentId,
  ) {
    return ActiveQuestsProvider(
      studentId,
    );
  }

  @override
  ActiveQuestsProvider getProviderOverride(
    covariant ActiveQuestsProvider provider,
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
  String? get name => r'activeQuestsProvider';
}

/// See also [activeQuests].
class ActiveQuestsProvider
    extends AutoDisposeFutureProvider<List<StudentQuest>> {
  /// See also [activeQuests].
  ActiveQuestsProvider(
    String studentId,
  ) : this._internal(
          (ref) => activeQuests(
            ref as ActiveQuestsRef,
            studentId,
          ),
          from: activeQuestsProvider,
          name: r'activeQuestsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$activeQuestsHash,
          dependencies: ActiveQuestsFamily._dependencies,
          allTransitiveDependencies:
              ActiveQuestsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  ActiveQuestsProvider._internal(
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
    FutureOr<List<StudentQuest>> Function(ActiveQuestsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveQuestsProvider._internal(
        (ref) => create(ref as ActiveQuestsRef),
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
  AutoDisposeFutureProviderElement<List<StudentQuest>> createElement() {
    return _ActiveQuestsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveQuestsProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveQuestsRef on AutoDisposeFutureProviderRef<List<StudentQuest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ActiveQuestsProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentQuest>>
    with ActiveQuestsRef {
  _ActiveQuestsProviderElement(super.provider);

  @override
  String get studentId => (origin as ActiveQuestsProvider).studentId;
}

String _$questsByOriginHash() => r'4bdc308c267ac01d0665d91c65cef7c281130b48';

/// See also [questsByOrigin].
@ProviderFor(questsByOrigin)
const questsByOriginProvider = QuestsByOriginFamily();

/// See also [questsByOrigin].
class QuestsByOriginFamily extends Family<AsyncValue<List<StudentQuest>>> {
  /// See also [questsByOrigin].
  const QuestsByOriginFamily();

  /// See also [questsByOrigin].
  QuestsByOriginProvider call(
    String studentId,
    QuestOrigin origin,
  ) {
    return QuestsByOriginProvider(
      studentId,
      origin,
    );
  }

  @override
  QuestsByOriginProvider getProviderOverride(
    covariant QuestsByOriginProvider provider,
  ) {
    return call(
      provider.studentId,
      provider.origin,
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
  String? get name => r'questsByOriginProvider';
}

/// See also [questsByOrigin].
class QuestsByOriginProvider
    extends AutoDisposeFutureProvider<List<StudentQuest>> {
  /// See also [questsByOrigin].
  QuestsByOriginProvider(
    String studentId,
    QuestOrigin origin,
  ) : this._internal(
          (ref) => questsByOrigin(
            ref as QuestsByOriginRef,
            studentId,
            origin,
          ),
          from: questsByOriginProvider,
          name: r'questsByOriginProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$questsByOriginHash,
          dependencies: QuestsByOriginFamily._dependencies,
          allTransitiveDependencies:
              QuestsByOriginFamily._allTransitiveDependencies,
          studentId: studentId,
          origin: origin,
        );

  QuestsByOriginProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.studentId,
    required this.origin,
  }) : super.internal();

  final String studentId;
  final QuestOrigin origin;

  @override
  Override overrideWith(
    FutureOr<List<StudentQuest>> Function(QuestsByOriginRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: QuestsByOriginProvider._internal(
        (ref) => create(ref as QuestsByOriginRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        studentId: studentId,
        origin: origin,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<StudentQuest>> createElement() {
    return _QuestsByOriginProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QuestsByOriginProvider &&
        other.studentId == studentId &&
        other.origin == origin;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);
    hash = _SystemHash.combine(hash, origin.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin QuestsByOriginRef on AutoDisposeFutureProviderRef<List<StudentQuest>> {
  /// The parameter `studentId` of this provider.
  String get studentId;

  /// The parameter `origin` of this provider.
  QuestOrigin get origin;
}

class _QuestsByOriginProviderElement
    extends AutoDisposeFutureProviderElement<List<StudentQuest>>
    with QuestsByOriginRef {
  _QuestsByOriginProviderElement(super.provider);

  @override
  String get studentId => (origin as QuestsByOriginProvider).studentId;
  @override
  QuestOrigin get origin => (origin as QuestsByOriginProvider).origin;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
