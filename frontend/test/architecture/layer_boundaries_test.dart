import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature layer boundaries', () {
    test('domain and data layers do not import presentation code', () {
      final violations = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainOrDataFile(file.path)) continue;

        final forbiddenImports =
            _importOrExportUris(file).where(_pointsToPresentation).toList();
        if (forbiddenImports.isNotEmpty) {
          violations.add('${file.path}: ${forbiddenImports.join(', ')}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain/data layers must not depend on presentation widgets or providers.',
      );
    });

    test('domain layer does not import or export data implementations', () {
      final violations = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainFile(file.path)) continue;

        final forbiddenUris =
            _importOrExportUris(file).where(_pointsToData).toList();
        if (forbiddenUris.isNotEmpty) {
          violations.add('${file.path}: ${forbiddenUris.join(', ')}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain files may define repository contracts, but must not expose data-layer implementations.',
      );
    });

    test('domain services do not import framework drivers or API clients', () {
      final violations = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainServiceFile(file.path)) continue;

        final forbiddenUris =
            _importOrExportUris(file).where(_pointsToInfrastructure).toList();
        if (forbiddenUris.isNotEmpty) {
          violations.add('${file.path}: ${forbiddenUris.join(', ')}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain services must stay pure. Platform, Firebase, persistence, environment, and API client adapters belong in data/core adapters.',
      );
    });

    test('domain layer does not import Flutter framework libraries', () {
      final currentImports = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainFile(file.path)) continue;

        final flutterImports =
            _importOrExportUris(file).where(_pointsToFlutterFramework).toList();
        for (final uri in flutterImports) {
          currentImports.add('${file.path}: $uri');
        }
      }
      currentImports.sort();

      final unexpectedImports =
          currentImports
              .where(
                (dependency) =>
                    !_legacyDomainFlutterFrameworkImportExceptions.contains(
                      dependency,
                    ),
              )
              .toList();
      final staleBaseline =
          _legacyDomainFlutterFrameworkImportExceptions
              .where((dependency) => !currentImports.contains(dependency))
              .toList();

      expect(
        unexpectedImports,
        isEmpty,
        reason:
            'Domain files must stay independent from Flutter framework libraries. Move UI types to presentation or replace them with pure Dart domain values.',
      );
      expect(
        staleBaseline,
        isEmpty,
        reason:
            'When a legacy domain Flutter import is removed, update this baseline so the remaining debt stays visible.',
      );
    });

    test('data layer does not import Flutter framework libraries', () {
      final currentImports = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDataFile(file.path)) continue;

        final flutterImports =
            _importOrExportUris(file).where(_pointsToFlutterFramework).toList();
        for (final uri in flutterImports) {
          currentImports.add('${file.path}: $uri');
        }
      }
      currentImports.sort();

      final unexpectedImports =
          currentImports
              .where(
                (dependency) =>
                    !_legacyDataFlutterFrameworkImportExceptions.contains(
                      dependency,
                    ),
              )
              .toList();
      final staleBaseline =
          _legacyDataFlutterFrameworkImportExceptions
              .where((dependency) => !currentImports.contains(dependency))
              .toList();

      expect(
        unexpectedImports,
        isEmpty,
        reason:
            'Data files must stay independent from Flutter framework libraries. Move UI types to presentation or replace them with pure Dart data values.',
      );
      expect(
        staleBaseline,
        isEmpty,
        reason:
            'When a legacy data Flutter import is removed, update this baseline so the remaining debt stays visible.',
      );
    });

    test(
      'core booking model layer does not import Flutter framework libraries',
      () {
        final currentImports = <String>[];

        for (final file in _dartFilesUnder('lib/core/booking')) {
          if (_isPresentationFile(file.path)) continue;

          final flutterImports =
              _importOrExportUris(
                file,
              ).where(_pointsToFlutterFramework).toList();
          for (final uri in flutterImports) {
            currentImports.add('${file.path}: $uri');
          }
        }
        currentImports.sort();

        final unexpectedImports =
            currentImports
                .where(
                  (dependency) =>
                      !_legacyCoreBookingFlutterFrameworkImportExceptions
                          .contains(dependency),
                )
                .toList();
        final staleBaseline =
            _legacyCoreBookingFlutterFrameworkImportExceptions
                .where((dependency) => !currentImports.contains(dependency))
                .toList();

        expect(
          unexpectedImports,
          isEmpty,
          reason:
              'Core booking models and repositories must not grow Flutter framework dependencies. Keep Flutter types in presentation adapters or explicit legacy migrations.',
        );
        expect(
          staleBaseline,
          isEmpty,
          reason:
              'When a legacy core booking Flutter import is removed, update this baseline so the remaining debt stays visible.',
        );
      },
    );

    test('core booking model layer does not expose presentation visuals', () {
      final violations = <String>[];

      for (final file in _dartFilesUnder('lib/core/booking')) {
        if (_isPresentationFile(file.path)) continue;

        final source = file.readAsStringSync();
        final exposesVisuals =
            RegExp(r'\b(?:Color|IconData)\s+get\s+\w+\b').hasMatch(source) ||
            RegExp(r'\b(?:Icons|AppColors)\s*\.').hasMatch(source);
        if (exposesVisuals) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Core booking models must expose semantic state only. Put colors, icons, and design-system mapping in presentation extensions.',
      );
    });

    test('domain layer does not add new Hive persistence annotations', () {
      final violations = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainFile(file.path)) continue;
        if (_legacyDomainHivePersistenceExceptions.contains(file.path)) {
          continue;
        }

        final source = file.readAsStringSync();
        final hasHivePersistence =
            _importOrExportUris(file).any(_pointsToHive) ||
            RegExp(r'@\s*Hive(?:Type|Field)\b').hasMatch(source) ||
            RegExp(r'\bextends\s+HiveObject\b').hasMatch(source);
        if (hasHivePersistence) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'New domain models must not depend on Hive persistence annotations. Keep storage adapters in data/core layers, or add a deliberate legacy exception while migrating old models.',
      );
    });

    test('domain layer does not import localization strings', () {
      final currentDependencies = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        if (!_isFeatureDomainFile(file.path)) continue;

        currentDependencies.addAll(_domainLocalizationDependencies(file));
      }
      currentDependencies.sort();

      final unexpectedDependencies =
          currentDependencies
              .where(
                (dependency) =>
                    !_legacyDomainLocalizationDependencies.contains(dependency),
              )
              .toList();
      final staleBaseline =
          _legacyDomainLocalizationDependencies
              .where((dependency) => !currentDependencies.contains(dependency))
              .toList();

      expect(
        unexpectedDependencies,
        isEmpty,
        reason:
            'Domain files must not depend on core/l10n or AppStrings. Keep user-facing copy in presentation/application boundaries and pass pure domain values across layers.',
      );
      expect(
        staleBaseline,
        isEmpty,
        reason:
            'When a legacy domain localization dependency is removed, update this baseline so the remaining debt stays visible.',
      );
    });

    test('domain model display getters stay behind the legacy baseline', () {
      final currentDisplayGetters = <String>[];

      for (final root in const [
        'lib/features',
        'lib/core/domain',
        'lib/core/booking',
      ]) {
        for (final file in _dartFilesUnder(root)) {
          if (_isPresentationFile(file.path)) continue;
          if (!file.path.contains('/domain/') &&
              !file.path.contains('/core/domain/') &&
              !file.path.contains('/core/booking/')) {
            continue;
          }

          currentDisplayGetters.addAll(_domainDisplayGetterDependencies(file));
        }
      }
      currentDisplayGetters.sort();

      final unexpectedDisplayGetters =
          currentDisplayGetters
              .where(
                (dependency) =>
                    !_legacyDomainDisplayGetterDependencies.contains(
                      dependency,
                    ),
              )
              .toList();
      final staleBaseline =
          _legacyDomainDisplayGetterDependencies
              .where(
                (dependency) => !currentDisplayGetters.contains(dependency),
              )
              .toList();

      expect(
        unexpectedDisplayGetters,
        isEmpty,
        reason:
            'Domain entities must not grow UI/display getters such as label, emoji, displayText, or homeRoute. Put display mapping in presentation extensions.',
      );
      expect(
        staleBaseline,
        isEmpty,
        reason:
            'When a legacy domain display getter is moved to presentation, update this baseline so the remaining debt stays visible.',
      );
    });

    test('repository contracts and implementations stay in their layers', () {
      final misplacedContracts = <String>[];
      final misplacedImplementations = <String>[];

      for (final file in _dartFilesUnder('lib/features')) {
        final source = file.readAsStringSync();

        if (RegExp(r'abstract\s+class\s+\w+Repository\b').hasMatch(source) &&
            !_isFeatureDomainRepositoryFile(file.path)) {
          misplacedContracts.add(file.path);
        }

        final implementationMatches = RegExp(
          r'class\s+\w+Repository\b[^{]*(?:implements|extends)\s+\w+Repository\b',
        ).allMatches(source);
        if (implementationMatches.isNotEmpty &&
            !_isFeatureDataRepositoryFile(file.path) &&
            !_legacyRepositoryImplementationExceptions.contains(file.path)) {
          misplacedImplementations.add(file.path);
        }
      }

      expect(
        misplacedContracts,
        isEmpty,
        reason:
            'Repository interfaces belong under feature/domain/repositories.',
      );
      expect(
        misplacedImplementations,
        isEmpty,
        reason:
            'Repository implementations belong under feature/data/repositories.',
      );
    });
  });

  group('mock data selection', () {
    test(
      'EnvironmentConfig.useMockData branches are centralized or explicit',
      () {
        final violations = <String>[];

        for (final file in _dartFilesUnder('lib')) {
          if (!file.readAsStringSync().contains(
            'EnvironmentConfig.useMockData',
          )) {
            continue;
          }
          if (_mockDataBranchExceptions.contains(file.path)) continue;

          violations.add(file.path);
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Repository selection should use createRepository<T>() or an explicitly documented exception.',
        );
      },
    );
  });
}

