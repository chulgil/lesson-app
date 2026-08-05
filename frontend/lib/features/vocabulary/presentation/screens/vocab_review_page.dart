import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../domain/entities/review_grade.dart';
import '../../domain/entities/vocab_card.dart';
import '../providers/review_session_provider.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/review_grade_bar.dart';

/// Flashcard review session — flip a card, then self-grade it (#1124).
///
/// [setId] null reviews the due cards across every set (the panel's global
/// session); a non-null id scopes to one set. Reveal state is local and resets
/// per card; grading advances the queue via [ReviewSession].
class VocabReviewPage extends ConsumerStatefulWidget {
  const VocabReviewPage({super.key, this.setId});

  final String? setId;

  @override
  ConsumerState<VocabReviewPage> createState() => _VocabReviewPageState();
}

class _VocabReviewPageState extends ConsumerState<VocabReviewPage> {
  bool _showAnswer = false;
  bool _grading = false;

  Future<void> _grade(ReviewGrade grade) async {
    // Drop taps arriving while a grade is being persisted (re-entrancy guard —
    // the notifier guards too, this also avoids a redundant provider call).
    if (_grading) return;
    setState(() => _grading = true);
    await ref.read(reviewSessionProvider(widget.setId).notifier).grade(grade);
    if (mounted) {
      setState(() {
        _showAnswer = false;
        _grading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(reviewSessionProvider(widget.setId));

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.vocabReviewTitle,
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (_, __) => _completeState(
              context,
              title: AppStrings.vocabReviewEmptyTitle,
              subtitle: AppStrings.vocabReviewEmptySubtitle,
            ),
        data: (state) {
          if (state.total == 0) {
            return _completeState(
              context,
              title: AppStrings.vocabReviewEmptyTitle,
              subtitle: AppStrings.vocabReviewEmptySubtitle,
            );
          }
          if (state.isDone) {
            return _completeState(
              context,
              title: AppStrings.vocabReviewDoneTitle,
              subtitle: AppStrings.vocabReviewDoneMessage(state.total),
            );
          }
          return _activeState(state.current!, state.completed + 1, state.total);
        },
      ),
    );
  }

  Widget _activeState(VocabCard card, int position, int total) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Column(
          children: [
            Text(
              AppStrings.vocabReviewProgress(position, total),
              style: AppTypography.caption.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Expanded(
              child: SingleChildScrollView(
                child: FlashcardWidget(
                  card: card,
                  showAnswer: _showAnswer,
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            SizedBox(
              height: AppSpacing.buttonHeight,
              child:
                  _showAnswer
                      ? ReviewGradeBar(onGrade: _grade)
                      : Center(
                        child: Text(
                          AppStrings.vocabTapToReveal,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.inkTertiary,
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _completeState(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return EmptyStateWidget(
      icon: Icons.check_circle_outline,
      title: title,
      subtitle: subtitle,
      actionLabel: AppStrings.vocabReviewClose,
      actionIcon: Icons.close,
      onAction: () => Navigator.of(context).maybePop(),
    );
  }
}
