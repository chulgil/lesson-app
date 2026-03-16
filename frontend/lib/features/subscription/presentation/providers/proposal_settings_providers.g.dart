// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$proposalSettingsRepositoryHash() =>
    r'41dc7b1a3b2d8707a20295ac098ed0ea42dd5ef5';

/// See also [proposalSettingsRepository].
@ProviderFor(proposalSettingsRepository)
final proposalSettingsRepositoryProvider =
    Provider<ProposalSettingsRepository>.internal(
  proposalSettingsRepository,
  name: r'proposalSettingsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proposalSettingsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProposalSettingsRepositoryRef = ProviderRef<ProposalSettingsRepository>;
String _$teacherProposalSettingsHash() =>
    r'2f9de50164129bf0fa0d3a673027a5ec4ec4c975';

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

/// See also [teacherProposalSettings].
@ProviderFor(teacherProposalSettings)
const teacherProposalSettingsProvider = TeacherProposalSettingsFamily();

/// See also [teacherProposalSettings].
class TeacherProposalSettingsFamily
    extends Family<AsyncValue<ProposalSettings>> {
  /// See also [teacherProposalSettings].
  const TeacherProposalSettingsFamily();

  /// See also [teacherProposalSettings].
  TeacherProposalSettingsProvider call(
    String teacherId,
  ) {
    return TeacherProposalSettingsProvider(
      teacherId,
    );
  }

  @override
  TeacherProposalSettingsProvider getProviderOverride(
    covariant TeacherProposalSettingsProvider provider,
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
  String? get name => r'teacherProposalSettingsProvider';
}

/// See also [teacherProposalSettings].
class TeacherProposalSettingsProvider
    extends AutoDisposeFutureProvider<ProposalSettings> {
  /// See also [teacherProposalSettings].
  TeacherProposalSettingsProvider(
    String teacherId,
  ) : this._internal(
          (ref) => teacherProposalSettings(
            ref as TeacherProposalSettingsRef,
            teacherId,
          ),
          from: teacherProposalSettingsProvider,
          name: r'teacherProposalSettingsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$teacherProposalSettingsHash,
          dependencies: TeacherProposalSettingsFamily._dependencies,
          allTransitiveDependencies:
              TeacherProposalSettingsFamily._allTransitiveDependencies,
          teacherId: teacherId,
        );

  TeacherProposalSettingsProvider._internal(
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
    FutureOr<ProposalSettings> Function(TeacherProposalSettingsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TeacherProposalSettingsProvider._internal(
        (ref) => create(ref as TeacherProposalSettingsRef),
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
  AutoDisposeFutureProviderElement<ProposalSettings> createElement() {
    return _TeacherProposalSettingsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeacherProposalSettingsProvider &&
        other.teacherId == teacherId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teacherId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeacherProposalSettingsRef
    on AutoDisposeFutureProviderRef<ProposalSettings> {
  /// The parameter `teacherId` of this provider.
  String get teacherId;
}

class _TeacherProposalSettingsProviderElement
    extends AutoDisposeFutureProviderElement<ProposalSettings>
    with TeacherProposalSettingsRef {
  _TeacherProposalSettingsProviderElement(super.provider);

  @override
  String get teacherId => (origin as TeacherProposalSettingsProvider).teacherId;
}

String _$proposalSettingsNotifierHash() =>
    r'aac884df2c65b31a035494de752c297f4b619840';

/// See also [ProposalSettingsNotifier].
@ProviderFor(ProposalSettingsNotifier)
final proposalSettingsNotifierProvider = AutoDisposeNotifierProvider<
    ProposalSettingsNotifier, AsyncValue<ProposalSettings?>>.internal(
  ProposalSettingsNotifier.new,
  name: r'proposalSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proposalSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProposalSettingsNotifier
    = AutoDisposeNotifier<AsyncValue<ProposalSettings?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
