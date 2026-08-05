import 'package:flutter/material.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../vocabulary/vocabulary.dart';
import 'practice_tool.dart';

/// Stable [PracticeTool.id]s for the language discipline's practice tools (#1102).
abstract final class LanguagePracticeToolIds {
  static const vocabBook = 'vocab_book';
  static const dictation = 'dictation';
  static const pronunciation = 'pronunciation';
  static const conversation = 'conversation';
}

/// Language (어학) discipline practice tools — Phase 5 (#1102), skeleton stage.
///
/// The third registered discipline after music and fitness. #979-A wired the
/// practice tools modal to a discipline-keyed [PracticeToolRegistry]; this
/// registers language's tool set as a single data entry, so the language shell
/// renders with **zero** modal-shell change and music stays byte-identical.
///
/// 단어장 (vocabBook) is the first **real** language tool (#1124): its panel is a
/// launcher into a word bank + SM-2 flashcard review (via the vocabulary facade).
/// The remaining three (받아쓰기/발음/회화) stay **skeletons** — each renders its
/// identity (via [EmptyStateWidget]) so the shell is navigable, but carries no
/// speech-recognition / scoring logic yet (a deliberate follow-up). None has id
/// `tuner` or `metronome`, so the modal's microphone + engine lifecycle stays
/// inert for language (both `_tunerIndex` and `_metronomeIndex` resolve to -1).
final List<PracticeTool> languagePracticeTools = <PracticeTool>[
  PracticeTool(
    id: LanguagePracticeToolIds.vocabBook,
    displayLabel: AppStrings.practiceToolVocabBook,
    // #1124: first real language tool — word bank + SM-2 flashcard review. The
    // panel launches full-screen CRUD/review (cross-feature = vocabulary facade).
    panelBuilder:
        (context, studentId, sectionId) => VocabBookPanel(studentId: studentId),
  ),
  PracticeTool(
    id: LanguagePracticeToolIds.dictation,
    displayLabel: AppStrings.practiceToolDictation,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.edit_note_outlined,
          title: AppStrings.practiceToolDictation,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
  PracticeTool(
    id: LanguagePracticeToolIds.pronunciation,
    displayLabel: AppStrings.practiceToolPronunciation,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.record_voice_over_outlined,
          title: AppStrings.practiceToolPronunciation,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
  PracticeTool(
    id: LanguagePracticeToolIds.conversation,
    displayLabel: AppStrings.practiceToolConversation,
    panelBuilder:
        (context, studentId, sectionId) => const EmptyStateWidget(
          icon: Icons.forum_outlined,
          title: AppStrings.practiceToolConversation,
          subtitle: AppStrings.practiceToolSkeletonSubtitle,
        ),
  ),
];