Iterable<File> _dartFilesUnder(String path) {
  return Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'));
}

List<String> _importOrExportUris(File file) {
  final source = file.readAsStringSync();
  return RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).toList();
}

List<String> _domainLocalizationDependencies(File file) {
  final dependencies = <String>[];
  final source = file.readAsStringSync();

  for (final uri in _importOrExportUris(file).where(_pointsToCoreL10n)) {
    dependencies.add('${file.path}: $uri');
  }
  if (RegExp(r'\bAppStrings\b').hasMatch(source)) {
    dependencies.add('${file.path}: AppStrings');
  }

  return dependencies;
}

List<String> _domainDisplayGetterDependencies(File file) {
  final dependencies = <String>[];
  final source = file.readAsStringSync();
  final displayGetterPattern = RegExp(
    r'\bString\s+get\s+(?:label|title|emoji|statusLabel|typeLabel|displayLabel|displayText|homeRoute|summaryText)\b',
  );
  final displayConstructorPattern = RegExp(
    r'\bconst\s+\w+\([^)]*this\.(?:label|description|message|example)\b',
  );

  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (displayGetterPattern.hasMatch(line) ||
        displayConstructorPattern.hasMatch(line)) {
      dependencies.add('${file.path}:${index + 1}');
    }
  }

  return dependencies;
}

