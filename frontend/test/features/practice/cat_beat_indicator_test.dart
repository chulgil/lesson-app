import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/presentation/widgets/metronome/cat_beat_indicator.dart';

void main() {
  group('CatBeatIndicator paw chunking', () {
    test('does not wrap simple meters with 6 or fewer beats', () {
      expect(chunkPawsForDisplayRows(4), [
        [1, 2, 3, 4],
      ]);
      expect(chunkPawsForDisplayRows(6), [
        [1, 2, 3, 4, 5, 6],
      ]);
    });

    test('wraps 8-beat compound meter into two compact rows', () {
      expect(chunkPawsForDisplayRows(8), [
        [1, 2, 3, 4, 5, 6],
        [7, 8],
      ]);
    });

    test('wraps 9-beat compound meter into two compact rows', () {
      expect(chunkPawsForDisplayRows(9), [
        [1, 2, 3, 4, 5, 6],
        [7, 8, 9],
      ]);
    });

    test('wraps 12-beat compound meter into two rows for compact layout', () {
      expect(chunkPawsForDisplayRows(12), [
        [1, 2, 3, 4, 5, 6],
        [7, 8, 9, 10, 11, 12],
      ]);
    });
  });
}
