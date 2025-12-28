// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inviteRepositoryHash() => r'98d033c52e9718e36a0601116ffb5ffa3f073da1';

/// Provider for invite repository
///
/// Copied from [inviteRepository].
@ProviderFor(inviteRepository)
final inviteRepositoryProvider = Provider<InviteRepository>.internal(
  inviteRepository,
  name: r'inviteRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inviteRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InviteRepositoryRef = ProviderRef<InviteRepository>;
String _$myInvitesHash() => r'bf5fa32b0c9566b5be6e40f34685d59a8c0325f3';

/// Get user's own invites
///
/// Copied from [myInvites].
@ProviderFor(myInvites)
final myInvitesProvider = AutoDisposeFutureProvider<List<Invite>>.internal(
  myInvites,
  name: r'myInvitesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myInvitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyInvitesRef = AutoDisposeFutureProviderRef<List<Invite>>;
String _$inviteByCodeHash() => r'287e2ff2419365a7b8a9e6687a787dfa68de2988';

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

/// Get invite by code
///
/// Copied from [inviteByCode].
@ProviderFor(inviteByCode)
const inviteByCodeProvider = InviteByCodeFamily();

/// Get invite by code
///
/// Copied from [inviteByCode].
class InviteByCodeFamily extends Family<AsyncValue<Invite?>> {
  /// Get invite by code
  ///
  /// Copied from [inviteByCode].
  const InviteByCodeFamily();

  /// Get invite by code
  ///
  /// Copied from [inviteByCode].
  InviteByCodeProvider call(
    String code,
  ) {
    return InviteByCodeProvider(
      code,
    );
  }

  @override
  InviteByCodeProvider getProviderOverride(
    covariant InviteByCodeProvider provider,
  ) {
    return call(
      provider.code,
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
  String? get name => r'inviteByCodeProvider';
}

/// Get invite by code
///
/// Copied from [inviteByCode].
class InviteByCodeProvider extends AutoDisposeFutureProvider<Invite?> {
  /// Get invite by code
  ///
  /// Copied from [inviteByCode].
  InviteByCodeProvider(
    String code,
  ) : this._internal(
          (ref) => inviteByCode(
            ref as InviteByCodeRef,
            code,
          ),
          from: inviteByCodeProvider,
          name: r'inviteByCodeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$inviteByCodeHash,
          dependencies: InviteByCodeFamily._dependencies,
          allTransitiveDependencies:
              InviteByCodeFamily._allTransitiveDependencies,
          code: code,
        );

  InviteByCodeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.code,
  }) : super.internal();

  final String code;

  @override
  Override overrideWith(
    FutureOr<Invite?> Function(InviteByCodeRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InviteByCodeProvider._internal(
        (ref) => create(ref as InviteByCodeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        code: code,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Invite?> createElement() {
    return _InviteByCodeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InviteByCodeProvider && other.code == code;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, code.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InviteByCodeRef on AutoDisposeFutureProviderRef<Invite?> {
  /// The parameter `code` of this provider.
  String get code;
}

class _InviteByCodeProviderElement
    extends AutoDisposeFutureProviderElement<Invite?> with InviteByCodeRef {
  _InviteByCodeProviderElement(super.provider);

  @override
  String get code => (origin as InviteByCodeProvider).code;
}

String _$pendingRequestsHash() => r'48f6153e4eef97df53fe8be57cff9d0b97590d4e';

/// Pending requests for current user (as target)
///
/// Copied from [pendingRequests].
@ProviderFor(pendingRequests)
final pendingRequestsProvider =
    AutoDisposeFutureProvider<List<ConnectionRequest>>.internal(
  pendingRequests,
  name: r'pendingRequestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingRequestsRef
    = AutoDisposeFutureProviderRef<List<ConnectionRequest>>;
String _$mySentRequestsHash() => r'6db99bedb3ee94b41342d12d22fddde7271cc591';

/// Sent requests by current user
///
/// Copied from [mySentRequests].
@ProviderFor(mySentRequests)
final mySentRequestsProvider =
    AutoDisposeFutureProvider<List<ConnectionRequest>>.internal(
  mySentRequests,
  name: r'mySentRequestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mySentRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MySentRequestsRef
    = AutoDisposeFutureProviderRef<List<ConnectionRequest>>;
String _$myConnectionsHash() => r'b6eda579c099c4363ee5b2a534226eff95c077af';

/// Current user's connections
///
/// Copied from [myConnections].
@ProviderFor(myConnections)
final myConnectionsProvider =
    AutoDisposeFutureProvider<List<Connection>>.internal(
  myConnections,
  name: r'myConnectionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myConnectionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyConnectionsRef = AutoDisposeFutureProviderRef<List<Connection>>;
String _$isConnectedWithHash() => r'a25228999de41a7194f39560e618ffe031a84811';

/// Check if connected with specific user
///
/// Copied from [isConnectedWith].
@ProviderFor(isConnectedWith)
const isConnectedWithProvider = IsConnectedWithFamily();

/// Check if connected with specific user
///
/// Copied from [isConnectedWith].
class IsConnectedWithFamily extends Family<AsyncValue<bool>> {
  /// Check if connected with specific user
  ///
  /// Copied from [isConnectedWith].
  const IsConnectedWithFamily();

  /// Check if connected with specific user
  ///
  /// Copied from [isConnectedWith].
  IsConnectedWithProvider call(
    String otherUserId,
  ) {
    return IsConnectedWithProvider(
      otherUserId,
    );
  }

  @override
  IsConnectedWithProvider getProviderOverride(
    covariant IsConnectedWithProvider provider,
  ) {
    return call(
      provider.otherUserId,
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
  String? get name => r'isConnectedWithProvider';
}

/// Check if connected with specific user
///
/// Copied from [isConnectedWith].
class IsConnectedWithProvider extends AutoDisposeFutureProvider<bool> {
  /// Check if connected with specific user
  ///
  /// Copied from [isConnectedWith].
  IsConnectedWithProvider(
    String otherUserId,
  ) : this._internal(
          (ref) => isConnectedWith(
            ref as IsConnectedWithRef,
            otherUserId,
          ),
          from: isConnectedWithProvider,
          name: r'isConnectedWithProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$isConnectedWithHash,
          dependencies: IsConnectedWithFamily._dependencies,
          allTransitiveDependencies:
              IsConnectedWithFamily._allTransitiveDependencies,
          otherUserId: otherUserId,
        );

  IsConnectedWithProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherUserId,
  }) : super.internal();

  final String otherUserId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(IsConnectedWithRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IsConnectedWithProvider._internal(
        (ref) => create(ref as IsConnectedWithRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherUserId: otherUserId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _IsConnectedWithProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IsConnectedWithProvider && other.otherUserId == otherUserId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherUserId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IsConnectedWithRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `otherUserId` of this provider.
  String get otherUserId;
}

class _IsConnectedWithProviderElement
    extends AutoDisposeFutureProviderElement<bool> with IsConnectedWithRef {
  _IsConnectedWithProviderElement(super.provider);

  @override
  String get otherUserId => (origin as IsConnectedWithProvider).otherUserId;
}

String _$pendingRequestCountHash() =>
    r'ebb5c57fff0b98efa8bd53e235d99dbb461bf4bd';

/// Pending request count (for badge display)
///
/// Copied from [pendingRequestCount].
@ProviderFor(pendingRequestCount)
final pendingRequestCountProvider = AutoDisposeFutureProvider<int>.internal(
  pendingRequestCount,
  name: r'pendingRequestCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingRequestCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingRequestCountRef = AutoDisposeFutureProviderRef<int>;
String _$currentInviteUserRoleHash() =>
    r'845aceec73d9cc5d55ca9e8e3612b0704039e2db';

/// Current user role (for testing - should come from auth)
///
/// Copied from [CurrentInviteUserRole].
@ProviderFor(CurrentInviteUserRole)
final currentInviteUserRoleProvider =
    NotifierProvider<CurrentInviteUserRole, InviteUserRole>.internal(
  CurrentInviteUserRole.new,
  name: r'currentInviteUserRoleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentInviteUserRoleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentInviteUserRole = Notifier<InviteUserRole>;
String _$currentInviteUserIdHash() =>
    r'b2c6bb4f22ae915bb195f25873c89ce87f6d0d40';

/// Current user ID (for testing - should come from auth)
///
/// Copied from [CurrentInviteUserId].
@ProviderFor(CurrentInviteUserId)
final currentInviteUserIdProvider =
    NotifierProvider<CurrentInviteUserId, String>.internal(
  CurrentInviteUserId.new,
  name: r'currentInviteUserIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentInviteUserIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentInviteUserId = Notifier<String>;
String _$inviteCreatorHash() => r'2aecea518b0f52a291ee48f0fa53eb3ca46ac8c2';

/// Create a new invite
///
/// Copied from [InviteCreator].
@ProviderFor(InviteCreator)
final inviteCreatorProvider =
    AutoDisposeNotifierProvider<InviteCreator, AsyncValue<Invite?>>.internal(
  InviteCreator.new,
  name: r'inviteCreatorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inviteCreatorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InviteCreator = AutoDisposeNotifier<AsyncValue<Invite?>>;
String _$inviteRevokerHash() => r'0eb722c9b84949e62c21c238c330349578c9aecb';

/// Revoke invite action
///
/// Copied from [InviteRevoker].
@ProviderFor(InviteRevoker)
final inviteRevokerProvider =
    AutoDisposeNotifierProvider<InviteRevoker, AsyncValue<void>>.internal(
  InviteRevoker.new,
  name: r'inviteRevokerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inviteRevokerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InviteRevoker = AutoDisposeNotifier<AsyncValue<void>>;
String _$connectionRequesterHash() =>
    r'3d5433880ff986b6016ebf264095cdbe83cc4987';

/// Create connection request from invite code
///
/// Copied from [ConnectionRequester].
@ProviderFor(ConnectionRequester)
final connectionRequesterProvider = AutoDisposeNotifierProvider<
    ConnectionRequester, AsyncValue<ConnectionRequest?>>.internal(
  ConnectionRequester.new,
  name: r'connectionRequesterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionRequesterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectionRequester
    = AutoDisposeNotifier<AsyncValue<ConnectionRequest?>>;
String _$connectionRequestResponderHash() =>
    r'8b6fa4c19a2472f655bf6c0351cb3b7fd33f873a';

/// Accept/Reject connection request
///
/// Copied from [ConnectionRequestResponder].
@ProviderFor(ConnectionRequestResponder)
final connectionRequestResponderProvider = AutoDisposeNotifierProvider<
    ConnectionRequestResponder, AsyncValue<void>>.internal(
  ConnectionRequestResponder.new,
  name: r'connectionRequestResponderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionRequestResponderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectionRequestResponder = AutoDisposeNotifier<AsyncValue<void>>;
String _$connectionManagerHash() => r'33092b55df5aeaa9441802ca7b4f24f70dc38b72';

/// Connection manager for deactivate/reactivate
///
/// Copied from [ConnectionManager].
@ProviderFor(ConnectionManager)
final connectionManagerProvider =
    AutoDisposeNotifierProvider<ConnectionManager, AsyncValue<void>>.internal(
  ConnectionManager.new,
  name: r'connectionManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectionManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ConnectionManager = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