bool _isFeatureDomainOrDataFile(String path) =>
    path.contains('/domain/') || path.contains('/data/');

bool _isFeatureDomainFile(String path) => path.contains('/domain/');

bool _isFeatureDataFile(String path) => path.contains('/data/');

bool _isPresentationFile(String path) => path.contains('/presentation/');

bool _isFeatureDomainRepositoryFile(String path) =>
    path.contains('/domain/repositories/');

bool _isFeatureDomainServiceFile(String path) =>
    path.contains('/domain/services/');

bool _isFeatureDataRepositoryFile(String path) =>
    path.contains('/data/repositories/');

bool _pointsToPresentation(String uri) => uri.contains('/presentation/');

bool _pointsToData(String uri) =>
    uri.contains('/data/') && !uri.startsWith('package:timezone/');

bool _pointsToInfrastructure(String uri) {
  if (uri == 'dart:io') return true;
  if (uri.startsWith('package:firebase_')) return true;
  if (uri.startsWith('package:flutter_local_notifications/')) return true;
  if (_pointsToHive(uri)) return true;
  if (uri.startsWith('package:shared_preferences/')) return true;
  if (uri.contains('/core/config/environment')) return true;
  if (uri.contains('/core/network/')) return true;
  return false;
}

bool _pointsToHive(String uri) =>
    uri.startsWith('package:hive/') || uri.startsWith('package:hive_flutter/');

