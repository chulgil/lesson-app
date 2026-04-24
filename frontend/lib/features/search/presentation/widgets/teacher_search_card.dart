import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/domain/entities/teacher_search.dart';

/// Card widget displaying a teacher's profile in search results
class TeacherSearchCard extends StatelessWidget {
  const TeacherSearchCard({
    super.key,
    required this.teacher,
    this.isPreviousTeacher = false,
  });

  final TeacherProfile teacher;
  final bool isPreviousTeacher;

  @override
  Widget build(BuildContext context) {
    final publicProfile = TeacherPublicProfile.fromProfile(teacher);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      shape: RoundedRectangleBorder(
        // Highlight previous teacher with a subtle border
        side:
            isPreviousTeacher
                ? BorderSide(
                  color: AppColors.ink.withValues(alpha: 0.5),
                  width: 1.5,
                )
                : BorderSide.none,
      ),
      child: InkWell(
        onTap:
            () => context.push(
              AppRoutes.teacherDetail.replaceFirst(':id', teacher.id),
            ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile image
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.paperDark,
                backgroundImage:
                    publicProfile.profileImage != null
                        ? NetworkImage(publicProfile.profileImage!)
                        : null,
                child:
                    publicProfile.profileImage == null
                        ? Icon(
                          Icons.person,
                          size: 35,
                          color: AppColors.inkSecondary,
                        )
                        : null,
              ),
              const SizedBox(width: AppSpacing.space3),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Previous teacher badge
                    if (isPreviousTeacher) ...[
                      _buildPreviousTeacherBadge(),
                      const SizedBox(height: AppSpacing.space1),
                    ],

                    // Academy badge (if applicable)
                    if (publicProfile.isAcademy &&
                        publicProfile.organizationName != null) ...[
                      _buildAcademyBadge(publicProfile.organizationName!),
                      const SizedBox(height: AppSpacing.space1),
                    ],

                    // Name and badges
                    _buildNameRow(publicProfile),

                    const SizedBox(height: AppSpacing.space1),

                    // Instruments
                    Text(
                      publicProfile.instruments.join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.paperAccent,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.space1),

                    // Experience and fee
                    _buildExperienceAndFee(publicProfile),

                    const SizedBox(height: AppSpacing.space2),

                    // Introduction
                    Text(
                      publicProfile.introduction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),

                    const SizedBox(height: AppSpacing.space2),

                    // Lesson areas
                    if (publicProfile.lessonAreas != null &&
                        publicProfile.lessonAreas!.isNotEmpty)
                      _buildLessonAreas(publicProfile.lessonAreas!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviousTeacherBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: 0.1)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 12, color: AppColors.ink),
          const SizedBox(width: AppSpacing.space1),
          Text(
            '이전에 레슨했어요',
            style: AppTypography.caption.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademyBadge(String organizationName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paperAccent.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school, size: 12, color: AppColors.paperAccent),
          const SizedBox(width: AppSpacing.space1),
          Text(
            organizationName,
            style: AppTypography.caption.copyWith(
              color: AppColors.paperAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow(TeacherPublicProfile publicProfile) {
    return Row(
      children: [
        Expanded(
          child: Text(
            publicProfile.name ?? '선생님',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...publicProfile.badges.take(2).map((badge) {
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.space1),
            child: Icon(
              _getBadgeIcon(badge),
              size: 18,
              color: AppColors.paperAccent,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExperienceAndFee(TeacherPublicProfile publicProfile) {
    return Row(
      children: [
        if (publicProfile.experienceYears != null) ...[
          Icon(Icons.work_outline, size: 14, color: AppColors.inkSecondary),
          const SizedBox(width: AppSpacing.space1),
          Text(
            '${publicProfile.experienceYears}년',
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
        ],
        if (publicProfile.feeRange != null) ...[
          Icon(
            Icons.payments_outlined,
            size: 14,
            color: AppColors.inkSecondary,
          ),
          const SizedBox(width: AppSpacing.space1),
          Text(
            publicProfile.feeRange!.formatted,
            style: AppTypography.caption.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLessonAreas(List<String> lessonAreas) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          lessonAreas.take(3).map((area) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(color: AppColors.paperDark),
              child: Text(
                area,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            );
          }).toList(),
    );
  }

  IconData _getBadgeIcon(VerificationBadge badge) {
    switch (badge) {
      case VerificationBadge.phoneVerified:
        return Icons.phone_android;
      case VerificationBadge.certified:
        return Icons.verified;
      case VerificationBadge.premium:
        return Icons.star;
    }
  }
}
