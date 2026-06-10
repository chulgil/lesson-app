// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inviteRepositoryHash() => r'72b15bea199bfddd7699f6a4a633bc194be669f8';

/// Provider for invite repository - switches between Mock and Remote.
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

typedef InviteRepositoryRef = ProviderRef<InviteRepository>;
String _$myInvitesHash() => r'fd327fbdb2c1093102f9a8b2f4f7bfbaf4227918';

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

typedef MyInvitesRef = AutoDisposeFutureProviderRef<List<Invite>>;
String _$inviteByCodeHash() => r'22b5b8d00538ea7ea96282001966e9daac1f48d3';

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

String _$pendingRequestsHash() => r'a3ef36d05976f36aeb4e74b92d1d1495a73aca39';

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

typedef PendingRequestsRef
    = AutoDisposeFutureProviderRef<List<ConnectionRequest>>;
String _$mySentRequestsHash() => r'74b4db0658530fd9b332f63de0981845d4a2bff0';

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

typedef MySentRequestsRef
    = AutoDisposeFutureProviderRef<List<ConnectionRequest>>;
String _$myConnectionsHash() => r'75d96c285cafbcd6b48aeabc73cc0957a3195954';

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

typedef MyConnectionsRef = AutoDisposeFutureProviderRef<List<Connection>>;
String _$isConnectedWithHash() => r'4656313139917d552c5ff46bf2fa877a13068e2b';

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
    r'b44dc7913bb7fb8c157d808abf6969009970f848';

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

typedef PendingRequestCountRef = AutoDisposeFutureProviderRef<int>;
String _$myDisconnectedConnectionsHash() =>
    r'0581ae9bb5cd67574ec793ca2ea6b3df576ffedd';

/// Get inactive/disconnected connections for current user
/// Used in teacher search to show "이전에 레슨했어요" teachers
///
/// Copied from [myDisconnectedConnections].
@ProviderFor(myDisconnectedConnections)
final myDisconnectedConnectionsProvider =
    AutoDisposeFutureProvider<List<Connection>>.internal(
  myDisconnectedConnections,
  name: r'myDisconnectedConnectionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myDisconnectedConnectionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MyDisconnectedConnectionsRef
    = AutoDisposeFutureProviderRef<List<Connection>>;
String _$previousTeacherIdsHash() =>
    r'5e52adaa777b08a589860f95074e9c94d62d5109';

/// Get teacher IDs that the current student previously had lessons with
///
/// Copied from [previousTeacherIds].
@ProviderFor(previousTeacherIds)
final previousTeacherIdsProvider =
    AutoDisposeFutureProvider<Set<String>>.internal(
  previousTeacherIds,
  name: r'previousTeacherIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$previousTeacherIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PreviousTeacherIdsRef = AutoDisposeFutureProviderRef<Set<String>>;
String _$currentInviteUserRoleHash() =>
    r'588b216dacf821ea8d22a0a20f104b36a1e0303c';

/// Current user role - synced with app's role system
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
    r'34b17e1b79a3010ede127f97a4767d5fcad2ae55';

/// Current user ID - synced with app's user system
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
    r'a21ceecfe78ab395858bb03aaf860c7dc9aa795c';

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
    r'1aafc2940c65416435865a2caabdc704a0f592b9';

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
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
