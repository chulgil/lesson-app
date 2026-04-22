// Reusable widgets for extended profile screen.
//
// Contains cards, buttons, and helper widgets.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/profile/domain/entities/teacher_profile.dart';
import '../../../../features/profile/presentation/providers/teacher_extended_profile_provider.dart';
import 'extended_profile_dialogs.dart';

/// Profile completion card with gradient background.
class ProfileCompletionCard extends StatelessWidget {
  final TeacherProfile profile;

  const ProfileCompletionCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final percentage = profile.completionPercentage;
    final level = profile.completionLevel;
    final levelColor = getCompletionLevelColor(level);
    final levelLabel = getCompletionLevelLabel(level);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, levelColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '프로필 완성도',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space1,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                ),
                child: Text(
                  levelLabel,
                  style: AppTypography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Text(
                '$percentage%',
                style: AppTypography.headingLarge.copyWith(
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusSmall,
                      ),
                    ),
                    if (profile.nextSteps.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        '다음 단계: ${profile.nextSteps.join(", ")}',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Generic info card with icon, title, value, and tap action.
class ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isEmpty;
  final VoidCallback onTap;

  const ProfileInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color:
                isEmpty
                    ? AppColors.paperAccent.withValues(alpha: 0.3)
                    : AppColors.inkQuaternary,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paperAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Icon(icon, color: AppColors.paperAccent, size: 24),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.bodyLarge.copyWith(
                      color:
                          isEmpty
                              ? AppColors.inkTertiary
                              : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.inkTertiary),
          ],
        ),
      ),
    );
  }
}

/// Education card with edit/delete actions.
class EducationCard extends ConsumerWidget {
  final Education education;
  final int index;

  const EducationCard({
    super.key,
    required this.education,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paperOk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(Icons.school, color: AppColors.paperOk, size: 24),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  education.school,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${education.major} · ${education.degree}${education.graduationYear != null ? ' · ${education.graduationYear}년 졸업' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.inkTertiary),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${AppRoutes.educationEdit}?index=$index');
              } else if (value == 'delete') {
                showDeleteConfirmDialog(
                  context,
                  '학력',
                  () => ref
                      .read(teacherExtendedProfileProvider.notifier)
                      .removeEducation(index),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(AppStrings.modify),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
                ],
          ),
        ],
      ),
    );
  }
}

/// Career card with edit/delete actions.
class CareerCard extends ConsumerWidget {
  final Career career;
  final int index;

  const CareerCard({super.key, required this.career, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.paperAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(Icons.work, color: AppColors.paperAccent, size: 24),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        career.organization,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (career.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paperOk.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSmall,
                          ),
                        ),
                        child: Text(
                          '재직중',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.paperOk,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${career.position} · ${career.period}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                if (career.description != null &&
                    career.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    career.description!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.inkSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.inkTertiary),
            onSelected: (value) {
              if (value == 'edit') {
                context.push('${AppRoutes.careerEdit}?index=$index');
              } else if (value == 'delete') {
                showDeleteConfirmDialog(
                  context,
                  '경력',
                  () => ref
                      .read(teacherExtendedProfileProvider.notifier)
                      .removeCareer(index),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(AppStrings.modify),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
                ],
          ),
        ],
      ),
    );
  }
}

/// Certificate card with status indicator and edit/delete actions.
class CertificateCard extends ConsumerWidget {
  final Certificate certificate;

  const CertificateCard({super.key, required this.certificate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = getCertificateStatusColor(certificate.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              getCertificateStatusIcon(certificate.status),
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        certificate.name,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSmall,
                        ),
                      ),
                      child: Text(
                        getCertificateStatusLabel(certificate.status),
                        style: AppTypography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${getCertificateTypeLabel(certificate.type)} · ${certificate.issuingBody}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${certificate.issueDate.year}년 ${certificate.issueDate.month}월 발급',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.inkTertiary,
                  ),
                ),
                if (certificate.isRejected &&
                    certificate.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    '반려 사유: ${certificate.rejectionReason}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.paperAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.inkTertiary),
            onSelected: (value) {
              if (value == 'edit') {
                context.push(
                  '${AppRoutes.certificateEdit}?id=${certificate.id}',
                );
              } else if (value == 'delete') {
                showDeleteConfirmDialog(
                  context,
                  '자격증',
                  () => ref
                      .read(teacherExtendedProfileProvider.notifier)
                      .removeCertificate(certificate.id),
                );
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text(AppStrings.modify),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text(AppStrings.delete)),
                ],
          ),
        ],
      ),
    );
  }
}

/// Empty state card with icon, message, and action button.
class ProfileEmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonText;
  final VoidCallback onTap;

  const ProfileEmptyCard({
    super.key,
    required this.icon,
    required this.message,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.paperDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.inkQuaternary,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.inkTertiary),
          const SizedBox(height: AppSpacing.space3),
          Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.paperAccent,
              side: BorderSide(color: AppColors.paperAccent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width add button with icon.
class ProfileAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ProfileAddButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.paperAccent,
          side: BorderSide(color: AppColors.paperAccent),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        ),
      ),
    );
  }
}

// Helper functions for profile completion

/// Returns color for completion level.
Color getCompletionLevelColor(ProfileCompletionLevel level) {
  switch (level) {
    case ProfileCompletionLevel.minimum:
      return AppColors.paperAccent;
    case ProfileCompletionLevel.basic:
      return AppColors.ink;
    case ProfileCompletionLevel.standard:
      return AppColors.paperOk;
    case ProfileCompletionLevel.complete:
      return AppColors.paperAccent;
  }
}

/// Returns label for completion level.
String getCompletionLevelLabel(ProfileCompletionLevel level) {
  switch (level) {
    case ProfileCompletionLevel.minimum:
      return '최소';
    case ProfileCompletionLevel.basic:
      return '기본';
    case ProfileCompletionLevel.standard:
      return '표준';
    case ProfileCompletionLevel.complete:
      return '완료';
  }
}

// Helper functions for certificates

/// Returns color for certificate status.
Color getCertificateStatusColor(CertificateStatus status) {
  switch (status) {
    case CertificateStatus.pending:
      return AppColors.paperAccent;
    case CertificateStatus.approved:
      return AppColors.paperOk;
    case CertificateStatus.rejected:
      return AppColors.paperAccent;
  }
}

/// Returns icon for certificate status.
IconData getCertificateStatusIcon(CertificateStatus status) {
  switch (status) {
    case CertificateStatus.pending:
      return Icons.hourglass_empty;
    case CertificateStatus.approved:
      return Icons.verified;
    case CertificateStatus.rejected:
      return Icons.cancel_outlined;
  }
}

/// Returns label for certificate status.
String getCertificateStatusLabel(CertificateStatus status) {
  switch (status) {
    case CertificateStatus.pending:
      return '심사중';
    case CertificateStatus.approved:
      return '승인됨';
    case CertificateStatus.rejected:
      return '반려됨';
  }
}

/// Returns label for certificate type.
String getCertificateTypeLabel(CertificateType type) {
  switch (type) {
    case CertificateType.musicTeacher:
      return '음악 교원';
    case CertificateType.cultureArtsEducator:
      return '문화예술교육사';
    case CertificateType.schoolTeacher:
      return '학교 교원';
    case CertificateType.conservatory:
      return '음악원 수료';
    case CertificateType.degree:
      return '음악 학위';
    case CertificateType.performance:
      return '연주 자격';
    case CertificateType.other:
      return '기타';
  }
}
