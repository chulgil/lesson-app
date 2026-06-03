// Regression: the force-update button must route to the platform's own store.
// Previously it always opened the Apple App Store, even on Android. (#3)

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/settings/presentation/screens/force_update_screen.dart';

void main() {
  group('ForceUpdateScreen.storeTargets', () {
    test('Android routes to the Play Store, not the App Store', () {
      final targets = ForceUpdateScreen.storeTargets(isAndroid: true);

      expect(targets, isNotEmpty);
      // First choice is the Play app deep link.
      expect(targets.first.scheme, 'market');
      expect(targets.first.toString(), contains('id=app.lessonaza'));
      // https fallback also points at the Play Store.
      expect(
        targets.any(
          (u) =>
              u.host == 'play.google.com' &&
              u.toString().contains('id=app.lessonaza'),
        ),
        isTrue,
      );
      // Never the App Store on Android.
      expect(targets.any((u) => u.host.contains('apple.com')), isFalse);
    });

    test('iOS routes to the App Store, not the Play Store', () {
      final targets = ForceUpdateScreen.storeTargets(isAndroid: false);

      expect(targets, isNotEmpty);
      expect(targets.every((u) => u.host.contains('apple.com')), isTrue);
      expect(targets.any((u) => u.host == 'play.google.com'), isFalse);
    });
  });
}
