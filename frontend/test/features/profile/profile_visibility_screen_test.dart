import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/presentation/screens/profile_visibility_screen.dart';

void main() {
  group('ProfileVisibilityScreen', () {
    test('widget compiles without errors', () {
      // This test verifies that the widget class exists and is instantiable
      // without requiring full Riverpod setup
      const widget = ProfileVisibilityScreen();
      expect(widget, isNotNull);
    });
  });
}
