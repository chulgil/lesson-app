import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('riverpod state contract', () {
    test('feature providers do not use legacy StateNotifier APIs', () {
      final violations = _legacyStateNotifierUsages().toList()..sort();

      expect(
        violations,
        isEmpty,
        reason:
            'New or migrated feature state must use riverpod_annotation codegen Notifier/AsyncNotifier providers instead of StateNotifierProvider.',
      );
    });
  });
}

Iterable<String> _legacyStateNotifierUsages() sync* {
  final legacyPatterns = {
    'StateNotifierProvider': RegExp(r'\bStateNotifierProvider\b'),
    'StateNotifier': RegExp(r'\bStateNotifier\s*<'),
  };

  for (final file in _dartFilesUnder('lib/features')) {
    final source = file.readAsStringSync();

    for (final entry in legacyPatterns.entries) {
      if (entry.value.hasMatch(source)) {
        yield '${file.path}: ${entry.key}';
      }
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
