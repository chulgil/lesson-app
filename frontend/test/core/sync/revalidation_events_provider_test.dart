import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/sync/revalidation_events_provider.dart';

void main() {
  group('RevalidationEvents', () {
    test('starts null and emit publishes path with a monotonic seq', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      expect(c.read(revalidationEventsProvider), isNull);

      c.read(revalidationEventsProvider.notifier).emit('/practice');
      final s1 = c.read(revalidationEventsProvider)!;
      expect(s1.path, '/practice');
      expect(s1.seq, 1);

      // Same path emitted again is a distinct state (seq advances) so listeners
      // still fire — a plain equal object would be dropped by Riverpod.
      c.read(revalidationEventsProvider.notifier).emit('/practice');
      final s2 = c.read(revalidationEventsProvider)!;
      expect(s2.seq, 2);
    });
  });

  group('ref.autoRevalidate', () {
    test('invalidates only on matching (segment-aware) prefixes', () async {
      var builds = 0;
      final probe = Provider.autoDispose<int>((ref) {
        ref.autoRevalidate('/practice');
        return ++builds;
      });

      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(probe, (_, _) {}, fireImmediately: true);
      expect(builds, 1);

      // Non-matching prefix → no rebuild.
      c.read(revalidationEventsProvider.notifier).emit('/lessons');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(probe), 1);

      // Exact prefix → rebuild.
      c.read(revalidationEventsProvider.notifier).emit('/practice');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(probe), 2);

      // Child segment → rebuild.
      c.read(revalidationEventsProvider.notifier).emit('/practice/42');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(probe), 3);

      // Sibling text prefix must NOT match (segment-aware).
      c.read(revalidationEventsProvider.notifier).emit('/practice-logs');
      await Future<void>.delayed(Duration.zero);
      expect(c.read(probe), 3);
    });
  });
}