bool _pointsToFlutterFramework(String uri) =>
    uri.startsWith('package:flutter/');

bool _pointsToCoreL10n(String uri) => uri.contains('/core/l10n/');

const _legacyRepositoryImplementationExceptions = <String>{};

const _legacyDomainFlutterFrameworkImportExceptions = <String>{};

const _legacyDataFlutterFrameworkImportExceptions = <String>{};

const _legacyCoreBookingFlutterFrameworkImportExceptions = <String>{};

const _legacyDomainLocalizationDependencies = <String>{};

const _legacyDomainDisplayGetterDependencies = <String>{};

const _legacyDomainHivePersistenceExceptions = <String>{
  'lib/features/lessons/domain/entities/attendance_stats.dart',
  'lib/features/lessons/domain/entities/feedback_preset.dart',
  'lib/features/practice/domain/entities/practice_goal.dart',
  'lib/features/practice/domain/entities/practice_note.dart',
  'lib/features/practice/domain/entities/practice_repertoire.dart',
  'lib/features/practice/domain/entities/recording.dart',
  'lib/features/relationship/domain/entities/notification_setting.dart',
  'lib/features/relationship/domain/entities/relationship_status.dart',
  'lib/features/relationship/domain/entities/teacher_student_relation.dart',
  'lib/features/schedule/domain/entities/group_class.dart',
  'lib/features/schedule/domain/entities/group_class_booking.dart',
  'lib/features/schedule/domain/entities/group_class_schedule.dart',
  'lib/features/schedule/domain/entities/makeup_lesson.dart',
  'lib/features/schedule/domain/entities/no_show_policy.dart',
  'lib/features/schedule/domain/entities/request_event.dart',
  'lib/features/schedule/domain/entities/schedule_confirmation_card.dart',
  'lib/features/schedule/domain/entities/teacher_availability.dart',
  'lib/features/schedule/domain/entities/unified_lesson_request.dart',
  'lib/features/student_home/domain/entities/manual_teacher.dart',
  'lib/features/students/domain/entities/class_membership.dart',
  'lib/features/students/domain/entities/lesson_class.dart',
  'lib/features/students/domain/entities/lesson_location.dart',
  'lib/features/students/domain/entities/lesson_slot.dart',
  'lib/features/subscription/domain/entities/lesson_policy.dart',
  'lib/features/subscription/domain/entities/proposal_settings.dart',
  'lib/features/subscription/domain/entities/subscription.dart',
  'lib/features/subscription/domain/entities/subscription_proposal.dart',
  'lib/features/subscription/domain/entities/subscription_settings.dart',
  'lib/features/subscription/domain/entities/subscription_template.dart',
  'lib/features/subscription/domain/entities/subscription_usage.dart',
};

const _mockDataBranchExceptions = <String>{
  'lib/core/providers/repository_provider.dart',

  // Non-repository bootstrapping or UI gates that still need product decisions.
  'lib/core/router/app_router.dart',
  'lib/core/services/image_upload_service.dart',
  'lib/core/widgets/debug_role_switcher.dart',
  'lib/main.dart',
  'lib/features/auth/presentation/providers/auth_provider.dart',
  'lib/features/auth/presentation/providers/user_role_provider.dart',
  'lib/features/auth/presentation/screens/login_screen.dart',
  'lib/features/auth/presentation/screens/student_invite_code_screen.dart',
  'lib/features/notifications/presentation/providers/notification_providers.dart',
  'lib/features/onboarding/presentation/screens/student_profile_setup_screen.dart',
  'lib/features/onboarding/presentation/screens/student_tutorial_screen.dart',
  'lib/features/onboarding/presentation/screens/tutorial_screen.dart',
};
