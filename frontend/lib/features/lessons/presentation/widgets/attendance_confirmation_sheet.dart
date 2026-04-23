import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../domain/entities/lesson.dart';
import 'lesson_confirmation_dialog.dart';

/// BottomSheet for quick attendance confirmation after a lesson.
///
/// Shows lesson info + two options:
/// - Lesson completed (deducts subscription)
/// - Not completed (select reason with deduction info)
class AttendanceConfirmationSheet extends StatefulWidget {
  final Lesson lesson;

  const AttendanceConfirmationSheet({super.key, required this.lesson});

  /// Show as a modal bottom sheet and return the result.
  static Future<LessonConfirmationResult?> show(
    BuildContext context, {
    required Lesson lesson,
  }) {
    return showModalBottomSheet<LessonConfirmationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttendanceConfirmationSheet(lesson: lesson),
    );
  }

  @override
  State<AttendanceConfirmationSheet> createState() =>
      _AttendanceConfirmationSheetState();
}

class _AttendanceConfirmationSheetState
    extends State<AttendanceConfirmationSheet> {
  bool _showReasonSelection = false;
  LessonNonCompletionReason? _selectedReason;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: _showReasonSelection ? 0.75 : 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLarge),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.space3,
                AppSpacing.screenPadding,
                MediaQuery.of(context).padding.bottom + AppSpacing.space4,
              ),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child:
                    _showReasonSelection
                        ? _buildReasonSelection()
                        : _buildInitialConfirmation(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialConfirmation() {
    final lesson = widget.lesson;
    final weekdays = [
      '',
      AppStrings.mon,
      AppStrings.tue,
      AppStrings.wed,
      AppStrings.thu,
      AppStrings.fri,
      AppStrings.sat,
      AppStrings.sun,
    ];
    final weekday = weekdays[lesson.date.weekday];
    final dateStr =
        '${lesson.date.month}/${lesson.date.day}($weekday) ${lesson.startTime}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        const Center(
          child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Header
        Row(
          children: [
            const Icon(Icons.fact_check, color: AppColors.paperAccent),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score §7.27: 바텀시트 제목 Playfair.
            Text(
              AppStrings.lessonConfirmation,
              style: NotebookTypography.sectionTitle,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Lesson info card
        Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.paperDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Column(
            children: [
              Text(
                dateStr,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                '${lesson.studentName} ${lesson.instrument}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Action buttons row
        Row(
          children: [
            // Completed
            Expanded(
              child: _buildActionCard(
                icon: Icons.check_circle,
                label: AppStrings.lessonCompleted,
                sublabel: AppStrings.deductOne,
                color: AppColors.paperOk,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pop(const LessonConfirmationResult(completed: true));
                },
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            // Not completed
            Expanded(
              child: _buildActionCard(
                icon: Icons.cancel,
                label: AppStrings.lessonNotCompleted,
                sublabel: AppStrings.selectReason,
                color: AppColors.paperAccent,
                onTap: () => setState(() => _showReasonSelection = true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReasonSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        const Center(
          child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Header with back
        Row(
          children: [
            IconButton(
              onPressed:
                  () => setState(() {
                    _showReasonSelection = false;
                    _selectedReason = null;
                  }),
              icon: const Icon(Icons.arrow_back),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: AppSpacing.space2),
            // Notebook × Score §7.27: 바텀시트 서브 헤더 Playfair.
            Text(
              AppStrings.nonCompletionReason,
              style: NotebookTypography.sectionTitle,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Reason options
        ...LessonNonCompletionReason.values.map((reason) {
          final isSelected = _selectedReason == reason;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: _buildReasonOption(
              reason: reason,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedReason = reason),
            ),
          );
        }),

        const SizedBox(height: AppSpacing.space3),

        // Note field
        TextField(
          controller: _noteController,
          maxLines: 2,
          style: AppTypography.bodySmall,
          decoration: InputDecoration(
            hintText: AppStrings.optionalNote,
            hintStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.inkTertiary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.space3),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Confirm button
        SizedBox(
          height: AppSpacing.buttonHeight,
          child: ElevatedButton(
            onPressed:
                _selectedReason == null
                    ? null
                    : () {
                      Navigator.of(context).pop(
                        LessonConfirmationResult(
                          completed: false,
                          nonCompletionReason: _selectedReason,
                          note:
                              _noteController.text.isEmpty
                                  ? null
                                  : _noteController.text,
                        ),
                      );
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.paperAccent,
              disabledBackgroundColor: AppColors.scheduleMutedAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: Text(
              AppStrings.confirm,
              // Notebook × Score §7.50: Vermillion CTA foreground = paper.
              style: AppTypography.buttonSmall.copyWith(color: AppColors.paper),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.space2),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(sublabel, style: AppTypography.caption.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonOption({
    required LessonNonCompletionReason reason,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? reason.color : AppColors.inkQuaternary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          color: isSelected ? reason.color.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? reason.color : AppColors.inkTertiary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason.label,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    reason.description,
                    style: AppTypography.caption.copyWith(
                      color:
                          reason.isDeducted
                              ? AppColors.paperAccent
                              : AppColors.inkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
