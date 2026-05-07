import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../extensions/unified_lesson_request_visuals.dart';

/// Profile card for lesson request detail — branches by viewer role and type.
///
/// Extracted from request_detail_screen.dart to reduce file size.
class RequestProfileCard extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String viewerRole;
  final String studentName;
  final String? academyName;
  final Student? student;

  const RequestProfileCard({
    super.key,
    required this.request,
    required this.viewerRole,
    required this.studentName,
    this.academyName,
    this.student,
  });

  @override
  Widget build(BuildContext context) {
    if (viewerRole == 'student') {
      return _buildStudentViewCard();
    }
    return request.type == LessonRequestType.trial
        ? _buildTrialCard()
        : _buildRegularCard();
  }

  Widget _buildTrialCard() {
    final urgent = isRequestUrgent(request.createdAt);

    return _buildCardContainer(
      children: [
        _buildTopInfoRow(urgent),
        const SizedBox(height: AppSpacing.space3),
        _buildStudentInfoRow(studentName, AppColors.paperAccent),
      ],
    );
  }

  Widget _buildRegularCard() {
    final urgent = isRequestUrgent(request.createdAt);

    return _buildCardContainer(
      children: [
        _buildTopInfoRow(urgent),
        const SizedBox(height: AppSpacing.space3),
        _buildStudentInfoRow(studentName, AppColors.paperAccent),
        if (student != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: AppSpacing.iconSM,
                color: AppColors.inkTertiary,
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${AppStrings.lessonCount(student!.totalLessons)} · ${AppStrings.practiceRate(student!.practiceRate)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStudentViewCard() {
    final urgent = isRequestUrgent(request.createdAt);

    return _buildCardContainer(
      children: [
        _buildTopInfoRow(urgent),
        const SizedBox(height: AppSpacing.space3),
        _buildStudentInfoRow(AppStrings.teacher, AppColors.ink),
      ],
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.space4),
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStudentInfoRow(String name, Color avatarColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: AppSpacing.avatarMedium / 2,
          backgroundColor: avatarColor.withValues(alpha: 0.08),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: AppTypography.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: avatarColor,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${request.instrument} · ${request.experience.label} · ${request.goal.label}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildTopInfoRow(bool urgent) {
    return Row(
      children: [
        if (request.isAcademy && academyName != null) ...[
          Text('🏫', style: AppTypography.bodySmall),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              academyName!,
              style: AppTypography.caption.copyWith(
                color: AppColors.inkSecondary,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
        ] else ...[
          Text(
            AppStrings.individualLesson,
            style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          ),
          const SizedBox(width: AppSpacing.space2),
        ],
        _buildTypeBadge(),
        if (request.isReturningStudent) ...[
          const SizedBox(width: AppSpacing.space1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space1 + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.paperOk.withValues(alpha: 0.12),
            ),
            child: Text(
              AppStrings.returning,
              style: AppTypography.captionSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.paperOk,
              ),
            ),
          ),
        ],
        const Spacer(),
        Text(
          formatRelativeTime(request.createdAt),
          style: AppTypography.caption.copyWith(
            color: urgent ? AppColors.paperAccent : AppColors.inkTertiary,
            fontWeight: urgent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    final typeColor =
        request.type == LessonRequestType.trial
            ? AppColors.ink
            : AppColors.paperAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12)),
      child: Text(
        request.typeDisplayLabel,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: typeColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final color = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12)),
      child: Text(
        request.statusChipLabel,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(UnifiedRequestStatus status) {
    return switch (status) {
      UnifiedRequestStatus.completed => AppColors.paperOk,
      UnifiedRequestStatus.paymentNotified => AppColors.paperAccent,
      UnifiedRequestStatus.cancelled => AppColors.paperAccent,
      UnifiedRequestStatus.expired => AppColors.paperAccent,
      UnifiedRequestStatus.rejected => AppColors.paperAccent,
      _ => AppColors.ink,
    };
  }
}
