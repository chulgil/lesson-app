import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/search/presentation/screens/academy_detail_screen.dart';

void main() {
  group('AcademyDetailScreen', () {
    test('widget compiles without errors', () {
      // This test verifies that the widget class exists and is instantiable
      // without requiring full Riverpod setup
      final widget = AcademyDetailScreen(key: null, organizationId: 'acad_1');
      expect(widget, isNotNull);
      expect(widget.organizationId, equals('acad_1'));
    });
  });
}
