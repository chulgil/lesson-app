import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_memo.dart';

void main() {
  group('LoopMemo — #510', () {
    test('toJson then fromJson round trips', () {
      final memo = LoopMemo(
        id: 'memo-1',
        atSeconds: 42,
        text: '여기 보잉 주의',
        createdAt: DateTime(2026, 6, 4, 10, 30),
      );

      final json = memo.toJson();
      final decoded = LoopMemo.fromJson(json);

      expect(decoded, equals(memo));
      expect(decoded.id, 'memo-1');
      expect(decoded.atSeconds, 42);
      expect(decoded.text, '여기 보잉 주의');
      expect(decoded.createdAt, DateTime(2026, 6, 4, 10, 30));
    });

    test('copyWith overrides only the requested fields', () {
      final memo = LoopMemo(
        id: 'memo-1',
        atSeconds: 10,
        text: 'old',
        createdAt: DateTime(2026, 6, 4),
      );

      final updated = memo.copyWith(text: 'new');

      expect(updated.id, memo.id);
      expect(updated.atSeconds, memo.atSeconds);
      expect(updated.text, 'new');
      expect(updated.createdAt, memo.createdAt);
    });

    test('equality is structural across fields', () {
      final a = LoopMemo(
        id: 'm',
        atSeconds: 1,
        text: 't',
        createdAt: DateTime(2026, 6, 4),
      );
      final b = LoopMemo(
        id: 'm',
        atSeconds: 1,
        text: 't',
        createdAt: DateTime(2026, 6, 4),
      );
      final c = LoopMemo(
        id: 'm',
        atSeconds: 2,
        text: 't',
        createdAt: DateTime(2026, 6, 4),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });
}
