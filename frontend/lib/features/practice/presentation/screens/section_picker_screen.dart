// Reusable screen for picking a section from all available sections.
//
// Used for:
// - Connecting orphan recordings to sections
// - Importing external audio files to sections
// - Any other section selection needs

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/practice_repertoire.dart';
import '../../../settings/presentation/providers/orphan_recording_provider.dart';

/// Result returned when a section is selected.
class SectionPickerResult {
  final PracticeRepertoire repertoire;
  final PracticeSection section;

  SectionPickerResult({
    required this.repertoire,
    required this.section,
  });
}

/// Reusable screen for selecting a section.
///
/// Returns [SectionPickerResult] when a section is selected, or null if cancelled.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<SectionPickerResult>(
///   context,
///   MaterialPageRoute(builder: (context) => const SectionPickerScreen()),
/// );
/// if (result != null) {
///   // Use result.section.id
/// }
/// ```
class SectionPickerScreen extends ConsumerStatefulWidget {
  /// Optional title override
  final String? title;

  /// Optional recording to show info about (for orphan recording flow)
  final PracticeRecording? recording;

  const SectionPickerScreen({
    super.key,
    this.title,
    this.recording,
  });

  @override
  ConsumerState<SectionPickerScreen> createState() => _SectionPickerScreenState();
}

class _SectionPickerScreenState extends ConsumerState<SectionPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(allSectionsForAssignmentProvider);

    return Scaffold(
      backgroundColor: AppColors.paperDark,
      appBar: AppBar(
        title: Text(widget.title ?? '섹션 선택'),
        backgroundColor: AppColors.paperDark,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '레퍼토리 또는 섹션 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: const BorderSide(color: AppColors.inkQuaternary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: const BorderSide(color: AppColors.inkQuaternary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Section list
          Expanded(
            child: sectionsAsync.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter by search query
                final filtered = _searchQuery.isEmpty
                    ? sections
                    : sections.where((item) {
                        final repertoireName = item.repertoire.name.toLowerCase();
                        final sectionName = item.section.pieceName.toLowerCase();
                        final rangeText = item.section.rangeText.toLowerCase();
                        return repertoireName.contains(_searchQuery) ||
                            sectionName.contains(_searchQuery) ||
                            rangeText.contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return _buildNoResultsState();
                }

                // Group by repertoire
                final grouped = <String, List<({PracticeRepertoire repertoire, PracticeSection section})>>{};
                for (final item in filtered) {
                  grouped.putIfAbsent(item.repertoire.id, () => []).add(item);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space4),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final repertoireId = grouped.keys.elementAt(index);
                    final items = grouped[repertoireId]!;
                    final repertoire = items.first.repertoire;

                    return _RepertoireGroup(
                      repertoire: repertoire,
                      sections: items,
                      onSectionTap: (section) => _selectSection(repertoire, section),
                      searchQuery: _searchQuery,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.paperAccent),
                    const SizedBox(height: AppSpacing.space4),
                    const Text('오류가 발생했습니다.', style: TextStyle(color: AppColors.paperAccent)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '섹션이 없습니다',
              style: AppTypography.headingSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              '먼저 레퍼토리와 섹션을 만들어주세요.',
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

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.inkTertiary,
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              '"$_searchQuery" 검색 결과 없음',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSection(PracticeRepertoire repertoire, PracticeSection section) {
    Navigator.pop(
      context,
      SectionPickerResult(repertoire: repertoire, section: section),
    );
  }
}

class _RepertoireGroup extends StatelessWidget {
  final PracticeRepertoire repertoire;
  final List<({PracticeRepertoire repertoire, PracticeSection section})> sections;
  final void Function(PracticeSection) onSectionTap;
  final String searchQuery;

  const _RepertoireGroup({
    required this.repertoire,
    required this.sections,
    required this.onSectionTap,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Repertoire header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space2),
          color: AppColors.paperDark,
          child: Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: _buildHighlightedText(
                  repertoire.name,
                  searchQuery,
                  AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '${sections.length}개 섹션',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        // Sections
        ...sections.map((item) => _SectionTile(
              section: item.section,
              onTap: () => onSectionTap(item.section),
              searchQuery: searchQuery,
            )),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              color: AppColors.primary,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final PracticeSection section;
  final VoidCallback onTap;
  final String searchQuery;

  const _SectionTile({
    required this.section,
    required this.onTap,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: const Icon(
          Icons.music_note,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: _buildHighlightedText(
        section.pieceName,
        searchQuery,
        AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: _buildHighlightedText(
        section.rangeText,
        searchQuery,
        AppTypography.bodySmall.copyWith(
          color: AppColors.inkSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.inkTertiary),
      onTap: onTap,
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(text, style: style);
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: style.copyWith(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              color: AppColors.primary,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
