import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature dependency contract', () {
    test(
      'cross-feature presentation provider imports are explicit legacy dependencies',
      () {
        final currentImports =
            _crossFeaturePresentationProviderImports().toList()..sort();
        final unexpectedImports =
            currentImports
                .where(
                  (dependency) =>
                      !_legacyCrossFeaturePresentationProviderImports.contains(
                        dependency,
                      ),
                )
                .toList();
        final staleBaseline =
            _legacyCrossFeaturePresentationProviderImports
                .where((dependency) => !currentImports.contains(dependency))
                .toList();

        expect(
          unexpectedImports,
          isEmpty,
          reason:
              'New code must not import another feature presentation provider directly. Use a feature facade, domain contract, or application service instead.',
        );
        expect(
          staleBaseline,
          isEmpty,
          reason:
              'When a legacy cross-feature presentation provider import is removed, update this baseline so the remaining debt stays visible.',
        );
      },
    );

    test('feature implementation files do not import presentation providers', () {
      final directImports =
          _featurePresentationProviderImports().toList()..sort();

      expect(
        directImports,
        isEmpty,
        reason:
            'Feature implementation files must use feature facades or local application boundaries instead of importing presentation/providers directly.',
      );
    });

    test(
      'feature presentation files do not import another feature presentation implementation directly',
      () {
        final directImports =
            _crossFeaturePresentationImplementationImports().toList()..sort();

        expect(
          directImports,
          isEmpty,
          reason:
              'Feature presentation code must depend on another feature through a feature facade or shared/core widget, not direct screens/widgets/providers imports.',
        );
      },
    );

    test('only feature facades export presentation providers', () {
      final invalidExports =
          _nonFacadePresentationProviderExports().toList()..sort();

      expect(
        invalidExports,
        isEmpty,
        reason:
            'Presentation providers may be re-exported only from a feature facade so public provider boundaries stay explicit.',
      );
    });
  });
}

Iterable<String> _crossFeaturePresentationImplementationImports() sync* {
  for (final file in _dartFilesUnder('lib/features')) {
    final sourceFeature = _featureNameForPath(file.path);
    if (sourceFeature == null || !file.path.contains('/presentation/')) {
      continue;
    }

    for (final uri in _importUris(file)) {
      final targetPath = _normalizedImportPath(file.path, uri);
      if (targetPath == null) continue;

      final targetFeature = _featureNameForPath(targetPath);
      if (targetFeature == null || targetFeature == sourceFeature) continue;
      if (!_pointsToPresentationImplementation(targetPath)) continue;

      yield '${file.path} -> $uri';
    }
  }
}

Iterable<String> _crossFeaturePresentationProviderImports() sync* {
  for (final file in _dartFilesUnder('lib/features')) {
    final sourceFeature = _featureNameForPath(file.path);
    if (sourceFeature == null || !file.path.contains('/presentation/')) {
      continue;
    }

    for (final uri in _importOrExportUris(file)) {
      final targetFeature = _featureNameForImportUri(file.path, uri);
      if (targetFeature == null || targetFeature == sourceFeature) continue;
      if (!_pointsToPresentationProvider(uri)) continue;

      yield '${file.path} -> $uri';
    }
  }
}

Iterable<String> _featurePresentationProviderImports() sync* {
  for (final file in _dartFilesUnder('lib/features')) {
    if (file.path.endsWith('_facade.dart')) continue;

    for (final uri in _importUris(file)) {
      if (!_pointsToPresentationProvider(uri)) continue;
      yield '${file.path} -> $uri';
    }
  }
}

Iterable<String> _nonFacadePresentationProviderExports() sync* {
  for (final file in _dartFilesUnder('lib/features')) {
    if (file.path.endsWith('_facade.dart')) continue;

    for (final uri in _exportUris(file)) {
      if (!_pointsToPresentationProvider(uri)) continue;
      yield '${file.path} -> $uri';
    }
  }
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

List<String> _importUris(File file) {
  final source = file.readAsStringSync();
  return RegExp(
    r'''^\s*import\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).toList();
}

List<String> _exportUris(File file) {
  final source = file.readAsStringSync();
  return RegExp(
    r'''^\s*export\s+['"]([^'"]+)['"]''',
    multiLine: true,
  ).allMatches(source).map((match) => match.group(1)!).toList();
}

String? _featureNameForPath(String path) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

String? _featureNameForImportUri(String sourcePath, String uri) {
  final absoluteUriMatch =
      RegExp(
        r'package:(?:lessonaza|lesson_app)/features/([^/]+)/',
      ).firstMatch(uri) ??
      RegExp(r'(?:^|/)features/([^/]+)/').firstMatch(uri);
  if (absoluteUriMatch != null) return absoluteUriMatch.group(1);

  if (!uri.startsWith('.')) return null;

  final sourceUri = Directory.current.uri.resolve(sourcePath);
  final normalized = sourceUri.resolve(uri).path;
  final match = RegExp(r'/lib/features/([^/]+)/').firstMatch(normalized);
  return match?.group(1);
}

String? _normalizedImportPath(String sourcePath, String uri) {
  final packageMatch = RegExp(
    r'package:(?:lessonaza|lesson_app)/(.+)$',
  ).firstMatch(uri);
  if (packageMatch != null) return 'lib/${packageMatch.group(1)!}';

  if (uri.startsWith('features/')) return 'lib/$uri';
  if (!uri.startsWith('.')) return null;

  final sourceUri = Directory.current.uri.resolve(sourcePath);
  return sourceUri.resolve(uri).path;
}

bool _pointsToPresentationProvider(String uri) =>
    uri.contains('/presentation/providers/') ||
    uri.startsWith('presentation/providers/');

bool _pointsToPresentationImplementation(String path) =>
    path.contains('/presentation/screens/') ||
    path.contains('/presentation/widgets/') ||
    path.contains('/presentation/providers/');

const _legacyCrossFeaturePresentationProviderImports = <String>{};
