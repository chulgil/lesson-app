import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/sync/lost_writes_provider.dart';

void main() {
  group('LostWrites', () {
    test('starts null; record publishes count+reason with monotonic seq', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(lostWritesProvider), isNull);

      c.read(lostWritesProvider.notifier).record(3, LostWritesReason.expired);
      final e1 = c.read(lostWritesProvider)!;
      expect(e1.count, 3);
      expect(e1.reason, LostWritesReason.expired);
      expect(e1.seq, 1);

      // Same-ish event still distinct via seq so listeners fire.
      c.read(lostWritesProvider.notifier).record(2, LostWritesReason.logout);
      final e2 = c.read(lostWritesProvider)!;
      expect(e2.seq, 2);
      expect(e2.reason, LostWritesReason.logout);
    });

    test('record with non-positive count is a no-op', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(lostWritesProvider.notifier).record(0, LostWritesReason.expired);
      expect(c.read(lostWritesProvider), isNull);
    });

    test('clear resets to null', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(lostWritesProvider.notifier).record(1, LostWritesReason.logout);
      expect(c.read(lostWritesProvider), isNotNull);
      c.read(lostWritesProvider.notifier).clear();
      expect(c.read(lostWritesProvider), isNull);
    });
  });
}
