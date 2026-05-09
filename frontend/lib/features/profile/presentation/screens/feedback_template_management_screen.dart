import 'package:flutter/material.dart';
import 'package:lessonaza/core/widgets/notebook/notebook_surfaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/notebook/notebook_detail_app_bar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../lessons/lessons_facade.dart';
import '../../../lessons/domain/entities/feedback_template.dart';
import '../../../lessons/presentation/extensions/template_category_visuals.dart';
import '../widgets/feedback_template_form_sheet.dart';

/// Screen for managing teacher's feedback templates.
class FeedbackTemplateManagementScreen extends ConsumerStatefulWidget {
  const FeedbackTemplateManagementScreen({super.key});

  @override
  ConsumerState<FeedbackTemplateManagementScreen> createState() =>
      _FeedbackTemplateManagementScreenState();
}

class _FeedbackTemplateManagementScreenState
    extends ConsumerState<FeedbackTemplateManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: FeedbackCategory.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotebookScreenScaffold(
      appBar: NotebookDetailAppBar(
        title: AppStrings.feedbackTemplateScreenTitle,
        actions: [DetailAppBarAction.add],
        onAction: (action) {
          if (action == DetailAppBarAction.add) {
            FeedbackTemplateFormSheet.show(context);
          }
        },
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: '전체'),
            ...FeedbackCategory.values.map((cat) => Tab(text: cat.label)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(null),
          ...FeedbackCategory.values.map((cat) => _buildList(cat)),
        ],
      ),
    );
  }

  Widget _buildList(FeedbackCategory? category) {
    final AsyncValue<List<FeedbackTemplate>> templatesAsync;
    if (category != null) {
      templatesAsync = ref.watch(feedbackTemplatesByCategoryProvider(category));
    } else {
      templatesAsync = ref.watch(feedbackTemplatesProvider);
    }

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) return _buildEmpty();
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: templates.length,
          separatorBuilder:
              (_, __) => const SizedBox(height: AppSpacing.space3),
          itemBuilder: (_, i) => _buildCard(templates[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (_, __) => Center(
            child: OutlinedButton.icon(
              onPressed: () {
                if (category != null) {
                  ref.invalidate(feedbackTemplatesByCategoryProvider(category));
                } else {
                  ref.invalidate(feedbackTemplatesProvider);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              AppStrings.feedbackTemplateEmptyTitle,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              AppStrings.feedbackTemplateEmptyBody,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(FeedbackTemplate template) {
    return Dismissible(
      key: Key(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space4),
        decoration: BoxDecoration(color: AppColors.paperAccent),
        child: const Icon(Icons.delete, color: AppColors.paper),
      ),
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) {
        ref
            .read(feedbackTemplatesNotifierProvider.notifier)
            .deleteTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.feedbackTemplateDeletedSnack),
          ),
        );
      },
      child: NotebookCard(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap:
              () => FeedbackTemplateFormSheet.show(context, existing: template),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _categoryChip(template.category),
                    const Spacer(),
                    if (template.usageCount > 0) ...[
                      Icon(
                        Icons.repeat,
                        size: 14,
                        color: AppColors.inkTertiary,
                      ),
                      const SizedBox(width: AppSpacing.space1),
                      Text(
                        '${template.usageCount}회',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  template.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  template.body,
                  style: NotebookTypography.hand,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (template.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  Wrap(
                    spacing: AppSpacing.space2,
                    runSpacing: AppSpacing.space1,
                    children:
                        template.tags
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.paperAccentSoft,
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Text(
                                  '#$t',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.paperAccent,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(FeedbackCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.paperAccentSoft),
      child: Text(
        cat.label,
        style: AppTypography.caption.copyWith(
          color: AppColors.paperAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete() {
    return showNotebookDialog<bool>(
      context: context,
      title: AppStrings.profileFeedbackTemplateDeleteTitle,
      content: const Text(AppStrings.profileFeedbackTemplateDeleteConfirm),
      confirmLabel: AppStrings.delete,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
  }
}
