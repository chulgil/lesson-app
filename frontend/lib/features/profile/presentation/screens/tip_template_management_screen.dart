import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/lessons/domain/entities/tip_template.dart';
import '../../../lessons/presentation/providers/tip_template_providers.dart';

/// Screen for managing tip templates
class TipTemplateManagementScreen extends ConsumerStatefulWidget {
  const TipTemplateManagementScreen({super.key});

  @override
  ConsumerState<TipTemplateManagementScreen> createState() =>
      _TipTemplateManagementScreenState();
}

class _TipTemplateManagementScreenState
    extends ConsumerState<TipTemplateManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TipCategory.values.length + 1,
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('템플릿 관리'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: '전체'),
            ...TipCategory.values.map((cat) => Tab(text: cat.label)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTemplateList(null),
          ...TipCategory.values.map((cat) => _buildTemplateList(cat)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTemplateDialog,
        icon: const Icon(Icons.add),
        label: const Text('템플릿 추가'),
      ),
    );
  }

  Widget _buildTemplateList(TipCategory? category) {
    final AsyncValue<List<TipTemplate>> templatesAsync;

    if (category != null) {
      templatesAsync = ref.watch(tipTemplatesByCategoryProvider(category));
    } else {
      templatesAsync = ref.watch(tipTemplatesProvider);
    }

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books_outlined,
                  size: 64,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '등록된 템플릿이 없습니다',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '자주 사용하는 팁을 템플릿으로 저장하세요',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: templates.length,
          separatorBuilder:
              (_, __) => const SizedBox(height: AppSpacing.space3),
          itemBuilder: (context, index) {
            final template = templates[index];
            return _buildTemplateCard(template);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.paperAccent),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  '템플릿을 불러오는데 실패했습니다',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                OutlinedButton.icon(
                  onPressed: () {
                    if (category != null) {
                      ref.invalidate(tipTemplatesByCategoryProvider(category));
                    } else {
                      ref.invalidate(tipTemplatesProvider);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTemplateCard(TipTemplate template) {
    return Dismissible(
      key: Key(template.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paperAccent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(template);
      },
      onDismissed: (direction) {
        ref
            .read(tipTemplatesNotifierProvider.notifier)
            .deleteTemplate(template.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('템플릿이 삭제되었습니다'),
            action: SnackBarAction(
              label: '실행취소',
              onPressed: () {
                ref
                    .read(tipTemplatesNotifierProvider.notifier)
                    .addTemplate(
                      content: template.content,
                      category: template.category,
                      instrument: template.instrument,
                    );
              },
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () => _showEditTemplateDialog(template),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with category and usage count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: Text(
                        template.category.label,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (template.instrument != null) ...[
                      const SizedBox(width: AppSpacing.space2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
                        ),
                        child: Text(
                          template.instrument!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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

                // Content
                Text(template.content, style: AppTypography.bodyMedium),

                const SizedBox(height: AppSpacing.space2),

                // Last used info
                if (template.lastUsedAt != null)
                  Text(
                    '마지막 사용: ${_formatDate(template.lastUsedAt!)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else if (diff.inDays < 30) {
      return '${diff.inDays ~/ 7}주 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  Future<bool?> _showDeleteConfirmation(TipTemplate template) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('템플릿 삭제'),
            content: const Text('이 템플릿을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(AppStrings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.paperAccent),
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );
  }

  void _showAddTemplateDialog() {
    final contentController = TextEditingController();
    final instrumentController = TextEditingController();
    TipCategory selectedCategory = TipCategory.general;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('새 템플릿 추가'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '템플릿 내용을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '카테고리',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space2,
                        children:
                            TipCategory.values.map((cat) {
                              final isSelected = selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat.label),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(
                                      () => selectedCategory = cat,
                                    );
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      TextField(
                        controller: instrumentController,
                        decoration: const InputDecoration(
                          labelText: '악기 (선택)',
                          hintText: '예: 바이올린, 피아노',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('내용을 입력해주세요')),
                        );
                        return;
                      }

                      await ref
                          .read(tipTemplatesNotifierProvider.notifier)
                          .addTemplate(
                            content: contentController.text.trim(),
                            category: selectedCategory,
                            instrument:
                                instrumentController.text.trim().isEmpty
                                    ? null
                                    : instrumentController.text.trim(),
                          );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('템플릿이 추가되었습니다')),
                        );
                      }
                    },
                    child: const Text('추가'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showEditTemplateDialog(TipTemplate template) {
    final contentController = TextEditingController(text: template.content);
    final instrumentController = TextEditingController(
      text: template.instrument ?? '',
    );
    TipCategory selectedCategory = template.category;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('템플릿 수정'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '템플릿 내용을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      Text(
                        '카테고리',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space2,
                        children:
                            TipCategory.values.map((cat) {
                              final isSelected = selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat.label),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(
                                      () => selectedCategory = cat,
                                    );
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      TextField(
                        controller: instrumentController,
                        decoration: const InputDecoration(
                          labelText: '악기 (선택)',
                          hintText: '예: 바이올린, 피아노',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(AppStrings.cancel),
                  ),
                  FilledButton(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('내용을 입력해주세요')),
                        );
                        return;
                      }

                      final updatedTemplate = template.copyWith(
                        content: contentController.text.trim(),
                        category: selectedCategory,
                        instrument:
                            instrumentController.text.trim().isEmpty
                                ? null
                                : instrumentController.text.trim(),
                      );

                      await ref
                          .read(tipTemplatesNotifierProvider.notifier)
                          .updateTemplate(updatedTemplate);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('템플릿이 수정되었습니다')),
                        );
                      }
                    },
                    child: const Text(AppStrings.save),
                  ),
                ],
              );
            },
          ),
    );
  }
}
