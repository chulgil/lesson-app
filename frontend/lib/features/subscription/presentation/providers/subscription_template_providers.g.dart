// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_template_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$subscriptionTemplateRepositoryHash() =>
    r'58b56604d758faad675778a61a718f17052241e4';

/// Template repository provider - switches between Mock and Remote.
///
/// Copied from [subscriptionTemplateRepository].
@ProviderFor(subscriptionTemplateRepository)
final subscriptionTemplateRepositoryProvider =
    Provider<SubscriptionTemplateRepository>.internal(
      subscriptionTemplateRepository,
      name: r'subscriptionTemplateRepositoryProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$subscriptionTemplateRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef SubscriptionTemplateRepositoryRef =
    ProviderRef<SubscriptionTemplateRepository>;
String _$teacherTemplatesHash() => r'3ece1db7ec611ed16fe64b09532f42026f0725f9';

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

/// See also [teacherTemplates].
@ProviderFor(teacherTemplates)
const teacherTemplatesProvider = TeacherTemplatesFamily();

/// See also [teacherTemplates].
class TeacherTemplatesFamily
    extends Family<AsyncValue<List<SubscriptionTemplate>>> {
  /// See also [teacherTemplates].
  const TeacherTemplatesFamily();

  /// See also [teacherTemplates].
  TeacherTemplatesProvider call(String teacherId) {
    return TeacherTemplatesProvider(teacherId);
  }

  @override
  TeacherTemplatesProvider getProviderOverride(
    covariant TeacherTemplatesProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teacherTemplatesProvider';
}

/// See also [teacherTemplates].
class TeacherTemplatesProvider
    extends AutoDisposeFutureProvider<List<SubscriptionTemplate>> {
  /// See also [teacherTemplates].
  TeacherTemplatesProvider(String teacherId)
    : this._internal(
        (ref) => teacherTemplates(ref as TeacherTemplatesRef, teacherId),
        from: teacherTemplatesProvider,
        name: r'teacherTemplatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$teacherTemplatesHash,
        dependencies: TeacherTemplatesFamily._dependencies,
        allTransitiveDependencies:
            TeacherTemplatesFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  TeacherTemplatesProvider._internal(
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
    FutureOr<List<SubscriptionTemplate>> Function(TeacherTemplatesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherTemplatesProvider._internal(
        (ref) => create(ref as TeacherTemplatesRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionTemplate>> createElement() {
    return _TeacherTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherTemplatesProvider && other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TeacherTemplatesRef
    on AutoDisposeFutureProviderRef<List<SubscriptionTemplate>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionTemplate>>
    with TeacherTemplatesRef {
  _TeacherTemplatesProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherTemplatesProvider).teacherId;
}

String _$activeTeacherTemplatesHash() =>
    r'44b524bed9fc975f6ab644456ebb711ce0a91096';

/// See also [activeTeacherTemplates].
@ProviderFor(activeTeacherTemplates)
const activeTeacherTemplatesProvider = ActiveTeacherTemplatesFamily();

/// See also [activeTeacherTemplates].
class ActiveTeacherTemplatesFamily
    extends Family<AsyncValue<List<SubscriptionTemplate>>> {
  /// See also [activeTeacherTemplates].
  const ActiveTeacherTemplatesFamily();

  /// See also [activeTeacherTemplates].
  ActiveTeacherTemplatesProvider call(String teacherId) {
    return ActiveTeacherTemplatesProvider(teacherId);
  }

  @override
  ActiveTeacherTemplatesProvider getProviderOverride(
    covariant ActiveTeacherTemplatesProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'activeTeacherTemplatesProvider';
}

/// See also [activeTeacherTemplates].
class ActiveTeacherTemplatesProvider
    extends AutoDisposeFutureProvider<List<SubscriptionTemplate>> {
  /// See also [activeTeacherTemplates].
  ActiveTeacherTemplatesProvider(String teacherId)
    : this._internal(
        (ref) =>
            activeTeacherTemplates(ref as ActiveTeacherTemplatesRef, teacherId),
        from: activeTeacherTemplatesProvider,
        name: r'activeTeacherTemplatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$activeTeacherTemplatesHash,
        dependencies: ActiveTeacherTemplatesFamily._dependencies,
        allTransitiveDependencies:
            ActiveTeacherTemplatesFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  ActiveTeacherTemplatesProvider._internal(
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
    FutureOr<List<SubscriptionTemplate>> Function(
      ActiveTeacherTemplatesRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveTeacherTemplatesProvider._internal(
        (ref) => create(ref as ActiveTeacherTemplatesRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionTemplate>> createElement() {
    return _ActiveTeacherTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveTeacherTemplatesProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveTeacherTemplatesRef
    on AutoDisposeFutureProviderRef<List<SubscriptionTemplate>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _ActiveTeacherTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionTemplate>>
    with ActiveTeacherTemplatesRef {
  _ActiveTeacherTemplatesProviderElement(super.provider);

  @override
  String get teacherId => (origin as ActiveTeacherTemplatesProvider).teacherId;
}

String _$autoProposalTemplatesHash() =>
    r'8374e434d982dfe45f991ebd331a0d924e51d3c0';

/// 🆕 자동 제안 대상 템플릿만 가져오기
/// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
/// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
///
/// Copied from [autoProposalTemplates].
@ProviderFor(autoProposalTemplates)
const autoProposalTemplatesProvider = AutoProposalTemplatesFamily();

/// 🆕 자동 제안 대상 템플릿만 가져오기
/// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
/// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
///
/// Copied from [autoProposalTemplates].
class AutoProposalTemplatesFamily
    extends Family<AsyncValue<List<SubscriptionTemplate>>> {
  /// 🆕 자동 제안 대상 템플릿만 가져오기
  /// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
  /// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
  ///
  /// Copied from [autoProposalTemplates].
  const AutoProposalTemplatesFamily();

  /// 🆕 자동 제안 대상 템플릿만 가져오기
  /// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
  /// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
  ///
  /// Copied from [autoProposalTemplates].
  AutoProposalTemplatesProvider call(String teacherId) {
    return AutoProposalTemplatesProvider(teacherId);
  }

  @override
  AutoProposalTemplatesProvider getProviderOverride(
    covariant AutoProposalTemplatesProvider provider,
  ) {
    return call(provider.teacherId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'autoProposalTemplatesProvider';
}

/// 🆕 자동 제안 대상 템플릿만 가져오기
/// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
/// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
///
/// Copied from [autoProposalTemplates].
class AutoProposalTemplatesProvider
    extends AutoDisposeFutureProvider<List<SubscriptionTemplate>> {
  /// 🆕 자동 제안 대상 템플릿만 가져오기
  /// isActive = true && isAutoProposalEnabled = true인 템플릿만 반환
  /// 체험레슨 완료 또는 수강권 만료 시 자동 제안에 사용
  ///
  /// Copied from [autoProposalTemplates].
  AutoProposalTemplatesProvider(String teacherId)
    : this._internal(
        (ref) =>
            autoProposalTemplates(ref as AutoProposalTemplatesRef, teacherId),
        from: autoProposalTemplatesProvider,
        name: r'autoProposalTemplatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$autoProposalTemplatesHash,
        dependencies: AutoProposalTemplatesFamily._dependencies,
        allTransitiveDependencies:
            AutoProposalTemplatesFamily._allTransitiveDependencies,
        teacherId: teacherId,
      );

  AutoProposalTemplatesProvider._internal(
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
    FutureOr<List<SubscriptionTemplate>> Function(
      AutoProposalTemplatesRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AutoProposalTemplatesProvider._internal(
        (ref) => create(ref as AutoProposalTemplatesRef),
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
  AutoDisposeFutureProviderElement<List<SubscriptionTemplate>> createElement() {
    return _AutoProposalTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AutoProposalTemplatesProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AutoProposalTemplatesRef
    on AutoDisposeFutureProviderRef<List<SubscriptionTemplate>> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _AutoProposalTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionTemplate>>
    with AutoProposalTemplatesRef {
  _AutoProposalTemplatesProviderElement(super.provider);

  @override
  String get teacherId => (origin as AutoProposalTemplatesProvider).teacherId;
}

String _$academyTemplatesHash() => r'90a850a579c97fbcbdbcce8cfe056a330696d595';

/// See also [academyTemplates].
@ProviderFor(academyTemplates)
const academyTemplatesProvider = AcademyTemplatesFamily();

/// See also [academyTemplates].
class AcademyTemplatesFamily
    extends Family<AsyncValue<List<SubscriptionTemplate>>> {
  /// See also [academyTemplates].
  const AcademyTemplatesFamily();

  /// See also [academyTemplates].
  AcademyTemplatesProvider call(String academyId) {
    return AcademyTemplatesProvider(academyId);
  }

  @override
  AcademyTemplatesProvider getProviderOverride(
    covariant AcademyTemplatesProvider provider,
  ) {
    return call(provider.academyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'academyTemplatesProvider';
}

/// See also [academyTemplates].
class AcademyTemplatesProvider
    extends AutoDisposeFutureProvider<List<SubscriptionTemplate>> {
  /// See also [academyTemplates].
  AcademyTemplatesProvider(String academyId)
    : this._internal(
        (ref) => academyTemplates(ref as AcademyTemplatesRef, academyId),
        from: academyTemplatesProvider,
        name: r'academyTemplatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$academyTemplatesHash,
        dependencies: AcademyTemplatesFamily._dependencies,
        allTransitiveDependencies:
            AcademyTemplatesFamily._allTransitiveDependencies,
        academyId: academyId,
      );

  AcademyTemplatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.academyId,
  }) : super.internal();

  final String academyId;

  @override
  Override overrideWith(
    FutureOr<List<SubscriptionTemplate>> Function(AcademyTemplatesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AcademyTemplatesProvider._internal(
        (ref) => create(ref as AcademyTemplatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        academyId: academyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SubscriptionTemplate>> createElement() {
    return _AcademyTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AcademyTemplatesProvider && other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AcademyTemplatesRef
    on AutoDisposeFutureProviderRef<List<SubscriptionTemplate>> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _AcademyTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionTemplate>>
    with AcademyTemplatesRef {
  _AcademyTemplatesProviderElement(super.provider);

  @override
  String get academyId => (origin as AcademyTemplatesProvider).academyId;
}

String _$activeAcademyTemplatesHash() =>
    r'bafb62208d3f905ca70381fd3b0a12daea0e7dfa';

/// See also [activeAcademyTemplates].
@ProviderFor(activeAcademyTemplates)
const activeAcademyTemplatesProvider = ActiveAcademyTemplatesFamily();

/// See also [activeAcademyTemplates].
class ActiveAcademyTemplatesFamily
    extends Family<AsyncValue<List<SubscriptionTemplate>>> {
  /// See also [activeAcademyTemplates].
  const ActiveAcademyTemplatesFamily();

  /// See also [activeAcademyTemplates].
  ActiveAcademyTemplatesProvider call(String academyId) {
    return ActiveAcademyTemplatesProvider(academyId);
  }

  @override
  ActiveAcademyTemplatesProvider getProviderOverride(
    covariant ActiveAcademyTemplatesProvider provider,
  ) {
    return call(provider.academyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'activeAcademyTemplatesProvider';
}

/// See also [activeAcademyTemplates].
class ActiveAcademyTemplatesProvider
    extends AutoDisposeFutureProvider<List<SubscriptionTemplate>> {
  /// See also [activeAcademyTemplates].
  ActiveAcademyTemplatesProvider(String academyId)
    : this._internal(
        (ref) =>
            activeAcademyTemplates(ref as ActiveAcademyTemplatesRef, academyId),
        from: activeAcademyTemplatesProvider,
        name: r'activeAcademyTemplatesProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$activeAcademyTemplatesHash,
        dependencies: ActiveAcademyTemplatesFamily._dependencies,
        allTransitiveDependencies:
            ActiveAcademyTemplatesFamily._allTransitiveDependencies,
        academyId: academyId,
      );

  ActiveAcademyTemplatesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.academyId,
  }) : super.internal();

  final String academyId;

  @override
  Override overrideWith(
    FutureOr<List<SubscriptionTemplate>> Function(
      ActiveAcademyTemplatesRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveAcademyTemplatesProvider._internal(
        (ref) => create(ref as ActiveAcademyTemplatesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        academyId: academyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<SubscriptionTemplate>> createElement() {
    return _ActiveAcademyTemplatesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveAcademyTemplatesProvider &&
        other.academyId == academyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, academyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ActiveAcademyTemplatesRef
    on AutoDisposeFutureProviderRef<List<SubscriptionTemplate>> {
  /// The parameter `academyId` of this provider.
  String get academyId;
}

class _ActiveAcademyTemplatesProviderElement
    extends AutoDisposeFutureProviderElement<List<SubscriptionTemplate>>
    with ActiveAcademyTemplatesRef {
  _ActiveAcademyTemplatesProviderElement(super.provider);

  @override
  String get academyId => (origin as ActiveAcademyTemplatesProvider).academyId;
}

String _$subscriptionTemplateHash() =>
    r'34a2e67b87125693f6d6d259fa2e9186d3bcfc36';

/// See also [subscriptionTemplate].
@ProviderFor(subscriptionTemplate)
const subscriptionTemplateProvider = SubscriptionTemplateFamily();

/// See also [subscriptionTemplate].
class SubscriptionTemplateFamily
    extends Family<AsyncValue<SubscriptionTemplate?>> {
  /// See also [subscriptionTemplate].
  const SubscriptionTemplateFamily();

  /// See also [subscriptionTemplate].
  SubscriptionTemplateProvider call(String templateId) {
    return SubscriptionTemplateProvider(templateId);
  }

  @override
  SubscriptionTemplateProvider getProviderOverride(
    covariant SubscriptionTemplateProvider provider,
  ) {
    return call(provider.templateId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'subscriptionTemplateProvider';
}

/// See also [subscriptionTemplate].
class SubscriptionTemplateProvider
    extends AutoDisposeFutureProvider<SubscriptionTemplate?> {
  /// See also [subscriptionTemplate].
  SubscriptionTemplateProvider(String templateId)
    : this._internal(
        (ref) =>
            subscriptionTemplate(ref as SubscriptionTemplateRef, templateId),
        from: subscriptionTemplateProvider,
        name: r'subscriptionTemplateProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$subscriptionTemplateHash,
        dependencies: SubscriptionTemplateFamily._dependencies,
        allTransitiveDependencies:
            SubscriptionTemplateFamily._allTransitiveDependencies,
        templateId: templateId,
      );

  SubscriptionTemplateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.templateId,
  }) : super.internal();

  final String templateId;

  @override
  Override overrideWith(
    FutureOr<SubscriptionTemplate?> Function(SubscriptionTemplateRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SubscriptionTemplateProvider._internal(
        (ref) => create(ref as SubscriptionTemplateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        templateId: templateId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<SubscriptionTemplate?> createElement() {
    return _SubscriptionTemplateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SubscriptionTemplateProvider &&
        other.templateId == templateId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, templateId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin SubscriptionTemplateRef
    on AutoDisposeFutureProviderRef<SubscriptionTemplate?> {
  /// The parameter `templateId` of this provider.
  String get templateId;
}

class _SubscriptionTemplateProviderElement
    extends AutoDisposeFutureProviderElement<SubscriptionTemplate?>
    with SubscriptionTemplateRef {
  _SubscriptionTemplateProviderElement(super.provider);

  @override
  String get templateId => (origin as SubscriptionTemplateProvider).templateId;
}

String _$subscriptionTemplateNotifierHash() =>
    r'b8069eff8e1d7ba6e85b5a14d31e78242f396901';

/// See also [SubscriptionTemplateNotifier].
@ProviderFor(SubscriptionTemplateNotifier)
final subscriptionTemplateNotifierProvider = AutoDisposeNotifierProvider<
  SubscriptionTemplateNotifier,
  AsyncValue<SubscriptionTemplate?>
>.internal(
  SubscriptionTemplateNotifier.new,
  name: r'subscriptionTemplateNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$subscriptionTemplateNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SubscriptionTemplateNotifier =
    AutoDisposeNotifier<AsyncValue<SubscriptionTemplate?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
