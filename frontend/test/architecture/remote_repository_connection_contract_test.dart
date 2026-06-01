import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backend-backed repositories do not use local fallback in remote mode', () {
    const providerPaths = [
      'lib/features/practice/presentation/providers/practice_item_providers.dart',
      'lib/features/practice/presentation/providers/practice_note_provider.dart',
      'lib/features/parent_home/presentation/providers/child_profile_provider.dart',
      'lib/features/lessons/presentation/providers/tip_template_providers.dart',
      'lib/features/lessons/presentation/providers/feedback_template_providers.dart',
      'lib/features/schedule/presentation/providers/schedule_confirmation_card_providers.dart',
      'lib/features/students/presentation/providers/teacher_announcement_providers.dart',
    ];

    for (final path in providerPaths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains('createLocalFallbackRepository')),
        reason:
            '$path has a backend API and must select a Remote repository '
            'when USE_MOCK=false.',
      );
      expect(
        source,
        contains('remote:'),
        reason: '$path must wire createRepository(..., remote: ...).',
      );
    }
  });
}
