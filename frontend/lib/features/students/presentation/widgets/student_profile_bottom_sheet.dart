import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/notebook_typography.dart';
import '../../../../core/widgets/bottom_sheet_handle.dart';
import '../../../../core/widgets/notebook/notebook_surfaces.dart';
import '../../domain/entities/student.dart';
import '../extensions/student_domain_visuals.dart';

/// Show a unified student profile bottom sheet.
///
/// Used from request_detail_screen (lesson request chat) and
/// subscription_detail_screen (schedule change chat).
/// Always shows "학생 상세 보기" button for teacher navigation.
void showStudentProfileBottomSheet({
  required BuildContext context,
  required String studentId,
  required String studentName,
  required String instrument,
  Student? student,
  String? subscriptionSummary,
  String? message,
  bool isTrialRequest = false,
}) {
  showNotebookBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    padding: EdgeInsets.zero,
    showHandle: false,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(color: AppColors.paper),
        padding: EdgeInsets.fromLTRB(
          0,
          AppSpacing.space3,
          0,
          MediaQuery.of(ctx).padding.bottom + AppSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(
              child: BottomSheetHandle(width: 36, margin: EdgeInsets.zero),
            ),
            const SizedBox(height: AppSpacing.space4),

            // Profile avatar
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  student?.profileColor ?? AppColors.scheduleMutedBackground,
              child: Text(
                studentName.isNotEmpty ? studentName[0] : '?',
                style: AppTypography.headingLarge.copyWith(
                  color: AppColors.paper,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),

            // Student name
            Text(studentName, style: NotebookTypography.pieceTitle),
            const SizedBox(height: AppSpacing.space1),

            // Instrument
            Text(
              instrument,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),

            // Subscription summary (if provided)
            if (subscriptionSummary != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: const BoxDecoration(color: AppColors.paperDark),
                  child: Text(
                    subscriptionSummary,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // Student message (quote block for trial)
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space3),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color:
                        isTrialRequest
                            ? AppColors.paperAccentSoft
                            : AppColors.paperDark,
                    border:
                        isTrialRequest
                            ? const Border(
                              left: BorderSide(
                                color: AppColors.paperAccent,
                                width: 3,
                              ),
                            )
                            : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTrialRequest)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.space1,
                          ),
                          child: Text(
                            AppStrings.studentMessage,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.paperAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        message,
                        style:
                            isTrialRequest
                                ? AppTypography.bodyMedium.copyWith(
                                  color: AppColors.ink,
                                )
                                : AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Student detail info
            if (student != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  children: [
                    if (student.phone != null && student.phone!.isNotEmpty)
                      _profileInfoRow(AppStrings.phoneLabel, student.phone!),
                    if (student.parentPhone != null &&
                        student.parentPhone!.isNotEmpty)
                      _profileInfoRow(
                        AppStrings.parentPhoneLabel,
                        student.parentPhone!,
                      ),
                    _profileInfoRow(AppStrings.levelLabel, student.level.label),
                  ],
                ),
              ),
            ],

            // Navigate to student detail
            const SizedBox(height: AppSpacing.space3),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push(
                      AppRoutes.studentDetail.replaceFirst(':id', studentId),
                    );
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text(AppStrings.viewStudentDetail),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.space4),
          ],
        ),
      );
    },
  );
}

Widget _profileInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.space2),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
        ),
        Expanded(child: Text(value, style: AppTypography.bodySmall)),
      ],
    ),
  );
}
