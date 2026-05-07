// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'piece_crud_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$piecesHash() => r'18a0e5dac8b82c6d6cd97cea980bcaac4b81731a';

/// All pieces provider (library)
///
/// Copied from [pieces].
@ProviderFor(pieces)
final piecesProvider = FutureProvider<List<Piece>>.internal(
  pieces,
  name: r'piecesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$piecesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PiecesRef = FutureProviderRef<List<Piece>>;
String _$pieceHash() => r'0262ec158b5c05ca78e504798e0ef74cb49c1410';

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

/// Single piece provider
///
/// Copied from [piece].
@ProviderFor(piece)
const pieceProvider = PieceFamily();

/// Single piece provider
///
/// Copied from [piece].
class PieceFamily extends Family<AsyncValue<Piece?>> {
  /// Single piece provider
  ///
  /// Copied from [piece].
  const PieceFamily();

  /// Single piece provider
  ///
  /// Copied from [piece].
  PieceProvider call(
    String id,
  ) {
    return PieceProvider(
      id,
    );
  }

  @override
  PieceProvider getProviderOverride(
    covariant PieceProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'pieceProvider';
}

/// Single piece provider
///
/// Copied from [piece].
class PieceProvider extends FutureProvider<Piece?> {
  /// Single piece provider
  ///
  /// Copied from [piece].
  PieceProvider(
    String id,
  ) : this._internal(
          (ref) => piece(
            ref as PieceRef,
            id,
          ),
          from: pieceProvider,
          name: r'pieceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$pieceHash,
          dependencies: PieceFamily._dependencies,
          allTransitiveDependencies: PieceFamily._allTransitiveDependencies,
          id: id,
        );

  PieceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Piece?> Function(PieceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PieceProvider._internal(
        (ref) => create(ref as PieceRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  FutureProviderElement<Piece?> createElement() {
    return _PieceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PieceProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PieceRef on FutureProviderRef<Piece?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _PieceProviderElement extends FutureProviderElement<Piece?>
    with PieceRef {
  _PieceProviderElement(super.provider);

  @override
  String get id => (origin as PieceProvider).id;
}

String _$filteredPiecesHash() => r'65d594d2beba246e45bbb4de322c314b5f70bc49';

/// See also [filteredPieces].
@ProviderFor(filteredPieces)
final filteredPiecesProvider = FutureProvider<List<Piece>>.internal(
  filteredPieces,
  name: r'filteredPiecesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredPiecesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FilteredPiecesRef = FutureProviderRef<List<Piece>>;
String _$studentRepertoireHash() => r'd460125c9c6715efc02a083eba2f87a69cea730d';

/// Student repertoire provider
///
/// Copied from [studentRepertoire].
@ProviderFor(studentRepertoire)
const studentRepertoireProvider = StudentRepertoireFamily();

/// Student repertoire provider
///
/// Copied from [studentRepertoire].
class StudentRepertoireFamily extends Family<AsyncValue<Repertoire>> {
  /// Student repertoire provider
  ///
  /// Copied from [studentRepertoire].
  const StudentRepertoireFamily();

  /// Student repertoire provider
  ///
  /// Copied from [studentRepertoire].
  StudentRepertoireProvider call(
    String studentId,
  ) {
    return StudentRepertoireProvider(
      studentId,
    );
  }

  @override
  StudentRepertoireProvider getProviderOverride(
    covariant StudentRepertoireProvider provider,
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
  String? get name => r'studentRepertoireProvider';
}

/// Student repertoire provider
///
/// Copied from [studentRepertoire].
class StudentRepertoireProvider extends FutureProvider<Repertoire> {
  /// Student repertoire provider
  ///
  /// Copied from [studentRepertoire].
  StudentRepertoireProvider(
    String studentId,
  ) : this._internal(
          (ref) => studentRepertoire(
            ref as StudentRepertoireRef,
            studentId,
          ),
          from: studentRepertoireProvider,
          name: r'studentRepertoireProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentRepertoireHash,
          dependencies: StudentRepertoireFamily._dependencies,
          allTransitiveDependencies:
              StudentRepertoireFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentRepertoireProvider._internal(
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
    FutureOr<Repertoire> Function(StudentRepertoireRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: StudentRepertoireProvider._internal(
        (ref) => create(ref as StudentRepertoireRef),
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
  FutureProviderElement<Repertoire> createElement() {
    return _StudentRepertoireProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentRepertoireProvider && other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentRepertoireRef on FutureProviderRef<Repertoire> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentRepertoireProviderElement
    extends FutureProviderElement<Repertoire> with StudentRepertoireRef {
  _StudentRepertoireProviderElement(super.provider);

  @override
  String get studentId => (origin as StudentRepertoireProvider).studentId;
}

String _$pieceSearchQueryHash() => r'55769e6c42264a7e032dca0a683d6f43565c5bed';

/// Search pieces provider
///
/// Copied from [PieceSearchQuery].
@ProviderFor(PieceSearchQuery)
final pieceSearchQueryProvider =
    NotifierProvider<PieceSearchQuery, String>.internal(
  PieceSearchQuery.new,
  name: r'pieceSearchQueryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pieceSearchQueryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PieceSearchQuery = Notifier<String>;
String _$piecesNotifierHash() => r'309b095366713ebb66a8123d9acbe7115bd8ec60';

/// Piece library notifier for CRUD operations
///
/// Copied from [PiecesNotifier].
@ProviderFor(PiecesNotifier)
final piecesNotifierProvider =
    AsyncNotifierProvider<PiecesNotifier, List<Piece>>.internal(
  PiecesNotifier.new,
  name: r'piecesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$piecesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PiecesNotifier = AsyncNotifier<List<Piece>>;
String _$studentRepertoireNotifierHash() =>
    r'bfdba12f46d89de0b9984e542ccb4cce8a94609d';

abstract class _$StudentRepertoireNotifier
    extends BuildlessAsyncNotifier<Repertoire> {
  late final String studentId;

  FutureOr<Repertoire> build(
    String studentId,
  );
}

/// Student repertoire notifier
///
/// Copied from [StudentRepertoireNotifier].
@ProviderFor(StudentRepertoireNotifier)
const studentRepertoireNotifierProvider = StudentRepertoireNotifierFamily();

/// Student repertoire notifier
///
/// Copied from [StudentRepertoireNotifier].
class StudentRepertoireNotifierFamily extends Family<AsyncValue<Repertoire>> {
  /// Student repertoire notifier
  ///
  /// Copied from [StudentRepertoireNotifier].
  const StudentRepertoireNotifierFamily();

  /// Student repertoire notifier
  ///
  /// Copied from [StudentRepertoireNotifier].
  StudentRepertoireNotifierProvider call(
    String studentId,
  ) {
    return StudentRepertoireNotifierProvider(
      studentId,
    );
  }

  @override
  StudentRepertoireNotifierProvider getProviderOverride(
    covariant StudentRepertoireNotifierProvider provider,
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
  String? get name => r'studentRepertoireNotifierProvider';
}

/// Student repertoire notifier
///
/// Copied from [StudentRepertoireNotifier].
class StudentRepertoireNotifierProvider
    extends AsyncNotifierProviderImpl<StudentRepertoireNotifier, Repertoire> {
  /// Student repertoire notifier
  ///
  /// Copied from [StudentRepertoireNotifier].
  StudentRepertoireNotifierProvider(
    String studentId,
  ) : this._internal(
          () => StudentRepertoireNotifier()..studentId = studentId,
          from: studentRepertoireNotifierProvider,
          name: r'studentRepertoireNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentRepertoireNotifierHash,
          dependencies: StudentRepertoireNotifierFamily._dependencies,
          allTransitiveDependencies:
              StudentRepertoireNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentRepertoireNotifierProvider._internal(
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
  FutureOr<Repertoire> runNotifierBuild(
    covariant StudentRepertoireNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(StudentRepertoireNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudentRepertoireNotifierProvider._internal(
        () => create()..studentId = studentId,
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
  AsyncNotifierProviderElement<StudentRepertoireNotifier, Repertoire>
      createElement() {
    return _StudentRepertoireNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentRepertoireNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin StudentRepertoireNotifierRef on AsyncNotifierProviderRef<Repertoire> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentRepertoireNotifierProviderElement
    extends AsyncNotifierProviderElement<StudentRepertoireNotifier, Repertoire>
    with StudentRepertoireNotifierRef {
  _StudentRepertoireNotifierProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentRepertoireNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
