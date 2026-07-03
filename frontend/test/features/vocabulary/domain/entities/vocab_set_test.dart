import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/vocabulary/domain/entities/vocab_set.dart';

void main() {
  final createdAt = DateTime(2026, 7, 3, 9, 30);

  group('VocabSet', () {
    test('toJson/fromJson round-trip preserves every field', () {
      final set = VocabSet(id: 's1', title: '중국어 HSK4', createdAt: createdAt);

      final restored = VocabSet.fromJson(set.toJson());

      expect(restored, set);
      expect(restored.id, 's1');
      expect(restored.title, '중국어 HSK4');
      expect(restored.createdAt, createdAt);
    });

    test('copyWith replaces only the given field', () {
      final set = VocabSet(id: 's1', title: '원본', createdAt: createdAt);

      final renamed = set.copyWith(title: '수정됨');

      expect(renamed.id, 's1');
      expect(renamed.title, '수정됨');
      expect(renamed.createdAt, createdAt);
      expect(renamed, isNot(set));
    });

    test('value equality by id/title/createdAt', () {
      final a = VocabSet(id: 's1', title: 't', createdAt: createdAt);
      final b = VocabSet(id: 's1', title: 't', createdAt: createdAt);
      final c = VocabSet(id: 's2', title: 't', createdAt: createdAt);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
