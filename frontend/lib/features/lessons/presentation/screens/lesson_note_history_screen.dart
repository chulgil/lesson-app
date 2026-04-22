import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../features/lessons/domain/entities/lesson.dart';
import '../providers/lesson_note_providers.dart';

/// Full lesson note history screen with search and period filter.
class LessonNoteHistoryScreen extends ConsumerStatefulWidget {
  final String studentId;

  const LessonNoteHistoryScreen({super.key, required this.studentId});

  @override
  ConsumerState<LessonNoteHistoryScreen> createState() =>
      _LessonNoteHistoryScreenState();
}

class _LessonNoteHistoryScreenState
    extends ConsumerState<LessonNoteHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  NoteFilterPeriod _period = NoteFilterPeriod.threeMonths;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(studentLessonNotesProvider(widget.studentId));

    return Scaffold(
      appBar: AppBar(
        title: Text('레슨 노트'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '노트 검색...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkTertiary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.inkTertiary,
                ),
                suffixIcon:
                    _query.isNotEmpty
                        ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear, size: 20),
                        )
                        : null,
                filled: true,
                fillColor: AppColors.paperDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
              ),
            ),
          ),

          // Period filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Row(
              children:
                  NoteFilterPeriod.values.map((period) {
                    final isSelected = _period == period;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.space2),
                      child: FilterChip(
                        label: Text(period.label),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _period = period),
                        backgroundColor: AppColors.paper,
                        selectedColor: AppColors.paperAccent.withValues(
                          alpha: 0.15,
                        ),
                        checkmarkColor: AppColors.paperAccent,
                        side: BorderSide(
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkQuaternary,
                        ),
                        labelStyle: AppTypography.bodySmall.copyWith(
                          color:
                              isSelected
                                  ? AppColors.paperAccent
                                  : AppColors.inkSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.space3),

          // Notes list
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filtered = _filterNotes(notes);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildNotesList(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('오류가 발생했습니다.')),
            ),
          ),
        ],
      ),
    );
  }

  List<Lesson> _filterNotes(List<Lesson> notes) {
    return notes.where((lesson) {
      // Period filter
      final cutoff = _period.cutoffDate;
      if (cutoff != null && lesson.date.isBefore(cutoff)) return false;
      // Search query filter
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return (lesson.feedback?.toLowerCase().contains(q) ?? false) ||
          (lesson.keyPoints?.any((kp) => kp.toLowerCase().contains(q)) ??
              false) ||
          (lesson.practiceTips?.toLowerCase().contains(q) ?? false) ||
          (lesson.studentNote?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.notes,
      title: _query.isNotEmpty ? '검색 결과가 없습니다' : '레슨 노트가 없습니다',
    );
  }

  Widget _buildNotesList(List<Lesson> notes) {
    // Group by month
    final grouped = <String, List<Lesson>>{};
    for (final note in notes) {
      final key = '${note.date.year}년 ${note.date.month}월';
      grouped.putIfAbsent(key, () => []).add(note);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped.entries.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.space4,
                bottom: AppSpacing.space2,
              ),
              child: Text(
                entry.key,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            // Note cards
            ...entry.value.map(
              (lesson) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: _NoteCard(lesson: lesson),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Lesson lesson;

  const _NoteCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final dateStr = formatDateYMDWithDay(lesson.date);

    return InkWell(
      onTap:
          () => context.push(
            AppRoutes.lessonDetail.replaceFirst(':id', lesson.id),
          ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(color: AppColors.inkQuaternary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + instrument
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$dateStr  ${lesson.instrument}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.inkTertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),

            // Feedback — Notebook × Score: 선생님 손글씨 주석으로 Gaegu 렌더.
            if (lesson.feedback != null)
              Text(
                lesson.feedback!,
                style: NotebookTypography.hand.copyWith(
                  color: AppColors.paperPencil,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            // Key points
            if (lesson.keyPoints?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.space2),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    lesson.keyPoints!
                        .map(
                          (kp) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paperAccent.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusLarge,
                              ),
                            ),
                            child: Text(
                              kp,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.paperAccent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],

            // Practice tips (collapsed)
            if (lesson.practiceTips != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Expanded(
                    // Notebook × Score: 연습 팁도 손글씨 메모로 렌더.
                    child: Text(
                      lesson.practiceTips!,
                      style: NotebookTypography.hand.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.paperPencil,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Student memo (collapsed)
            if (lesson.studentNote != null &&
                lesson.studentNote!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: AppColors.paperAccent,
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Expanded(
                    // Notebook × Score: 학생 메모도 여백에 끼적인 손글씨 느낌으로.
                    child: Text(
                      lesson.studentNote!,
                      style: NotebookTypography.hand.copyWith(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.paperPencil,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
