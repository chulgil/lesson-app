import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/tip_template.dart';
import '../providers/tip_template_providers.dart';

/// Bottom sheet for selecting tip templates
class TipTemplateBottomSheet extends ConsumerStatefulWidget {
  final String? instrument;
  final TipCategory? initialCategory;
  final Function(String content) onSelect;

  const TipTemplateBottomSheet({
    super.key,
    this.instrument,
    this.initialCategory,
    required this.onSelect,
  });

  @override
  ConsumerState<TipTemplateBottomSheet> createState() =>
      _TipTemplateBottomSheetState();
}

class _TipTemplateBottomSheetState
    extends ConsumerState<TipTemplateBottomSheet> {
  TipCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXLarge),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              const Center(child: BottomSheetHandle()),

              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Row(
                  children: [
                    Text('템플릿 선택', style: AppTypography.headingMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAddTemplateDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('새 템플릿'),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '템플릿 검색...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusMedium,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Category filters
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  children: [
                    _buildCategoryChip(null, '전체'),
                    ...TipCategory.values.map(
                      (cat) => _buildCategoryChip(cat, cat.label),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.space3),

              // Frequently used section
              if (_searchQuery.isEmpty && _selectedCategory == null)
                _buildFrequentSection(),

              // Template list
              Expanded(child: _buildTemplateList(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(TipCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.space2),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedCategory = selected ? category : null);
        },
        backgroundColor: AppColors.paperDark,
        selectedColor: AppColors.paperAccentSoft,
        checkmarkColor: AppColors.paperAccent,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: isSelected ? AppColors.paperAccent : AppColors.inkSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.paperAccent : AppColors.inkQuaternary,
        ),
      ),
    );
  }

  Widget _buildFrequentSection() {
    final frequentAsync = ref.watch(frequentTipTemplatesProvider);

    return frequentAsync.when(
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18, color: AppColors.paperAccent),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    '자주 사용',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppSpacing.space3),
                    child: _buildQuickTemplateCard(template),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            const Divider(height: 1),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickTemplateCard(TipTemplate template) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTemplate(template),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      template.category.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${template.usageCount}회',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Expanded(
                child: Text(
                  template.content,
                  style: AppTypography.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateList(ScrollController scrollController) {
    // Use search or category filter
    final AsyncValue<List<TipTemplate>> templatesAsync;

    if (_searchQuery.isNotEmpty) {
      templatesAsync = ref.watch(tipTemplateSearchProvider(_searchQuery));
    } else if (_selectedCategory != null) {
      templatesAsync = ref.watch(
        tipTemplatesByCategoryProvider(_selectedCategory!),
      );
    } else if (widget.instrument != null) {
      templatesAsync = ref.watch(
        tipTemplatesByInstrumentProvider(widget.instrument),
      );
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
                  Icons.search_off,
                  size: 48,
                  color: AppColors.inkTertiary,
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '검색 결과가 없습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: scrollController,
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
                Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  '템플릿을 불러오는데 실패했습니다',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTemplateCard(TipTemplate template) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectTemplate(template),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space4),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(color: AppColors.inkQuaternary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    child: Text(
                      template.category.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.paperAccent,
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
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.inkTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(template.content, style: AppTypography.bodyMedium),
              if (template.usageCount > 0) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(
                  '${template.usageCount}회 사용됨',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectTemplate(TipTemplate template) async {
    try {
      // Increment usage count
      await ref
          .read(tipTemplatesNotifierProvider.notifier)
          .useTemplate(template.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('템플릿 사용 기록에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.paperAccent,
          ),
        );
      }
    }

    widget.onSelect(template.content);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showAddTemplateDialog(BuildContext context) {
    final contentController = TextEditingController();
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
                        maxLines: 3,
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
                      if (contentController.text.trim().isEmpty) return;

                      await ref
                          .read(tipTemplatesNotifierProvider.notifier)
                          .addTemplate(
                            content: contentController.text.trim(),
                            category: selectedCategory,
                            instrument: widget.instrument,
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
}

/// Show tip template bottom sheet
Future<void> showTipTemplateBottomSheet({
  required BuildContext context,
  String? instrument,
  TipCategory? initialCategory,
  required Function(String content) onSelect,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => TipTemplateBottomSheet(
          instrument: instrument,
          initialCategory: initialCategory,
          onSelect: onSelect,
        ),
  );
}
