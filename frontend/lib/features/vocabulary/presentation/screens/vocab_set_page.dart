import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/vocab_card.dart';
import '../../domain/entities/vocab_set.dart';
import '../providers/vocab_cards_provider.dart';
import '../providers/vocab_library_controller.dart';
import '../widgets/vocab_dialogs.dart';
import 'vocab_review_page.dart';

/// One vocabulary set: the card bank plus an entry into its review session
/// (#1124). Cards support swipe edit/delete (우→좌); the FAB adds a card.
class VocabSetPage extends ConsumerWidget {
  const VocabSetPage({super.key, required this.set});

  final VocabSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(vocabCardsProvider(set.id));
    final dueCount =
        ref.watch(dueCardsProvider(set.id)).valueOrNull?.length ?? 0;

    return NotebookScreenScaffold(
      appBarTitle: set.title,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(context, ref),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (dueCount > 0) _reviewCta(context, ref, dueCount),
          Expanded(
            child: cardsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) =>
                      const Center(child: Text(AppStrings.cannotLoadData)),
              data:
                  (cards) =>
                      cards.isEmpty
                          ? EmptyStateWidget(
                            icon: Icons.style_outlined,
                            title: AppStrings.vocabCardsEmptyTitle,
                            subtitle: AppStrings.vocabCardsEmptySubtitle,
                            actionLabel: AppStrings.vocabAddCardCta,
                            actionIcon: Icons.add,
                            onAction: () => _addCard(context, ref),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.space2,
                            ),
                            itemCount: cards.length,
                            separatorBuilder:
                                (_, __) =>
                                    const SizedBox(height: AppSpacing.space1),
                            itemBuilder:
                                (context, i) =>
                                    _cardRow(context, ref, cards[i]),
                          ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCta(
    BuildContext context,
    WidgetRef ref,
    int dueCount,
  ) => Padding(
    padding: const EdgeInsets.all(AppSpacing.space4),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _startReview(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          minimumSize: const Size.fromHeight(AppSpacing.buttonHeight),
        ),
        icon: const Icon(Icons.play_arrow, size: 18),
        label: Text(
          '${AppStrings.vocabReviewCta} · ${AppStrings.vocabDueBadge(dueCount)}',
          style: NotebookTypography.sectionLabel.copyWith(color: AppColors.ink),
        ),
      ),
    ),
  );

  Widget _cardRow(BuildContext context, WidgetRef ref, VocabCard card) =>
      SwipeActionTile(
        actions: [
          SwipeAction(
            label: AppStrings.edit,
            icon: Icons.edit_outlined,
            onPressed: () => _editCard(context, ref, card),
          ),
          SwipeAction(
            label: AppStrings.delete,
            icon: Icons.delete_outline,
            tone: SwipeActionTone.destructive,
            onPressed: () => _confirmDeleteCard(context, ref, card),
          ),
        ],
        child: Container(
          color: AppColors.paper,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.front,
                style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                card.back,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );

  Future<void> _addCard(BuildContext context, WidgetRef ref) async {
    final draft = await showVocabCardDialog(context);
    if (draft == null) return;
    await ref
        .read(vocabLibraryProvider.notifier)
        .addCard(
          set.id,
          front: draft.front,
          back: draft.back,
          example: draft.example,
          memo: draft.memo,
        );
  }

  Future<void> _editCard(
    BuildContext context,
    WidgetRef ref,
    VocabCard card,
  ) async {
    final draft = await showVocabCardDialog(context, initial: card);
    if (draft == null) return;
    await ref
        .read(vocabLibraryProvider.notifier)
        .editCard(
          card,
          front: draft.front,
          back: draft.back,
          example: draft.example,
          memo: draft.memo,
        );
  }

  Future<void> _confirmDeleteCard(
    BuildContext context,
    WidgetRef ref,
    VocabCard card,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.vocabDeleteCardTitle,
      message: AppStrings.vocabDeleteCardMessage,
      isDestructive: true,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      await ref.read(vocabLibraryProvider.notifier).deleteCard(set.id, card.id);
    }
  }

  Future<void> _startReview(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => VocabReviewPage(setId: set.id)),
    );
    // Refresh counts even if the learner exited mid-session (session-completion
    // invalidation only fires on the last card).
    ref.invalidate(vocabCardsProvider(set.id));
    ref.invalidate(dueCardsProvider(set.id));
  }
}
