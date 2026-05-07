// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_privacy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$journalPrivacySettingHash() =>
    r'ffe32dccdd3348210c799bf4b50ca1e290cf20d3';

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

abstract class _$JournalPrivacySetting
    extends BuildlessAsyncNotifier<JournalPrivacy> {
  late final String studentId;

  FutureOr<JournalPrivacy> build(
    String studentId,
  );
}

/// See also [JournalPrivacySetting].
@ProviderFor(JournalPrivacySetting)
const journalPrivacySettingProvider = JournalPrivacySettingFamily();

/// See also [JournalPrivacySetting].
class JournalPrivacySettingFamily extends Family<AsyncValue<JournalPrivacy>> {
  /// See also [JournalPrivacySetting].
  const JournalPrivacySettingFamily();

  /// See also [JournalPrivacySetting].
  JournalPrivacySettingProvider call(
    String studentId,
  ) {
    return JournalPrivacySettingProvider(
      studentId,
    );
  }

  @override
  JournalPrivacySettingProvider getProviderOverride(
    covariant JournalPrivacySettingProvider provider,
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
  String? get name => r'journalPrivacySettingProvider';
}

/// See also [JournalPrivacySetting].
class JournalPrivacySettingProvider
    extends AsyncNotifierProviderImpl<JournalPrivacySetting, JournalPrivacy> {
  /// See also [JournalPrivacySetting].
  JournalPrivacySettingProvider(
    String studentId,
  ) : this._internal(
          () => JournalPrivacySetting()..studentId = studentId,
          from: journalPrivacySettingProvider,
          name: r'journalPrivacySettingProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$journalPrivacySettingHash,
          dependencies: JournalPrivacySettingFamily._dependencies,
          allTransitiveDependencies:
              JournalPrivacySettingFamily._allTransitiveDependencies,
          studentId: studentId,
        );

  JournalPrivacySettingProvider._internal(
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
  FutureOr<JournalPrivacy> runNotifierBuild(
    covariant JournalPrivacySetting notifier,
  ) {
    return notifier.build(
      studentId,
    );
  }

  @override
  Override overrideWith(JournalPrivacySetting Function() create) {
    return ProviderOverride(
      origin: this,
      override: JournalPrivacySettingProvider._internal(
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
  AsyncNotifierProviderElement<JournalPrivacySetting, JournalPrivacy>
      createElement() {
    return _JournalPrivacySettingProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalPrivacySettingProvider &&
        other.studentId == studentId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, studentId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin JournalPrivacySettingRef on AsyncNotifierProviderRef<JournalPrivacy> {
  /// The parameter `studentId` of this provider.
  String get studentId;
}

class _JournalPrivacySettingProviderElement
    extends AsyncNotifierProviderElement<JournalPrivacySetting, JournalPrivacy>
    with JournalPrivacySettingRef {
  _JournalPrivacySettingProviderElement(super.provider);

  @override
  String get studentId => (origin as JournalPrivacySettingProvider).studentId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
