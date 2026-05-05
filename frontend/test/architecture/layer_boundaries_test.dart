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

bool _isFeatureDomainOrDataFile(String path) =>
    path.contains('/domain/') || path.contains('/data/');

bool _isFeatureDomainFile(String path) => path.contains('/domain/');

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
  if (uri.startsWith('package:hive/')) return true;
  if (uri.startsWith('package:hive_flutter/')) return true;
  if (uri.startsWith('package:shared_preferences/')) return true;
  if (uri.contains('/core/config/environment')) return true;
  if (uri.contains('/core/network/')) return true;
  return false;
}

const _legacyRepositoryImplementationExceptions = <String>{};

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

  // Legacy providers without a remote implementation/API endpoint yet.
  'lib/features/lessons/presentation/providers/payment_repository_provider.dart',
  'lib/features/parent_home/presentation/providers/child_profile_provider.dart',
  'lib/features/practice/presentation/providers/piece_repository_provider.dart',
  'lib/features/practice/presentation/providers/practice_note_provider.dart',
  'lib/features/practice/presentation/providers/practice_repertoire_repository_provider.dart',
  'lib/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart',
};
