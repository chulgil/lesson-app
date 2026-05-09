import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../core/widgets/notebook/thin_rule.dart';
import '../../domain/entities/feedback_template.dart';
import '../extensions/template_category_visuals.dart';
import '../providers/feedback_template_providers.dart';

/// Bottom sheet for picking a [FeedbackTemplate] to apply to lesson feedback.
///
/// Returns the selected template via [Navigator.pop] (callers consume in
/// `pop` future). Includes search, category filter, and "frequent" section.
class FeedbackTemplatePickerSheet extends ConsumerStatefulWidget {
  const FeedbackTemplatePickerSheet({super.key});

  static Future<FeedbackTemplate?> show(BuildContext context) {
    return showNotebookModalBottomSheet<FeedbackTemplate>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FeedbackTemplatePickerSheet(),
    );
  }

  @override
  ConsumerState<FeedbackTemplatePickerSheet> createState() =>
      _FeedbackTemplatePickerSheetState();
}

class _FeedbackTemplatePickerSheetState
    extends ConsumerState<FeedbackTemplatePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  FeedbackCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: BottomSheetHandle()),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.space2,
                  AppSpacing.screenPadding,
                  AppSpacing.space2,
                ),
                child: Text(
                  AppStrings.feedbackTemplatePickerTitle,
                  style: NotebookTypography.sectionTitle,
                ),
              ),
              _buildSearchBar(),
              const SizedBox(height: AppSpacing.space2),
              _buildCategoryChips(),
              const ThinRule(),
              Expanded(child: _buildBody(scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _query = v.trim()),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: AppStrings.feedbackTemplatePickerSearchHint,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon:
              _query.isEmpty
                  ? null
                  : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        children: [
          _categoryChip(null, AppStrings.all),
          ...FeedbackCategory.values.map((c) => _categoryChip(c, c.label)),
        ],
      ),
    );
  }

  Widget _categoryChip(FeedbackCategory? cat, String label) {
    final selected = _category == cat;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.space2),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _category = cat),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_query.isNotEmpty) {
      return _buildSearchResults(scrollController);
    }
    return _buildBrowseList(scrollController);
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    final asyncResults = ref.watch(feedbackTemplateSearchProvider(_query));
    return asyncResults.when(
      data: (list) {
        final filtered =
            _category == null
                ? list
                : list.where((t) => t.category == _category).toList();
        if (filtered.isEmpty) return _buildEmpty();
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: filtered.length,
          separatorBuilder:
              (_, __) => const SizedBox(height: AppSpacing.space2),
          itemBuilder: (_, i) => _buildTemplateTile(filtered[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBrowseList(ScrollController scrollController) {
    final allAsync =
        _category == null
            ? ref.watch(feedbackTemplatesProvider)
            : ref.watch(feedbackTemplatesByCategoryProvider(_category!));
    final frequentAsync = ref.watch(frequentFeedbackTemplatesProvider);

    return allAsync.when(
      data: (all) {
        if (all.isEmpty) return _buildEmpty();
        final frequent = frequentAsync.value ?? const <FeedbackTemplate>[];
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            if (_category == null && frequent.isNotEmpty) ...[
              _sectionHeader(AppStrings.feedbackTemplatePickerFrequentSection),
              const SizedBox(height: AppSpacing.space2),
              ...frequent.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                  child: _buildTemplateTile(t),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
            _sectionHeader(AppStrings.feedbackTemplatePickerAllSection),
            const SizedBox(height: AppSpacing.space2),
            ...all.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                child: _buildTemplateTile(t),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.inkSecondary,
        fontWeight: FontWeight.w600,
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
              size: 48,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space3),
            Text(
              _query.isNotEmpty
                  ? AppStrings.feedbackTemplatePickerEmptyResult
                  : AppStrings.feedbackTemplateEmptyTitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateTile(FeedbackTemplate template) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(template),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkQuaternary),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paperAccentSoft,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    template.category.label,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.paperAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              template.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
