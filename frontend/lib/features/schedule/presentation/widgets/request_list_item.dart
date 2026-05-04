import 'package:flutter/material.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_format_utils.dart';
import '../../domain/entities/unified_lesson_request.dart';

/// List item for lesson requests — triage card layout.
///
/// Supports both teacher and student perspectives via [viewerRole].
/// Teacher view: shows student name, avatar, teacher action label.
/// Student view: shows teacher name, avatar, student action label.
class RequestListItem extends StatelessWidget {
  final UnifiedLessonRequest request;
  final String studentName;
  final String? teacherName;
  final String? academyName;
  final String viewerRole;
  final VoidCallback? onTap;

  const RequestListItem({
    super.key,
    required this.request,
    required this.studentName,
    this.teacherName,
    this.academyName,
    this.viewerRole = 'teacher',
    this.onTap,
  });

  bool get _isStudentView => viewerRole == 'student';

  /// Display name: teacher view shows student, student view shows teacher.
  String get _displayName =>
      _isStudentView
          ? AppStrings.teacherDisplayName(teacherName ?? AppStrings.teacher)
          : studentName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space3,
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: AppSpacing.space3),
            Expanded(child: _buildInfo()),
            const SizedBox(width: AppSpacing.space3),
            _buildRightColumn(),
          ],
        ),
      ),
    );
  }

  /// Avatar with urgency dot overlay.
  Widget _buildAvatar() {
    final urgent = isRequestUrgent(request.createdAt);
    final initial = _displayName.isNotEmpty ? _displayName[0] : '?';
    final avatar = CircleAvatar(
      radius: AppSpacing.avatarSmall / 2,
      backgroundColor: AppColors.paperAccentSoft,
      child: Text(
        initial,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.paperAccent,
        ),
      ),
    );

    if (!urgent) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.paperAccent,
              border: Border.all(color: AppColors.paper, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    final source =
        request.isAcademy
            ? (academyName ?? AppStrings.academy)
            : AppStrings.individualLesson;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: name · instrument · level
        Text(
          '$_displayName · ${request.instrument} · ${request.experience.label}',
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.space1),

        // Line 2: source · type
        Text(
          '$source · ${request.typeDisplayLabel}',
          style: AppTypography.caption.copyWith(color: AppColors.inkTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Right column: status chip + elapsed time — matches schedule change request list style.
  Widget _buildRightColumn() {
    final label =
        _isStudentView
            ? request.studentActionLabel
            : request.teacherActionLabel;
    final color = _actionColor;
    final urgent = isRequestUrgent(request.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2,
            vertical: AppSpacing.space1,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
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

  Color get _actionColor {
    final colorKey =
        _isStudentView
            ? request.studentActionColorKey
            : request.teacherActionColorKey;
    return switch (colorKey) {
      'action' => AppColors.paperAccent,
      _ => AppColors.inkTertiary,
    };
  }
}
