import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import 'lesson_student_info.dart';

/// Student picker bottom sheet
void showLessonStudentPicker({
  required BuildContext context,
  required List<LessonStudentInfo> students,
  required LessonStudentInfo? selectedStudent,
  required ValueChanged<LessonStudentInfo> onStudentSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXLarge),
      ),
    ),
    builder:
        (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder:
              (context, scrollController) => Column(
                children: [
                  const SizedBox(height: AppSpacing.space2),
                  const BottomSheetHandle(margin: EdgeInsets.zero),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    // Notebook × Score §7.27: 바텀시트 제목 Playfair.
                    child: Text(
                      '학생 선택',
                      style: NotebookTypography.sectionTitle,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = selectedStudent?.id == student.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: student.color.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              student.name[0],
                              style: AppTypography.bodyLarge.copyWith(
                                color: student.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(student.name),
                          subtitle: Text(
                            '${student.instrument} · ${student.currentPiece}',
                          ),
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: AppColors.paperAccent,
                                  )
                                  : null,
                          onTap: () {
                            onStudentSelected(student);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
  );
}
