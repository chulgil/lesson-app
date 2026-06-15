import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice_journal/presentation/extensions/journal_tone.dart';

void main() {
  test('톤별 제목: child=도장판 / standard=연습장', () {
    expect(JournalTone.child.title, '도장판');
    expect(JournalTone.standard.title, '연습장');
  });
}
