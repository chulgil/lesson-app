// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$studentProfileImageNotifierHash() =>
    r'befedb7d3add005679672d70d56658ea0cad11ce';

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

abstract class _$StudentProfileImageNotifier
    extends BuildlessAutoDisposeAsyncNotifier<String?> {
  late final String studentId;

  FutureOr<String?> build(
    String studentId,
  );
}

/// Student profile image state.
///
/// Copied from [StudentProfileImageNotifier].
@ProviderFor(StudentProfileImageNotifier)
const studentProfileImageNotifierProvider = StudentProfileImageNotifierFamily();

/// Student profile image state.
///
/// Copied from [StudentProfileImageNotifier].
class StudentProfileImageNotifierFamily extends Family<AsyncValue<String?>> {
  /// Student profile image state.
  ///
  /// Copied from [StudentProfileImageNotifier].
  const StudentProfileImageNotifierFamily();

  /// Student profile image state.
  ///
  /// Copied from [StudentProfileImageNotifier].
  StudentProfileImageNotifierProvider call(
    String studentId,
  ) {
    return StudentProfileImageNotifierProvider(
      studentId,
    );
  }

  @override
  StudentProfileImageNotifierProvider getProviderOverride(
    covariant StudentProfileImageNotifierProvider provider,
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
  String? get name => r'studentProfileImageNotifierProvider';
}

/// Student profile image state.
///
/// Copied from [StudentProfileImageNotifier].
class StudentProfileImageNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<StudentProfileImageNotifier,
        String?> {
  /// Student profile image state.
  ///
  /// Copied from [StudentProfileImageNotifier].
  StudentProfileImageNotifierProvider(
    String studentId,
  ) : this._internal(
          () => StudentProfileImageNotifier()..studentId = studentId,
          from: studentProfileImageNotifierProvider,
          name: r'studentProfileImageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentProfileImageNotifierHash,
          dependencies: StudentProfileImageNotifierFamily._dependencies,
          allTransitiveDependencies:
              StudentProfileImageNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentProfileImageNotifierProvider._internal(
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
  FutureOr<String?> runNotifierBuild(
    covariant StudentProfileImageNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(StudentProfileImageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudentProfileImageNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<StudentProfileImageNotifier, String?>
      createElement() {
    return _StudentProfileImageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentProfileImageNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentProfileImageNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<String?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentProfileImageNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<StudentProfileImageNotifier,
        String?> with StudentProfileImageNotifierRef {
  _StudentProfileImageNotifierProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentProfileImageNotifierProvider).studentId;
}

String _$studentBackgroundImageNotifierHash() =>
    r'ffb72dba4e0de50e1393d0910b759bc3d567848a';

abstract class _$StudentBackgroundImageNotifier
    extends BuildlessAutoDisposeAsyncNotifier<String?> {
  late final String studentId;

  FutureOr<String?> build(
    String studentId,
  );
}

/// Student background image state.
///
/// Copied from [StudentBackgroundImageNotifier].
@ProviderFor(StudentBackgroundImageNotifier)
const studentBackgroundImageNotifierProvider =
    StudentBackgroundImageNotifierFamily();

/// Student background image state.
///
/// Copied from [StudentBackgroundImageNotifier].
class StudentBackgroundImageNotifierFamily extends Family<AsyncValue<String?>> {
  /// Student background image state.
  ///
  /// Copied from [StudentBackgroundImageNotifier].
  const StudentBackgroundImageNotifierFamily();

  /// Student background image state.
  ///
  /// Copied from [StudentBackgroundImageNotifier].
  StudentBackgroundImageNotifierProvider call(
    String studentId,
  ) {
    return StudentBackgroundImageNotifierProvider(
      studentId,
    );
  }

  @override
  StudentBackgroundImageNotifierProvider getProviderOverride(
    covariant StudentBackgroundImageNotifierProvider provider,
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
  String? get name => r'studentBackgroundImageNotifierProvider';
}

/// Student background image state.
///
/// Copied from [StudentBackgroundImageNotifier].
class StudentBackgroundImageNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<StudentBackgroundImageNotifier,
        String?> {
  /// Student background image state.
  ///
  /// Copied from [StudentBackgroundImageNotifier].
  StudentBackgroundImageNotifierProvider(
    String studentId,
  ) : this._internal(
          () => StudentBackgroundImageNotifier()..studentId = studentId,
          from: studentBackgroundImageNotifierProvider,
          name: r'studentBackgroundImageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$studentBackgroundImageNotifierHash,
          dependencies: StudentBackgroundImageNotifierFamily._dependencies,
          allTransitiveDependencies:
              StudentBackgroundImageNotifierFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  StudentBackgroundImageNotifierProvider._internal(
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
  FutureOr<String?> runNotifierBuild(
    covariant StudentBackgroundImageNotifier notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(StudentBackgroundImageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: StudentBackgroundImageNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<StudentBackgroundImageNotifier,
      String?> createElement() {
    return _StudentBackgroundImageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is StudentBackgroundImageNotifierProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin StudentBackgroundImageNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<String?> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _StudentBackgroundImageNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<
        StudentBackgroundImageNotifier,
        String?> with StudentBackgroundImageNotifierRef {
  _StudentBackgroundImageNotifierProviderElement(super.provider);

  @override
  String get studentId =>
      (origin as StudentBackgroundImageNotifierProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
