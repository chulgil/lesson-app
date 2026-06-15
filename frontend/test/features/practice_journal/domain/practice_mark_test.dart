import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/domain/entities/practice_mark.dart';

void main() {
  test('PracticeMark full > short 갱신, copyWith/json 왕복', () {
    final m = PracticeMark(
      date: DateTime.utc(2026, 6, 15),
      intensity: MarkIntensity.short,
    );
    final up = m.copyWith(intensity: MarkIntensity.full);
    expect(up.intensity, MarkIntensity.full);
    expect(PracticeMark.fromJson(up.toJson()).intensity, MarkIntensity.full);
    // full 은 short 보다 강함
    expect(MarkIntensity.full.isStrongerThan(MarkIntensity.short), isTrue);
  });
}
