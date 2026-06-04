import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/youtube/section_video_affordance.dart';

void main() {
  group('SectionVideoAffordance — §4.1 entry-point glyph', () {
    testWidgets('renders horizontal label without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionVideoAffordance(startSeconds: 42, endSeconds: 75),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('0:42'), findsOneWidget);
      expect(find.textContaining('1:15'), findsOneWidget);
    });

    testWidgets('stacked layout renders inside narrow column', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 60,
              child: SectionVideoAffordance(
                startSeconds: 0,
                endSeconds: 30,
                stacked: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders fallback when range is absent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionVideoAffordance(startSeconds: null, endSeconds: null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
