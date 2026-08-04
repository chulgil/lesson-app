import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/l10n/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/notebook_typography.dart';
import '../../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../../../../core/widgets/notebook/thin_rule.dart';
import 'lesson_student_info.dart';

/// Student picker bottom sheet
void showLessonStudentPicker({
  required BuildContext context,
  required List<LessonStudentInfo> students,
  required LessonStudentInfo? selectedStudent,
  required ValueChanged<LessonStudentInfo> onStudentSelected,
  // 경로 4 (quick_add_lesson) — 신규 학생 인라인 등록. 제공 시 목록 최상단
  // [새 학생 등록] 항목 + 빈 상태 액션이 이 콜백으로 위임된다 (시트는 닫힘).
  VoidCallback? onAddStudentRequested,
}) {
  showNotebookModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
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
                      AppStrings.lessonStudentPickerTitle,
                      style: NotebookTypography.sectionTitle,
                    ),
                  ),
                  Expanded(
                    child:
                        students.isEmpty
                            ? EmptyStateWidget(
                              icon: Icons.person_add_alt_1,
                              title: AppStrings.studentPickerEmptyTitle,
                              actionLabel: AppStrings.studentRegisterAction,
                              actionIcon: Icons.add,
                              onAction: () {
                                Navigator.pop(context);
                                if (onAddStudentRequested != null) {
                                  onAddStudentRequested();
                                } else {
                                  context.push(AppRoutes.addStudent);
                                }
                              },
                            )
                            : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.screenPadding,
                              ),
                              itemCount:
                                  students.length +
                                  (onAddStudentRequested != null ? 1 : 0),
                              separatorBuilder: (_, __) => const ThinRule(),
                              itemBuilder: (context, index) {
                                // 최상단 [새 학생 등록] (경로 4)
                                if (onAddStudentRequested != null &&
                                    index == 0) {
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: AppColors.paperDark,
                                      child: Icon(
                                        Icons.person_add_alt_1,
                                        color: AppColors.paperAccent,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      AppStrings.lessonPickerAddStudentAction,
                                      style: AppTypography.bodyLarge.copyWith(
                                        color: AppColors.paperAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      onAddStudentRequested();
                                    },
                                  );
                                }
                                final student =
                                    students[onAddStudentRequested != null
                                        ? index - 1
                                        : index];
                                final isSelected =
                                    selectedStudent?.id == student.id;

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
