// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_confirmation_card_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleConfirmationCardRepositoryHash() =>
    r'4d11dd645783c33c6a8f9f34391fec4961e1940a';

/// Repository provider for schedule confirmation cards.
///
/// Copied from [scheduleConfirmationCardRepository].
@ProviderFor(scheduleConfirmationCardRepository)
final scheduleConfirmationCardRepositoryProvider =
    Provider<ScheduleConfirmationCardRepository>.internal(
  scheduleConfirmationCardRepository,
  name: r'scheduleConfirmationCardRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleConfirmationCardRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ScheduleConfirmationCardRepositoryRef
    = ProviderRef<ScheduleConfirmationCardRepository>;
String _$pendingScheduleConfirmationCardsHash() =>
    r'030d2a638ace5b2b7312abccb3ae1a4ef60f5820';

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

/// Get all pending schedule confirmation cards for a student.
///
/// Copied from [pendingScheduleConfirmationCards].
@ProviderFor(pendingScheduleConfirmationCards)
const pendingScheduleConfirmationCardsProvider =
    PendingScheduleConfirmationCardsFamily();

/// Get all pending schedule confirmation cards for a student.
///
/// Copied from [pendingScheduleConfirmationCards].
class PendingScheduleConfirmationCardsFamily
    extends Family<AsyncValue<List<ScheduleConfirmationCard>>> {
  /// Get all pending schedule confirmation cards for a student.
  ///
  /// Copied from [pendingScheduleConfirmationCards].
  const PendingScheduleConfirmationCardsFamily();

  /// Get all pending schedule confirmation cards for a student.
  ///
  /// Copied from [pendingScheduleConfirmationCards].
  PendingScheduleConfirmationCardsProvider call(
    String studentId,
  ) {
    return PendingScheduleConfirmationCardsProvider(
      studentId,
    );
  }

  @override
  PendingScheduleConfirmationCardsProvider getProviderOverride(
    covariant PendingScheduleConfirmationCardsProvider provider,
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
  String? get name => r'pendingScheduleConfirmationCardsProvider';
}

/// Get all pending schedule confirmation cards for a student.
///
/// Copied from [pendingScheduleConfirmationCards].
class PendingScheduleConfirmationCardsProvider
    extends AutoDisposeFutureProvider<List<ScheduleConfirmationCard>> {
  /// Get all pending schedule confirmation cards for a student.
  ///
  /// Copied from [pendingScheduleConfirmationCards].
  PendingScheduleConfirmationCardsProvider(
    String studentId,
  ) : this._internal(
          (ref) => pendingScheduleConfirmationCards(
            ref as PendingScheduleConfirmationCardsRef,
            studentId,
          ),
          from: pendingScheduleConfirmationCardsProvider,
          name: r'pendingScheduleConfirmationCardsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pendingScheduleConfirmationCardsHash,
          dependencies: PendingScheduleConfirmationCardsFamily._dependencies,
          allTransitiveDependencies:
              PendingScheduleConfirmationCardsFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  PendingScheduleConfirmationCardsProvider._internal(
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
    FutureOr<List<ScheduleConfirmationCard>> Function(
            PendingScheduleConfirmationCardsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PendingScheduleConfirmationCardsProvider._internal(
        (ref) => create(ref as PendingScheduleConfirmationCardsRef),
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
  AutoDisposeFutureProviderElement<List<ScheduleConfirmationCard>>
      createElement() {
    return _PendingScheduleConfirmationCardsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingScheduleConfirmationCardsProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PendingScheduleConfirmationCardsRef
    on AutoDisposeFutureProviderRef<List<ScheduleConfirmationCard>> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _PendingScheduleConfirmationCardsProviderElement
    extends AutoDisposeFutureProviderElement<List<ScheduleConfirmationCard>>
    with PendingScheduleConfirmationCardsRef {
  _PendingScheduleConfirmationCardsProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as PendingScheduleConfirmationCardsProvider).studentId;
}

String _$scheduleConfirmationCardHash() =>
    r'cceef28f1adca403b32ae51031186fa39b86c906';

/// Get a specific schedule confirmation card by ID.
///
/// Copied from [scheduleConfirmationCard].
@ProviderFor(scheduleConfirmationCard)
const scheduleConfirmationCardProvider = ScheduleConfirmationCardFamily();

/// Get a specific schedule confirmation card by ID.
///
/// Copied from [scheduleConfirmationCard].
class ScheduleConfirmationCardFamily
    extends Family<AsyncValue<ScheduleConfirmationCard?>> {
  /// Get a specific schedule confirmation card by ID.
  ///
  /// Copied from [scheduleConfirmationCard].
  const ScheduleConfirmationCardFamily();

  /// Get a specific schedule confirmation card by ID.
  ///
  /// Copied from [scheduleConfirmationCard].
  ScheduleConfirmationCardProvider call(
    String cardId,
  ) {
    return ScheduleConfirmationCardProvider(
      cardId,
    );
  }

  @override
  ScheduleConfirmationCardProvider getProviderOverride(
    covariant ScheduleConfirmationCardProvider provider,
  ) {
    return call(
      provider.cardId,
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
  String? get name => r'scheduleConfirmationCardProvider';
}

/// Get a specific schedule confirmation card by ID.
///
/// Copied from [scheduleConfirmationCard].
class ScheduleConfirmationCardProvider
    extends AutoDisposeFutureProvider<ScheduleConfirmationCard?> {
  /// Get a specific schedule confirmation card by ID.
  ///
  /// Copied from [scheduleConfirmationCard].
  ScheduleConfirmationCardProvider(
    String cardId,
  ) : this._internal(
          (ref) => scheduleConfirmationCard(
            ref as ScheduleConfirmationCardRef,
            cardId,
          ),
          from: scheduleConfirmationCardProvider,
          name: r'scheduleConfirmationCardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleConfirmationCardHash,
          dependencies: ScheduleConfirmationCardFamily._dependencies,
          allTransitiveDependencies:
              ScheduleConfirmationCardFamily._allTransitiveDependencies,
          cardId: cardId,
        );

  ScheduleConfirmationCardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.cardId,
  }) : super.internal();

  final String cardId;

  @override
  Override overrideWith(
    FutureOr<ScheduleConfirmationCard?> Function(
            ScheduleConfirmationCardRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleConfirmationCardProvider._internal(
        (ref) => create(ref as ScheduleConfirmationCardRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        cardId: cardId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ScheduleConfirmationCard?> createElement() {
    return _ScheduleConfirmationCardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleConfirmationCardProvider && other.cardId == cardId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, cardId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ScheduleConfirmationCardRef
    on AutoDisposeFutureProviderRef<ScheduleConfirmationCard?> {
  /// The parameter `cardId` of this provider.
  String get cardId;
}

class _ScheduleConfirmationCardProviderElement
    extends AutoDisposeFutureProviderElement<ScheduleConfirmationCard?>
    with ScheduleConfirmationCardRef {
  _ScheduleConfirmationCardProviderElement(super.provider);

  @override
  String get cardId => (origin as ScheduleConfirmationCardProvider).cardId;
}

String _$scheduleConfirmationCardNotifierHash() =>
    r'acfa0549ad53b4aed6855d6cfb0af1301e792305';

/// Notifier for managing schedule confirmation card actions.
///
/// Copied from [ScheduleConfirmationCardNotifier].
@ProviderFor(ScheduleConfirmationCardNotifier)
final scheduleConfirmationCardNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleConfirmationCardNotifier,
        void>.internal(
  ScheduleConfirmationCardNotifier.new,
  name: r'scheduleConfirmationCardNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleConfirmationCardNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScheduleConfirmationCardNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
