import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_bookmark.dart';

void main() {
  group('LoopBookmark — #511', () {
    test('toJson then fromJson round trips', () {
      const bookmark = LoopBookmark(
        id: 'b1',
        name: '도입부',
        startSeconds: 10,
        endSeconds: 40,
        colorIndex: 2,
      );

      final json = bookmark.toJson();
      final decoded = LoopBookmark.fromJson(json);

      expect(decoded, equals(bookmark));
      expect(decoded.id, 'b1');
      expect(decoded.name, '도입부');
      expect(decoded.startSeconds, 10);
      expect(decoded.endSeconds, 40);
      expect(decoded.colorIndex, 2);
    });

    test('fromJson tolerates a missing colorIndex (defaults to 0)', () {
      final decoded = LoopBookmark.fromJson(<String, dynamic>{
        'id': 'b1',
        'name': '엔딩',
        'startSeconds': 50,
        'endSeconds': 80,
      });

      expect(decoded.colorIndex, 0);
    });

    test('copyWith overrides only the requested fields', () {
      const bookmark = LoopBookmark(
        id: 'b1',
        name: 'old',
        startSeconds: 0,
        endSeconds: 10,
        colorIndex: 0,
      );

      final updated = bookmark.copyWith(name: 'new', colorIndex: 4);

      expect(updated.id, bookmark.id);
      expect(updated.name, 'new');
      expect(updated.startSeconds, bookmark.startSeconds);
      expect(updated.endSeconds, bookmark.endSeconds);
      expect(updated.colorIndex, 4);
    });

    test('equality is structural across all fields', () {
      const a = LoopBookmark(
        id: 'b1',
        name: 'x',
        startSeconds: 0,
        endSeconds: 5,
        colorIndex: 0,
      );
      const b = LoopBookmark(
        id: 'b1',
        name: 'x',
        startSeconds: 0,
        endSeconds: 5,
        colorIndex: 0,
      );
      const c = LoopBookmark(
        id: 'b1',
        name: 'x',
        startSeconds: 0,
        endSeconds: 5,
        colorIndex: 1,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });
}
