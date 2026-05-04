import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('subscription domain services do not import presentation providers', () {
    final directory = Directory('lib/features/subscription/domain/services');
    final dartFiles = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('.g.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();

      expect(
        source,
        isNot(contains('/presentation/providers/')),
        reason: '${file.path} must not depend on presentation providers',
      );
      expect(
        source,
        isNot(contains('../../presentation/providers/')),
        reason: '${file.path} must not depend on presentation providers',
      );
    }
  });
}
