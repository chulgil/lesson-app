// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proposal_draft_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$proposalDraftStorageHash() =>
    r'5b27b22ff6250002abe83357cfbcc4e8b111194d';

/// Application-layer storage provider for subscription proposal drafts (#695).
///
/// Spec: docs/specs/user/phone_verification_policy.md §4.4 — "나중에" saves
/// the in-progress form to local Hive storage. The storage instance is kept
/// alive; individual load/save/delete operations are called imperatively
/// from the screen and the actions mixin.
///
/// Copied from [proposalDraftStorage].
@ProviderFor(proposalDraftStorage)
final proposalDraftStorageProvider = Provider<ProposalDraftStorage>.internal(
  proposalDraftStorage,
  name: r'proposalDraftStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proposalDraftStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ProposalDraftStorageRef = ProviderRef<ProposalDraftStorage>;
String _$proposalDraftHash() => r'3e89d7571a3e81a31723d7f02ee5d46b42fac13a';

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

/// Loads the current draft for (userId, studentId).
/// Returns `null` if no valid (non-expired) draft exists.
///
/// Side-effect: when an expired draft is auto-discarded by this load, the
/// `subscription.draft_expired` metric event is recorded (spec §5.5).
///
/// Copied from [proposalDraft].
@ProviderFor(proposalDraft)
const proposalDraftProvider = ProposalDraftFamily();

/// Loads the current draft for (userId, studentId).
/// Returns `null` if no valid (non-expired) draft exists.
///
/// Side-effect: when an expired draft is auto-discarded by this load, the
/// `subscription.draft_expired` metric event is recorded (spec §5.5).
///
/// Copied from [proposalDraft].
class ProposalDraftFamily extends Family<AsyncValue<ProposalDraft?>> {
  /// Loads the current draft for (userId, studentId).
  /// Returns `null` if no valid (non-expired) draft exists.
  ///
  /// Side-effect: when an expired draft is auto-discarded by this load, the
  /// `subscription.draft_expired` metric event is recorded (spec §5.5).
  ///
  /// Copied from [proposalDraft].
  const ProposalDraftFamily();

  /// Loads the current draft for (userId, studentId).
  /// Returns `null` if no valid (non-expired) draft exists.
  ///
  /// Side-effect: when an expired draft is auto-discarded by this load, the
  /// `subscription.draft_expired` metric event is recorded (spec §5.5).
  ///
  /// Copied from [proposalDraft].
  ProposalDraftProvider call(
    String userId,
    String studentId,
  ) {
    return ProposalDraftProvider(
      userId,
      studentId,
    );
  }

  @override
  ProposalDraftProvider getProviderOverride(
    covariant ProposalDraftProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'proposalDraftProvider';
}

/// Loads the current draft for (userId, studentId).
/// Returns `null` if no valid (non-expired) draft exists.
///
/// Side-effect: when an expired draft is auto-discarded by this load, the
/// `subscription.draft_expired` metric event is recorded (spec §5.5).
///
/// Copied from [proposalDraft].
class ProposalDraftProvider extends AutoDisposeFutureProvider<ProposalDraft?> {
  /// Loads the current draft for (userId, studentId).
  /// Returns `null` if no valid (non-expired) draft exists.
  ///
  /// Side-effect: when an expired draft is auto-discarded by this load, the
  /// `subscription.draft_expired` metric event is recorded (spec §5.5).
  ///
  /// Copied from [proposalDraft].
  ProposalDraftProvider(
    String userId,
    String studentId,
  ) : this._internal(
          (ref) => proposalDraft(
            ref as ProposalDraftRef,
            userId,
            studentId,
          ),
          from: proposalDraftProvider,
          name: r'proposalDraftProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$proposalDraftHash,
          dependencies: ProposalDraftFamily._dependencies,
          allTransitiveDependencies:
              ProposalDraftFamily._allTransitiveDependencies,
          userId: userId,
          studentId: studentId,
        );

  ProposalDraftProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.studentId,
  }) : super.internal();

  final String userId;
  final String studentId;

  @override
  Override overrideWith(
    FutureOr<ProposalDraft?> Function(ProposalDraftRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProposalDraftProvider._internal(
        (ref) => create(ref as ProposalDraftRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        studentId: studentId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProposalDraft?> createElement() {
    return _ProposalDraftProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProposalDraftProvider &&
        other.userId == userId &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ProposalDraftRef on AutoDisposeFutureProviderRef<ProposalDraft?> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _ProposalDraftProviderElement
    extends AutoDisposeFutureProviderElement<ProposalDraft?>
    with ProposalDraftRef {
  _ProposalDraftProviderElement(super.provider);

  @override
  String get userId => (origin as ProposalDraftProvider).userId;
  @override
  String get studentId => (origin as ProposalDraftProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
