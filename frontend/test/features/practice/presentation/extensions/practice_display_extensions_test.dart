import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/metronome_settings.dart';
import 'package:lessonaza/features/practice/domain/entities/piece.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_item.dart';
import 'package:lessonaza/features/practice/domain/entities/recording.dart';
import 'package:lessonaza/features/practice/domain/entities/repertoire_timeline.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_settings.dart';
import 'package:lessonaza/features/practice/domain/entities/tuner_types.dart';
import 'package:lessonaza/features/practice/presentation/extensions/practice_display_extensions.dart';

void main() {
  group('practice display extensions', () {
    test('maps practice item enum display values', () {
      expect(QuickReaction.good.emoji, '👍');
      expect(QuickReaction.excellent.label, '훌륭해요');
      expect(StudentResponse.question.emoji, '❓');
      expect(StudentResponse.thanks.label, '감사합니다');

      expect(PracticePriority.must.label, '필수');
      expect(PracticePriority.should.childLabel, '해보면 좋아요~');
      expect(PracticePriority.could.shortLabel, '선택');
      expect(PracticePriority.must.emoji, '⭐⭐⭐');

      expect(PracticeType.repertoire.label, '레퍼토리');
    });

    test('maps metronome display values', () {
      expect(AccentPattern.uniform.label, '균일');
      expect(AccentPattern.firstBeatOnly.description, '첫박만 강조');
      expect(AccentPattern.strongMediumWeak.description, '첫박 강, 3박 중간');
    });

    test('maps piece and recording display values', () {
      final piece = Piece(
        id: 'piece-1',
        title: 'Canon',
        composer: 'Pachelbel',
        opus: 'Op. 1',
        movement: 'I',
        createdAt: DateTime(2026),
      );

      expect(PieceProgress.polishing.label, '마무리');
      expect(piece.fullTitle, 'Canon - Pachelbel');
      expect(piece.displayName, 'Canon Op. 1 I');

      expect(RecordingType.student.label, '연습 녹음');
      expect(StorageStatus.archived.label, '아카이브');
    });

    test('maps timeline and tuner display values', () {
      const monthGroup = MonthGroup(
        yearMonth: '2026-05',
        year: 2026,
        month: 5,
        repertoires: [],
      );

      expect(monthGroup.label, '2026년 5월');
      expect(ClefType.treble.label, '높은음자리');
      expect(ClefType.bass.symbol, '𝄢');
      expect(EnharmonicMode.both.example, 'C#/Db, ...');
      expect(TuningStatus.flat.description, '조금 높여주세요');
      expect(JudgementResult.miss.message, '다시 해봐옹~');
      expect(Transposition.bb.description, 'Bb관');
    });
  });
}
