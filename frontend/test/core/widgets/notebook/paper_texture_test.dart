import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/widgets/notebook/paper_scaffold.dart';
import 'package:lessonaza/core/widgets/notebook/paper_texture.dart';

/// Records the speckles a painter draws, ignoring every other canvas call.
class _SpeckleRecorder implements Canvas {
  final List<Offset> centers = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) => centers.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Number of grain layers currently mounted.
int _grainLayers(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .where((paint) => paint.painter is PaperGrainPainter)
    .length;

void main() {
  group('PaperTexture', () {
    testWidgets('renders its child without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PaperTexture(child: Text('body'))),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('body'), findsOneWidget);
      expect(_grainLayers(tester), 1);
    });

    testWidgets('paints grain once when nested', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PaperTexture(
            child: Scaffold(body: PaperScaffold(child: Text('nested body'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('nested body'), findsOneWidget);
      expect(_grainLayers(tester), 1);
    });

    testWidgets('survives a tight zero-height constraint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  height: 0,
                  child: PaperTexture(child: SizedBox.expand()),
                ),
                Expanded(child: PaperTexture(child: Text('remaining'))),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('remaining'), findsOneWidget);
    });
  });

  group('PaperGrainPainter', () {
    const size = Size(375, 800);
    const painter = PaperGrainPainter();

    test('draws a sparse field — well under one speckle per cell', () {
      final canvas = _SpeckleRecorder();
      painter.paint(canvas, size);

      // Grid pitch is 24px; sparsity leaves roughly half the cells empty.
      const cells = 16 * 34;
      expect(canvas.centers, isNotEmpty);
      expect(canvas.centers.length, lessThan(cells));
    });

    test('draws an identical field on every paint', () {
      final first = _SpeckleRecorder();
      final second = _SpeckleRecorder();
      painter.paint(first, size);
      painter.paint(second, size);

      expect(first.centers, equals(second.centers));
    });

    test('draws nothing for an empty canvas', () {
      final canvas = _SpeckleRecorder();
      painter.paint(canvas, Size.zero);

      expect(canvas.centers, isEmpty);
    });
  });
}
