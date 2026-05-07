// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_announcement_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teacherAnnouncementRepositoryHash() =>
    r'bae1d912433f1e5c2ef784b15dfdc89b024ddb12';

/// Repository provider for teacher announcements.
///
/// Copied from [teacherAnnouncementRepository].
@ProviderFor(teacherAnnouncementRepository)
final teacherAnnouncementRepositoryProvider =
    Provider<TeacherAnnouncementRepository>.internal(
  teacherAnnouncementRepository,
  name: r'teacherAnnouncementRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$teacherAnnouncementRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TeacherAnnouncementRepositoryRef
    = ProviderRef<TeacherAnnouncementRepository>;
String _$teacherDayOffsHash() => r'f293242381b9c3d7a43709ff961adfd8c6e838c4';

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

/// 선생님의 휴강일 목록 (특정 기간).
/// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
///
/// Copied from [teacherDayOffs].
@ProviderFor(teacherDayOffs)
const teacherDayOffsProvider = TeacherDayOffsFamily();

/// 선생님의 휴강일 목록 (특정 기간).
/// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
///
/// Copied from [teacherDayOffs].
class TeacherDayOffsFamily extends Family<AsyncValue<List<DateTime>>> {
  /// 선생님의 휴강일 목록 (특정 기간).
  /// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
  ///
  /// Copied from [teacherDayOffs].
  const TeacherDayOffsFamily();

  /// 선생님의 휴강일 목록 (특정 기간).
  /// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
  ///
  /// Copied from [teacherDayOffs].
  TeacherDayOffsProvider call({
    required String teacherId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return TeacherDayOffsProvider(
      teacherId: teacherId,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  TeacherDayOffsProvider getProviderOverride(
    covariant TeacherDayOffsProvider provider,
  ) {
    return call(
      teacherId: provider.teacherId,
      fromDate: provider.fromDate,
      toDate: provider.toDate,
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
  String? get name => r'teacherDayOffsProvider';
}

/// 선생님의 휴강일 목록 (특정 기간).
/// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
///
/// Copied from [teacherDayOffs].
class TeacherDayOffsProvider extends AutoDisposeFutureProvider<List<DateTime>> {
  /// 선생님의 휴강일 목록 (특정 기간).
  /// 스케줄 탭, 시간 선택 UI에서 구독하여 휴강일을 표시/비활성화.
  ///
  /// Copied from [teacherDayOffs].
  TeacherDayOffsProvider({
    required String teacherId,
    required DateTime fromDate,
    required DateTime toDate,
  }) : this._internal(
          (ref) => teacherDayOffs(
            ref as TeacherDayOffsRef,
            teacherId: teacherId,
            fromDate: fromDate,
            toDate: toDate,
          ),
          from: teacherDayOffsProvider,
          name: r'teacherDayOffsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherDayOffsHash,
          dependencies: TeacherDayOffsFamily._dependencies,
          allTransitiveDependencies:
              TeacherDayOffsFamily._allTransitiveDependencies,
          teacherId: teacherId,
          fromDate: fromDate,
          toDate: toDate,
        );

  TeacherDayOffsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teacherId,
    required this.fromDate,
    required this.toDate,
  }) : super.internal();

  final String teacherId;
  final DateTime fromDate;
  final DateTime toDate;

  @override
  Override overrideWith(
    FutureOr<List<DateTime>> Function(TeacherDayOffsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherDayOffsProvider._internal(
        (ref) => create(ref as TeacherDayOffsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teacherId: teacherId,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<DateTime>> createElement() {
    return _TeacherDayOffsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherDayOffsProvider &&
        other.teacherId == teacherId &&
        other.fromDate == fromDate &&
        other.toDate == toDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);
    hash = _SystemHash.combine(hash, fromDate.hashCode);
    hash = _SystemHash.combine(hash, toDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherDayOffsRef on AutoDisposeFutureProviderRef<List<DateTime>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;

  /// The parameter `fromDate` of this provider.
  DateTime get fromDate;

  /// The parameter `toDate` of this provider.
  DateTime get toDate;
}

class _TeacherDayOffsProviderElement
    extends AutoDisposeFutureProviderElement<List<DateTime>>
    with TeacherDayOffsRef {
  _TeacherDayOffsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherDayOffsProvider).teacherId;
  @override
  DateTime get fromDate => (origin as TeacherDayOffsProvider).fromDate;
  @override
  DateTime get toDate => (origin as TeacherDayOffsProvider).toDate;
}

String _$teacherAnnouncementsHash() =>
    r'247fbf5afe8f6ac5ede433a1b9ade2e9a91218c4';

/// 선생님의 공지 목록.
///
/// Copied from [teacherAnnouncements].
@ProviderFor(teacherAnnouncements)
const teacherAnnouncementsProvider = TeacherAnnouncementsFamily();

/// 선생님의 공지 목록.
///
/// Copied from [teacherAnnouncements].
class TeacherAnnouncementsFamily
    extends Family<AsyncValue<List<TeacherAnnouncement>>> {
  /// 선생님의 공지 목록.
  ///
  /// Copied from [teacherAnnouncements].
  const TeacherAnnouncementsFamily();

  /// 선생님의 공지 목록.
  ///
  /// Copied from [teacherAnnouncements].
  TeacherAnnouncementsProvider call(
    String teacherId,
  ) {
    return TeacherAnnouncementsProvider(
      teacherId,
    );
  }

  @override
  TeacherAnnouncementsProvider getProviderOverride(
    covariant TeacherAnnouncementsProvider provider,
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
  String? get name => r'teacherAnnouncementsProvider';
}

/// 선생님의 공지 목록.
///
/// Copied from [teacherAnnouncements].
class TeacherAnnouncementsProvider
    extends AutoDisposeFutureProvider<List<TeacherAnnouncement>> {
  /// 선생님의 공지 목록.
  ///
  /// Copied from [teacherAnnouncements].
  TeacherAnnouncementsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherAnnouncements(
            ref as TeacherAnnouncementsRef,
            teacherId,
          ),
          from: teacherAnnouncementsProvider,
          name: r'teacherAnnouncementsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherAnnouncementsHash,
          dependencies: TeacherAnnouncementsFamily._dependencies,
          allTransitiveDependencies:
              TeacherAnnouncementsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherAnnouncementsProvider._internal(
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
    FutureOr<List<TeacherAnnouncement>> Function(
            TeacherAnnouncementsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherAnnouncementsProvider._internal(
        (ref) => create(ref as TeacherAnnouncementsRef),
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
  AutoDisposeFutureProviderElement<List<TeacherAnnouncement>> createElement() {
    return _TeacherAnnouncementsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherAnnouncementsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherAnnouncementsRef
    on AutoDisposeFutureProviderRef<List<TeacherAnnouncement>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherAnnouncementsProviderElement
    extends AutoDisposeFutureProviderElement<List<TeacherAnnouncement>>
    with TeacherAnnouncementsRef {
  _TeacherAnnouncementsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherAnnouncementsProvider).teacherId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
