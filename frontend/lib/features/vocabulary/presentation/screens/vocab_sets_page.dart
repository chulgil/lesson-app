import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/notebook/notebook_alert_dialog.dart';
import '../../../../core/widgets/notebook/notebook_screen_scaffold.dart';
import '../../../../core/widgets/swipe_action_tile.dart';
import '../../domain/entities/vocab_set.dart';
import '../providers/vocab_cards_provider.dart';
import '../providers/vocab_library_controller.dart';
import '../providers/vocab_sets_provider.dart';
import '../widgets/vocab_dialogs.dart';
import 'vocab_set_page.dart';

/// The list of the learner's vocabulary sets (#1124). Swipe a row (우→좌) to
/// rename/delete; the FAB creates a set; tapping opens its card bank.
class VocabSetsPage extends ConsumerWidget {
  const VocabSetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(vocabSetsProvider);

    return NotebookScreenScaffold(
      appBarTitle: AppStrings.vocabSetsTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createSet(context, ref),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add),
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text(AppStrings.cannotLoadData)),
        data:
            (sets) =>
                sets.isEmpty
                    ? EmptyStateWidget(
                      icon: Icons.style_outlined,
                      title: AppStrings.vocabSetsEmptyTitle,
                      subtitle: AppStrings.vocabSetsEmptySubtitle,
                      actionLabel: AppStrings.vocabCreateSetCta,
                      actionIcon: Icons.add,
                      onAction: () => _createSet(context, ref),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.space2,
                      ),
                      itemCount: sets.length,
                      separatorBuilder:
                          (_, __) => const SizedBox(height: AppSpacing.space1),
                      itemBuilder: (context, i) => _SetRow(sets[i]),
                    ),
      ),
    );
  }

  Future<void> _createSet(BuildContext context, WidgetRef ref) async {
    final title = await showVocabSetNameDialog(context);
    if (title == null) return;
    await ref.read(vocabLibraryProvider.notifier).createSet(title);
  }
}

/// A single set row. A [ConsumerWidget] so it already holds the card/due counts
/// — the delete confirmation reads the card count synchronously (no await before
/// the dialog, so no context-across-async-gap).
class _SetRow extends ConsumerWidget {
  const _SetRow(this.set);

  final VocabSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardCount =
        ref.watch(vocabCardsProvider(set.id)).valueOrNull?.length ?? 0;
    final dueCount =
        ref.watch(dueCardsProvider(set.id)).valueOrNull?.length ?? 0;

    return SwipeActionTile(
      actions: [
        SwipeAction(
          label: AppStrings.edit,
          icon: Icons.edit_outlined,
          onPressed: () => _rename(context, ref),
        ),
        SwipeAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline,
          tone: SwipeActionTone.destructive,
          onPressed: () => _confirmDelete(context, ref, cardCount),
        ),
      ],
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          color: AppColors.paper,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      dueCount > 0
                          ? '${AppStrings.vocabCardCount(cardCount)} · ${AppStrings.vocabDueBadge(dueCount)}'
                          : AppStrings.vocabCardCount(cardCount),
                      style: AppTypography.caption.copyWith(
                        color:
                            dueCount > 0
                                ? AppColors.paperAccent
                                : AppColors.inkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => VocabSetPage(set: set)));
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final title = await showVocabSetNameDialog(
      context,
      initialTitle: set.title,
    );
    if (title == null) return;
    await ref.read(vocabLibraryProvider.notifier).renameSet(set, title);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int cardCount,
  ) async {
    final confirmed = await showNotebookDialog<bool>(
      context: context,
      title: AppStrings.vocabDeleteSetTitle,
      message: AppStrings.vocabDeleteSetMessage(set.title, cardCount),
      isDestructive: true,
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
    );
    if (confirmed == true) {
      await ref.read(vocabLibraryProvider.notifier).deleteSet(set.id);
    }
  }
}
