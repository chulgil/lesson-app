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
  });
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

String? _featureNameForPath(String path) {
  final match = RegExp(r'lib/features/([^/]+)/').firstMatch(path);
  return match?.group(1);
}

String? _featureNameForImportUri(String sourcePath, String uri) {
  final absoluteUriMatch =
      RegExp(r'package:lesson_app/features/([^/]+)/').firstMatch(uri) ??
      RegExp(r'(?:^|/)features/([^/]+)/').firstMatch(uri);
  if (absoluteUriMatch != null) return absoluteUriMatch.group(1);

  if (!uri.startsWith('.')) return null;

  final sourceUri = Directory.current.uri.resolve(sourcePath);
  final normalized = sourceUri.resolve(uri).path;
  final match = RegExp(r'/lib/features/([^/]+)/').firstMatch(normalized);
  return match?.group(1);
}

bool _pointsToPresentationProvider(String uri) =>
    uri.contains('/presentation/providers/') ||
    uri.startsWith('presentation/providers/');

const _legacyCrossFeaturePresentationProviderImports = <String>{};
