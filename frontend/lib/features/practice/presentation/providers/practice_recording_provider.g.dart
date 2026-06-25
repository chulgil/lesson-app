// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_recording_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$practiceRecordingServiceHash() =>
    r'253d7a6acabab71a819f7040324bed04edd281ea';

/// P1: 모든 연습 evidence 의 단일 진입점 서비스 provider.
///
/// 4 경로 wiring (메트로놈/튜너/YouTube/녹음/수동) 은 본 provider 를 통해
/// service 에 접근. 의존성: growthHeatmapRepository + studentQuestRepository.
///
/// Copied from [practiceRecordingService].
@ProviderFor(practiceRecordingService)
final practiceRecordingServiceProvider =
    Provider<PracticeRecordingService>.internal(
  practiceRecordingService,
  name: r'practiceRecordingServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceRecordingServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeRecordingServiceRef = ProviderRef<PracticeRecordingService>;
String _$practiceSourceLoggersHash() =>
    r'faf463095fb01ce199b339086adb20031c56adb1';

/// 4 경로 wiring 의 thin helper.
///
/// Copied from [practiceSourceLoggers].
@ProviderFor(practiceSourceLoggers)
final practiceSourceLoggersProvider = Provider<PracticeSourceLoggers>.internal(
  practiceSourceLoggers,
  name: r'practiceSourceLoggersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$practiceSourceLoggersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PracticeSourceLoggersRef = ProviderRef<PracticeSourceLoggers>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
