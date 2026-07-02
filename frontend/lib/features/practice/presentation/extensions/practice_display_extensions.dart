import '../../../../core/l10n/app_strings.dart';
import '../../domain/entities/metronome_settings.dart';
import '../../domain/entities/piece.dart';
import '../../domain/entities/practice_item.dart';
import '../../domain/entities/practice_loop_stats.dart';
import '../../domain/entities/practice_streak.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/repertoire_timeline.dart';
import '../../domain/entities/tuner_settings.dart';
import '../../domain/entities/tuner_types.dart';

extension AccentPatternDisplay on AccentPattern {
  String get label {
    return switch (this) {
      AccentPattern.uniform => '균일',
      AccentPattern.firstBeatOnly => '첫박강조',
      AccentPattern.strongMediumWeak => '강중약',
    };
  }

  String get description {
    return switch (this) {
      AccentPattern.uniform => '모든 박자 동일',
      AccentPattern.firstBeatOnly => '첫박만 강조',
      AccentPattern.strongMediumWeak => '첫박 강, 3박 중간',
    };
  }
}

extension PieceProgressDisplay on PieceProgress {
  String get label {
    return switch (this) {
      PieceProgress.notStarted => '시작 전',
      PieceProgress.inProgress => '진행중',
      PieceProgress.polishing => '마무리',
      PieceProgress.completed => '완료',
    };
  }
}

extension PieceDisplay on Piece {
  String get fullTitle {
    if (composer != null) {
      return '$title - $composer';
    }
    return title;
  }

  String get displayName {
    final parts = <String>[title];
    if (opus != null) parts.add(opus!);
    if (movement != null) parts.add(movement!);
    return parts.join(' ');
  }
}

extension QuickReactionDisplay on QuickReaction {
  String get label {
    return switch (this) {
      QuickReaction.good => '잘했어요',
      QuickReaction.excellent => '훌륭해요',
      QuickReaction.tryHarder => '힘내자',
    };
  }
}

extension StudentResponseDisplay on StudentResponse {
  String get label {
    return switch (this) {
      StudentResponse.thanks => '감사합니다',
      StudentResponse.question => '질문있어요',
    };
  }
}

extension PracticePriorityDisplay on PracticePriority {
  String get label {
    return switch (this) {
      PracticePriority.must => '필수',
      PracticePriority.should => '추천',
      PracticePriority.could => '도전',
    };
  }

  String get childLabel {
    return switch (this) {
      PracticePriority.must => '꼭 해와요!',
      PracticePriority.should => '해보면 좋아요~',
      PracticePriority.could => '도전해볼까?',
    };
  }

  String get shortLabel {
    return switch (this) {
      PracticePriority.must => '필수',
      PracticePriority.should => '권장',
      PracticePriority.could => '선택',
    };
  }
}

extension PracticeTypeDisplay on PracticeType {
  String get label {
    return switch (this) {
      PracticeType.repertoire => '레퍼토리',
      PracticeType.technique => '테크닉',
      PracticeType.theory => '이론',
      PracticeType.custom => '직접입력',
    };
  }
}

extension PracticeStreakDisplay on PracticeStreak {
  String get motivationMessage {
    if (currentStreak == 0) {
      return AppStrings.practiceJournalMotivationStart();
    } else if (currentStreak < 7) {
      return AppStrings.practiceJournalMotivationGrowing(currentStreak);
    } else if (currentStreak < 30) {
      return AppStrings.practiceJournalMotivationContinuing(currentStreak);
    } else {
      return AppStrings.practiceJournalMotivationCelebration(currentStreak);
    }
  }
}

extension RecordingTypeDisplay on RecordingType {
  String get label {
    return switch (this) {
      RecordingType.student => '연습 녹음',
      RecordingType.teacher => '참고 음원',
      RecordingType.feedback => '피드백',
    };
  }
}

extension StorageStatusDisplay on StorageStatus {
  String get label {
    return switch (this) {
      StorageStatus.local => '로컬 저장',
      StorageStatus.active => '서버 저장',
      StorageStatus.archived => '아카이브',
      StorageStatus.deleted => '삭제됨',
    };
  }
}

extension MonthGroupDisplay on MonthGroup {
  String get label => '$year년 $month월';
}

extension PracticeLoopStatsDisplay on PracticeLoopStats {
  /// Display label that combines piece + section names with sensible fallback.
  String get displayLabel {
    if (pieceName != null && pieceName!.isNotEmpty) {
      if (sectionName != null && sectionName!.isNotEmpty) {
        return '$pieceName · $sectionName';
      }
      return pieceName!;
    }
    return sectionName ?? sectionId;
  }
}

extension ClefTypeDisplay on ClefType {
  String get label {
    return switch (this) {
      ClefType.treble => '높은음자리',
      ClefType.bass => '낮은음자리',
      ClefType.alto => '가온음자리',
    };
  }

  String get symbol {
    return switch (this) {
      ClefType.treble => '𝄞',
      ClefType.bass => '𝄢',
      ClefType.alto => '𝄡',
    };
  }
}

extension EnharmonicModeDisplay on EnharmonicMode {
  String get label {
    return switch (this) {
      EnharmonicMode.sharpOnly => '샤프',
      EnharmonicMode.flatOnly => '플랫',
      EnharmonicMode.both => '병기',
    };
  }

  String get example {
    return switch (this) {
      EnharmonicMode.sharpOnly => 'C#, D#, ...',
      EnharmonicMode.flatOnly => 'Db, Eb, ...',
      EnharmonicMode.both => 'C#/Db, ...',
    };
  }
}

extension TuningStatusDisplay on TuningStatus {
  String get label {
    return switch (this) {
      TuningStatus.idle => '대기중',
      TuningStatus.listening => '감지중',
      TuningStatus.tuned => '정확',
      TuningStatus.flat => '낮음',
      TuningStatus.sharp => '높음',
    };
  }

  String get description {
    return switch (this) {
      TuningStatus.idle => '소리를 들려주세요',
      TuningStatus.listening => '음을 찾는 중...',
      TuningStatus.tuned => '완벽해요!',
      TuningStatus.flat => '조금 높여주세요',
      TuningStatus.sharp => '조금 낮춰주세요',
    };
  }
}

extension JudgementResultDisplay on JudgementResult {
  String get label {
    return switch (this) {
      JudgementResult.perfect => 'Perfect',
      JudgementResult.good => 'Good',
      JudgementResult.miss => 'Miss',
    };
  }

  String get message {
    return switch (this) {
      JudgementResult.perfect => '완벽해옹!',
      JudgementResult.good => '좋아옹!',
      JudgementResult.miss => '다시 해봐옹~',
    };
  }
}

extension TranspositionDisplay on Transposition {
  String get label {
    return switch (this) {
      Transposition.c => 'C',
      Transposition.bb => 'Bb',
      Transposition.eb => 'Eb',
      Transposition.f => 'F',
      Transposition.a => 'A',
    };
  }

  String get description {
    return switch (this) {
      Transposition.c => '실음',
      Transposition.bb => 'Bb관',
      Transposition.eb => 'Eb관',
      Transposition.f => 'F관',
      Transposition.a => 'A관',
    };
  }
}
